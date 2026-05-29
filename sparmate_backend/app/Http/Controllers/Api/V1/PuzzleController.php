<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Puzzle;
use App\Models\PuzzleAttempt;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PuzzleController extends Controller
{
    /**
     * Return a set of daily puzzles.
     *
     * Selects puzzles near the user's ELO rating that haven't been
     * solved today, falling back to random puzzles if needed.
     */
    public function daily(Request $request): JsonResponse
    {
        $user = $request->user();
        $dailyGoal = 5;

        // Get IDs of puzzles already attempted today
        $attemptedToday = $user->puzzleAttempts()
            ->whereDate('attempted_at', today())
            ->pluck('puzzle_id');

        // Select puzzles near the user's rating that haven't been attempted today
        $puzzles = Puzzle::whereNotIn('id', $attemptedToday)
            ->orderByRaw('ABS(rating - ?) ASC', [$user->elo_rating])
            ->limit($dailyGoal)
            ->get();

        // Today's stats
        $todayAttempts = $user->puzzleAttempts()
            ->whereDate('attempted_at', today())
            ->count();
        $todaySolved = $user->puzzleAttempts()
            ->whereDate('attempted_at', today())
            ->where('solved', true)
            ->count();

        return response()->json([
            'puzzles' => $puzzles,
            'stats' => [
                'attempted'  => $todayAttempts,
                'solved'     => $todaySolved,
                'daily_goal' => $dailyGoal,
                'progress'   => $dailyGoal > 0 ? min(1.0, $todaySolved / $dailyGoal) : 0,
            ],
        ]);
    }

    /**
     * Record a puzzle attempt.
     */
    public function attempt(Request $request, Puzzle $puzzle): JsonResponse
    {
        $validated = $request->validate([
            'solved'       => 'required|boolean',
            'time_seconds' => 'required|integer|min:0',
        ]);

        $attempt = PuzzleAttempt::create([
            'user_id'      => $request->user()->id,
            'puzzle_id'    => $puzzle->id,
            'solved'       => $validated['solved'],
            'time_seconds' => $validated['time_seconds'],
            'attempted_at' => now(),
        ]);

        // Update streak if this is the first solved puzzle today
        $user = $request->user();
        if ($validated['solved']) {
            $yesterdaySolved = $user->puzzleAttempts()
                ->whereDate('attempted_at', today()->subDay())
                ->where('solved', true)
                ->exists();

            $todayFirstSolve = $user->puzzleAttempts()
                ->whereDate('attempted_at', today())
                ->where('solved', true)
                ->count() === 1;

            if ($todayFirstSolve) {
                $user->increment('streak_days', $yesterdaySolved ? 1 : 0);
                if (! $yesterdaySolved) {
                    $user->update(['streak_days' => 1]);
                }
            }
        }

        return response()->json([
            'message' => $validated['solved'] ? 'Puzzle solved!' : 'Better luck next time.',
            'attempt' => $attempt,
        ]);
    }

    /**
     * Return the user's recent puzzle history.
     */
    public function recent(Request $request): JsonResponse
    {
        $attempts = $request->user()
            ->puzzleAttempts()
            ->with('puzzle:id,fen,category,difficulty,rating,theme')
            ->orderByDesc('attempted_at')
            ->limit(20)
            ->get()
            ->map(fn ($a) => [
                'id'           => $a->id,
                'puzzle'       => $a->puzzle,
                'solved'       => $a->solved,
                'time_seconds' => $a->time_seconds,
                'attempted_at' => $a->attempted_at?->toISOString(),
            ]);

        return response()->json([
            'recent_attempts' => $attempts,
        ]);
    }
}
