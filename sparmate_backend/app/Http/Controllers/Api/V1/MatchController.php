<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\SparringMatch;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class MatchController extends Controller
{
    /**
     * List the authenticated user's match history.
     */
    public function index(Request $request): JsonResponse
    {
        $matches = $request->user()
            ->matches()
            ->with('grandmaster:id,name,full_name,style,color_hex,icon,elo_rating')
            ->orderByDesc('played_at')
            ->paginate(20);

        return response()->json($matches);
    }

    /**
     * Start a new sparring match (create an in-progress record).
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'grandmaster_id' => 'required|exists:grandmasters,id',
        ]);

        $match = SparringMatch::create([
            'user_id'        => $request->user()->id,
            'grandmaster_id' => $validated['grandmaster_id'],
            'result'         => 'in_progress',
            'played_at'      => now(),
        ]);

        $match->load('grandmaster');

        return response()->json([
            'message' => 'Match started.',
            'match'   => $match,
        ], 201);
    }

    /**
     * Update a match with the final game data (PGN, result, analysis).
     * Called when the Flutter app finishes a sparring session.
     */
    public function update(Request $request, SparringMatch $match): JsonResponse
    {
        // Ensure the user owns this match
        if ($match->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $validated = $request->validate([
            'pgn'              => 'nullable|string',
            'fen_final'        => 'nullable|string',
            'result'           => 'required|in:win,loss,draw',
            'move_count'       => 'required|integer|min:0',
            'duration_seconds' => 'required|integer|min:0',
            'pressure_avg'     => 'nullable|numeric|min:0|max:100',
            'analysis'         => 'nullable|array',
        ]);

        $match->update($validated);
        $match->load('grandmaster');

        return response()->json([
            'message' => 'Match updated.',
            'match'   => $match,
        ]);
    }

    /**
     * Trigger post-match BKT analysis via the FastAPI microservice.
     *
     * Flow: Laravel → FastAPI (calculate BKT) → Laravel (save updated matrix).
     * This implements the pipeline described in Milestone 2, Section 4.5.
     */
    public function analyze(Request $request, SparringMatch $match): JsonResponse
    {
        if ($match->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $user = $request->user();
        $bktMatrix = $user->bktMatrix;

        if (! $bktMatrix) {
            $bktMatrix = $user->bktMatrix()->create([
                'matrix' => \App\Models\UserBktMatrix::defaultMatrix(),
            ]);
        }

        // Forward to FastAPI BKT microservice
        $fastApiUrl = config('services.fastapi.url', 'http://127.0.0.1:8000');

        try {
            $response = Http::timeout(10)->post("{$fastApiUrl}/api/v1/update-mastery", [
                'user_id'            => $user->id,
                'current_matrix'     => $bktMatrix->matrix,
                'classified_blunders' => $match->analysis ?? [],
            ]);

            if ($response->successful()) {
                $newMatrix = $response->json('new_matrix', $bktMatrix->matrix);
                $bktMatrix->update(['matrix' => $newMatrix]);

                return response()->json([
                    'message'    => 'BKT analysis complete.',
                    'new_matrix' => $newMatrix,
                ]);
            }

            return response()->json([
                'message'    => 'BKT analysis completed with fallback.',
                'new_matrix' => $bktMatrix->matrix,
            ]);

        } catch (\Exception $e) {
            // Gracefully degrade if FastAPI is unavailable
            return response()->json([
                'message'    => 'BKT microservice unavailable. Matrix unchanged.',
                'new_matrix' => $bktMatrix->matrix,
            ], 503);
        }
    }
}
