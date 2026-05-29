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
     * Return the user's current training plan (Coaching Engine screen).
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

        return response()->json([
            'bkt_matrix' => [
                'skills' => $bktMatrix->matrix,
                'updated_at' => $bktMatrix->updated_at?->toISOString(),
            ],
            'training_plan' => $trainingPlan ? [
                'primary_directive' => $trainingPlan->primary_directive,
                'weekly_focus'      => $trainingPlan->weekly_focus,
                'plan_items'        => $trainingPlan->plan_items,
                'generated_at'      => $trainingPlan->generated_at?->toISOString(),
            ] : null,
            'weakest_skills' => $this->getWeakestSkills($bktMatrix->matrix),
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
                'elo_rating' => $user->elo_rating,
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

                return response()->json([
                    'message'       => 'Training plan refreshed.',
                    'training_plan' => $plan,
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
            'message'       => 'Training plan generated locally (FastAPI unavailable).',
            'training_plan' => $plan,
        ]);
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
