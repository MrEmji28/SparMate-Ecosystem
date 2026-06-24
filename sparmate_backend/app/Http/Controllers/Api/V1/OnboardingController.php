<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\TrainingPlan;
use App\Models\UserBktMatrix;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class OnboardingController extends Controller
{
    /**
     * Save onboarding survey answers, adjust BKT matrix + ELO rating
     * based on the user's self-reported skill level, and trigger the
     * ML microservice to generate an initial training plan.
     *
     * Expected payload:
     * {
     *   "answers": [
     *     {"question_id": 1, "answer": "intermediate"},
     *     {"question_id": 2, "answer": "yes"},
     *     ...
     *   ]
     * }
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'answers'              => 'required|array|min:5',
            'answers.*.question_id' => 'required|integer',
            'answers.*.answer'     => 'required|string',
        ]);

        $user    = $request->user();
        $answers = collect($validated['answers']);

        // ── Determine overall skill level from answers ──────────────

        $skillScore = 0;

        // Q1: Experience level (direct indicator)
        $q1 = $answers->firstWhere('question_id', 1);
        if ($q1) {
            $skillScore += match ($q1['answer']) {
                'beginner'     => 1,
                'intermediate' => 2,
                'advanced'     => 3,
                default        => 1,
            };
        }

        // Q2: Piece movement knowledge
        $q2 = $answers->firstWhere('question_id', 2);
        if ($q2) {
            $skillScore += match ($q2['answer']) {
                'learning'   => 1,
                'most'       => 2,
                'all'        => 3,
                default      => 1,
            };
        }

        // Q3: Games played frequency
        $q3 = $answers->firstWhere('question_id', 3);
        if ($q3) {
            $skillScore += match ($q3['answer']) {
                'never'      => 1,
                'few'        => 2,
                'regularly'  => 3,
                default      => 1,
            };
        }

        // Q4: Familiarity with tactics
        $q4 = $answers->firstWhere('question_id', 4);
        if ($q4) {
            $skillScore += match ($q4['answer']) {
                'none'       => 1,
                'some'       => 2,
                'confident'  => 3,
                default      => 1,
            };
        }

        // Q5: Tournament / competitive experience
        $q5 = $answers->firstWhere('question_id', 5);
        if ($q5) {
            $skillScore += match ($q5['answer']) {
                'never'      => 1,
                'casual'     => 2,
                'competitive' => 3,
                default       => 1,
            };
        }

        // Determine tier from aggregate score (5-15 range)
        $skillLevel = match (true) {
            $skillScore >= 12 => 'advanced',
            $skillScore >= 8  => 'intermediate',
            default           => 'beginner',
        };

        // ── Adjust ELO and BKT based on skill level ────────────────
        // ELO: Beginner=500, Intermediate=1200, Advanced=1500

        [$eloRating, $bktValues] = match ($skillLevel) {
            'advanced' => [
                1500,
                [
                    'tactical_oversight'   => 0.65,
                    'positional_error'     => 0.60,
                    'endgame_fundamentals' => 0.55,
                    'opening_theory'       => 0.60,
                    'king_safety'          => 0.55,
                    'pawn_structure'       => 0.50,
                    'piece_coordination'   => 0.55,
                    'time_management'      => 0.45,
                ],
            ],
            'intermediate' => [
                1200,
                [
                    'tactical_oversight'   => 0.45,
                    'positional_error'     => 0.40,
                    'endgame_fundamentals' => 0.35,
                    'opening_theory'       => 0.40,
                    'king_safety'          => 0.35,
                    'pawn_structure'       => 0.30,
                    'piece_coordination'   => 0.35,
                    'time_management'      => 0.30,
                ],
            ],
            default => [ // beginner
                500,
                [
                    'tactical_oversight'   => 0.20,
                    'positional_error'     => 0.15,
                    'endgame_fundamentals' => 0.10,
                    'opening_theory'       => 0.15,
                    'king_safety'          => 0.10,
                    'pawn_structure'       => 0.10,
                    'piece_coordination'   => 0.15,
                    'time_management'      => 0.10,
                ],
            ],
        };

        // Update user profile
        $user->update([
            'elo_rating'           => $eloRating,
            'skill_level'          => $skillLevel,
            'onboarding_completed' => true,
        ]);

        // Update BKT matrix
        $bktMatrix = $user->bktMatrix;
        if ($bktMatrix) {
            $bktMatrix->update(['matrix' => $bktValues]);
        } else {
            $bktMatrix = UserBktMatrix::create([
                'user_id' => $user->id,
                'matrix'  => $bktValues,
            ]);
        }

        // ── Trigger ML Microservice for initial training plan ───────

        $trainingPlan = $this->generateInitialPlan($user, $bktValues, $eloRating, $skillLevel);

        $user->refresh();

        return response()->json([
            'message'        => 'Onboarding completed successfully.',
            'skill_level'    => $skillLevel,
            'elo_rating'     => $eloRating,
            'training_plan'  => $trainingPlan,
            'user'           => $user->load('bktMatrix'),
        ]);
    }

    /**
     * Call the FastAPI microservice to generate an initial training plan
     * based on the onboarding results. Falls back to a local plan if
     * the microservice is unavailable.
     */
    private function generateInitialPlan($user, array $bktValues, int $eloRating, string $skillLevel): array
    {
        $fastApiUrl = config('services.fastapi.url', 'http://127.0.0.1:8000');

        try {
            $response = Http::timeout(10)->post("{$fastApiUrl}/api/v1/generate-plan", [
                'user_id'     => $user->id,
                'bkt_matrix'  => $bktValues,
                'elo_rating'  => $eloRating,
                'skill_level' => $skillLevel,
            ]);

            if ($response->successful()) {
                $planData = $response->json();

                $plan = TrainingPlan::create([
                    'user_id'           => $user->id,
                    'primary_directive' => $planData['primary_directive'] ?? $this->getDefaultDirective($skillLevel),
                    'weekly_focus'      => $planData['weekly_focus'] ?? [],
                    'plan_items'        => $planData['plan_items'] ?? [],
                    'generated_at'      => now(),
                ]);

                return $plan->toArray();
            }
        } catch (\Exception $e) {
            // Fallback to local plan generation
        }

        // ── Fallback: generate skill-appropriate plan locally ────────

        $plan = TrainingPlan::create([
            'user_id'           => $user->id,
            'primary_directive' => $this->getDefaultDirective($skillLevel),
            'weekly_focus'      => $this->getDefaultWeeklyFocus($skillLevel),
            'plan_items'        => $this->getDefaultPlanItems($skillLevel),
            'generated_at'      => now(),
        ]);

        return $plan->toArray();
    }

    /**
     * Get a skill-level-appropriate coaching directive.
     */
    private function getDefaultDirective(string $skillLevel): string
    {
        return match ($skillLevel) {
            'advanced' => 'Focus on refining your tactical precision and endgame technique. Work on reducing time pressure mistakes and deepening your opening preparation.',
            'intermediate' => 'Build strong fundamentals by working on pattern recognition, basic tactics (pins, forks, skewers), and understanding pawn structures. Consistent practice will level up your game.',
            default => 'Welcome to chess! Start by learning how each piece moves, basic checkmate patterns, and simple tactics. Take your time and enjoy the journey of learning.',
        };
    }

    /**
     * Get default weekly focus areas based on skill level.
     */
    private function getDefaultWeeklyFocus(string $skillLevel): array
    {
        return match ($skillLevel) {
            'advanced' => ['Tactical Oversight', 'Time Management', 'Endgame Fundamentals'],
            'intermediate' => ['Tactical Oversight', 'King Safety', 'Opening Theory'],
            default => ['Piece Movement', 'Basic Checkmates', 'Simple Tactics'],
        };
    }

    /**
     * Generate a default weekly training plan appropriate for the skill level.
     */
    private function getDefaultPlanItems(string $skillLevel): array
    {
        return match ($skillLevel) {
            'advanced' => [
                ['day' => 'Monday',    'activity' => 'Tactical Puzzles (Advanced)',     'duration_min' => 25, 'type' => 'puzzle'],
                ['day' => 'Tuesday',   'activity' => 'Opening Preparation',            'duration_min' => 30, 'type' => 'lesson'],
                ['day' => 'Wednesday', 'activity' => 'Spar vs Grandmaster',            'duration_min' => 30, 'type' => 'sparring'],
                ['day' => 'Thursday',  'activity' => 'Endgame Technique Drill',        'duration_min' => 25, 'type' => 'lesson'],
                ['day' => 'Friday',    'activity' => 'Timed Puzzle Rush',              'duration_min' => 20, 'type' => 'puzzle'],
                ['day' => 'Saturday',  'activity' => 'Spar vs Grandmaster (Analysis)', 'duration_min' => 35, 'type' => 'sparring'],
                ['day' => 'Sunday',    'activity' => 'Game Review & Weak Spots',       'duration_min' => 25, 'type' => 'lesson'],
            ],
            'intermediate' => [
                ['day' => 'Monday',    'activity' => 'Pin & Fork Puzzles',             'duration_min' => 20, 'type' => 'puzzle'],
                ['day' => 'Tuesday',   'activity' => 'King Safety Lesson',             'duration_min' => 20, 'type' => 'lesson'],
                ['day' => 'Wednesday', 'activity' => 'Spar vs AI Opponent',            'duration_min' => 25, 'type' => 'sparring'],
                ['day' => 'Thursday',  'activity' => 'Pawn Structure Basics',          'duration_min' => 20, 'type' => 'lesson'],
                ['day' => 'Friday',    'activity' => 'Tactical Pattern Recognition',   'duration_min' => 15, 'type' => 'puzzle'],
                ['day' => 'Saturday',  'activity' => 'Spar & Analyze Mistakes',        'duration_min' => 30, 'type' => 'sparring'],
                ['day' => 'Sunday',    'activity' => 'Opening Principles Review',      'duration_min' => 20, 'type' => 'lesson'],
            ],
            default => [ // beginner
                ['day' => 'Monday',    'activity' => 'Learn How Pieces Move',          'duration_min' => 15, 'type' => 'lesson'],
                ['day' => 'Tuesday',   'activity' => 'Basic Checkmate Patterns',       'duration_min' => 15, 'type' => 'lesson'],
                ['day' => 'Wednesday', 'activity' => 'Simple Capture Puzzles',         'duration_min' => 10, 'type' => 'puzzle'],
                ['day' => 'Thursday',  'activity' => 'Opening Principles (Control Center)', 'duration_min' => 15, 'type' => 'lesson'],
                ['day' => 'Friday',    'activity' => 'Practice Match vs Easy AI',      'duration_min' => 15, 'type' => 'sparring'],
                ['day' => 'Saturday',  'activity' => 'Tactics: Forks & Pins',          'duration_min' => 15, 'type' => 'puzzle'],
                ['day' => 'Sunday',    'activity' => 'Review & Play for Fun',          'duration_min' => 20, 'type' => 'sparring'],
            ],
        };
    }
}
