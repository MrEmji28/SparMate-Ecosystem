<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\TrainingPlan;
use App\Models\UserBktMatrix;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class CoachingController extends Controller
{
    /**
     * Return the user's current training plan + BKT matrix + recent indicators.
     *
     * This is the primary endpoint for the Coaching Engine screen.
     * It aggregates data from the database and optionally calls FastAPI
     * for coaching insights derived from recent match blunders.
     */
    public function plan(Request $request): JsonResponse
    {
        $user = $request->user();

        $bktMatrix    = $user->bktMatrix;
        $trainingPlan = $user->trainingPlan;

        // If no BKT matrix exists, create a default one
        if (! $bktMatrix) {
            $bktMatrix = UserBktMatrix::create([
                'user_id' => $user->id,
                'matrix'  => UserBktMatrix::defaultMatrix(),
            ]);
        }

        // ── Fetch recent match indicators ─────────────────────────────
        $recentIndicators = $this->getRecentIndicators($user, $bktMatrix);

        return response()->json([
            'bkt_matrix' => [
                'skills'     => $bktMatrix->matrix,
                'updated_at' => $bktMatrix->updated_at?->toISOString(),
            ],
            'training_plan' => $trainingPlan ? [
                'primary_directive' => $trainingPlan->primary_directive,
                'weekly_focus'      => $trainingPlan->weekly_focus,
                'plan_items'        => $trainingPlan->plan_items,
                'generated_at'      => $trainingPlan->generated_at?->toISOString(),
            ] : null,
            'weakest_skills'     => $this->getWeakestSkills($bktMatrix->matrix),
            'recent_indicators'  => $recentIndicators,
        ]);
    }

    /**
     * Trigger a coaching plan refresh via the FastAPI microservice.
     *
     * Sends the BKT matrix to FastAPI, which generates a new training plan.
     */
    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();
        $bktMatrix = $user->bktMatrix;

        if (! $bktMatrix) {
            $bktMatrix = UserBktMatrix::create([
                'user_id' => $user->id,
                'matrix'  => UserBktMatrix::defaultMatrix(),
            ]);
        }

        $fastApiUrl = config('services.fastapi.url', 'http://127.0.0.1:8000');

        try {
            $response = Http::timeout(10)->post("{$fastApiUrl}/api/v1/generate-plan", [
                'user_id'    => $user->id,
                'bkt_matrix' => $bktMatrix->matrix,
                'elo_rating' => $user->elo_rating ?? 1200,
            ]);

            if ($response->successful()) {
                $planData = $response->json();

                $plan = TrainingPlan::create([
                    'user_id'           => $user->id,
                    'primary_directive' => $planData['primary_directive'] ?? 'Focus on your weakest areas.',
                    'weekly_focus'      => $planData['weekly_focus'] ?? [],
                    'plan_items'        => $planData['plan_items'] ?? [],
                    'generated_at'      => now(),
                ]);

                // Also fetch fresh indicators
                $indicators = $this->getRecentIndicators($user, $bktMatrix);

                return response()->json([
                    'message'            => 'Training plan refreshed.',
                    'training_plan'      => $plan,
                    'recent_indicators'  => $indicators,
                ]);
            }
        } catch (\Exception $e) {
            // Fallback: generate a basic plan locally
        }

        // Fallback plan if FastAPI is unavailable
        $weakest = $this->getWeakestSkills($bktMatrix->matrix);

        $plan = TrainingPlan::create([
            'user_id'           => $user->id,
            'primary_directive' => 'Focus on improving your ' . ($weakest[0]['skill_label'] ?? 'weakest area') . '.',
            'weekly_focus'      => array_slice(array_column($weakest, 'skill_label'), 0, 3),
            'plan_items'        => $this->generateFallbackPlan($weakest),
            'generated_at'      => now(),
        ]);

        return response()->json([
            'message'            => 'Training plan generated locally (FastAPI unavailable).',
            'training_plan'      => $plan,
            'recent_indicators'  => [],
        ]);
    }

    /**
     * Get recent coaching indicators by analyzing the user's last matches.
     *
     * Calls the FastAPI /coaching-insights endpoint with recent match blunders.
     * Falls back to a local summary if FastAPI is unavailable.
     */
    private function getRecentIndicators($user, $bktMatrix): array
    {
        // Fetch last 5 matches with classified blunders and grandmaster info
        $recentMatches = $user->matches()
            ->with('grandmaster:id,name,full_name')
            ->whereNotNull('result')
            ->where('result', '!=', 'in_progress')
            ->orderByDesc('played_at')
            ->limit(5)
            ->get();

        if ($recentMatches->isEmpty()) {
            return [];
        }

        // Build match blunder summaries for FastAPI
        $matchSummaries = $recentMatches->map(function ($match) {
            $opponentName = $match->grandmaster?->full_name
                          ?? $match->grandmaster?->name
                          ?? 'Opponent';

            return [
                'match_id'      => $match->id,
                'opponent_name' => $opponentName,
                'result'        => $match->result,
                'blunders'      => $match->classified_blunders ?? [],
            ];
        })->toArray();

        // Try FastAPI coaching-insights endpoint
        $fastApiUrl = config('services.fastapi.url', 'http://127.0.0.1:8000');

        try {
            $response = Http::timeout(8)->post("{$fastApiUrl}/api/v1/coaching-insights", [
                'user_id'        => $user->id,
                'bkt_matrix'     => $bktMatrix->matrix,
                'recent_matches' => $matchSummaries,
            ]);

            if ($response->successful()) {
                return $response->json('recent_indicators', []);
            }
        } catch (\Exception $e) {
            // FastAPI unavailable — fall back to local summary
        }

        // ── Fallback: Generate basic indicators locally ───────────────
        return $this->generateLocalIndicators($matchSummaries);
    }

    /**
     * Generate basic coaching indicators locally when FastAPI is unavailable.
     */
    private function generateLocalIndicators(array $matchSummaries): array
    {
        $indicators = [];

        foreach ($matchSummaries as $match) {
            $blunders = $match['blunders'] ?? [];
            $opponent = $match['opponent_name'] ?? 'Opponent';

            if (empty($blunders)) {
                $indicators[] = [
                    'icon_type' => 'positive',
                    'opponent'  => $opponent,
                    'text'      => 'Clean game with no significant blunders. Well played!',
                    'category'  => '',
                    'match_id'  => $match['match_id'],
                ];
                continue;
            }

            // Count categories
            $categories = array_count_values(array_column($blunders, 'category'));
            arsort($categories);
            $topCategory = array_key_first($categories);
            $label = str_replace('_', ' ', ucwords($topCategory, '_'));

            $indicators[] = [
                'icon_type' => 'negative',
                'opponent'  => $opponent,
                'text'      => "{$label} was the primary weakness — {$categories[$topCategory]} mistake(s) in this area.",
                'category'  => $topCategory,
                'match_id'  => $match['match_id'],
            ];
        }

        return array_slice($indicators, 0, 6);
    }

    /**
     * Extract the weakest skills from the BKT matrix (lowest mastery probabilities).
     */
    private function getWeakestSkills(array $matrix): array
    {
        $skills = [];
        foreach ($matrix as $key => $value) {
            $skills[] = [
                'skill'       => $key,
                'skill_label' => str_replace('_', ' ', ucwords($key, '_')),
                'mastery'     => round($value, 3),
            ];
        }

        usort($skills, fn ($a, $b) => $a['mastery'] <=> $b['mastery']);

        return $skills;
    }

    /**
     * Generate a basic fallback training plan when FastAPI is unavailable.
     */
    private function generateFallbackPlan(array $weakestSkills): array
    {
        $days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
        $plan = [];

        foreach ($days as $i => $day) {
            $skill = $weakestSkills[$i % count($weakestSkills)] ?? $weakestSkills[0];
            $plan[] = [
                'day'          => $day,
                'activity'     => $skill['skill_label'] . ' Drill',
                'duration_min' => 20,
                'type'         => $i % 2 === 0 ? 'lesson' : 'puzzle',
            ];
        }

        return $plan;
    }
}
