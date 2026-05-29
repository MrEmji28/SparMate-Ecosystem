<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\Puzzle;
use App\Models\SparringMatch;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Aggregate data for the Home Screen.
     *
     * Returns: active lesson, recent match, daily puzzle count,
     * coaching summary, and user stats.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        // Active lesson (most recent in-progress lesson)
        $activeLesson = $user->lessonProgress()
            ->with('lesson')
            ->whereNull('completed_at')
            ->where('progress', '>', 0)
            ->orderByDesc('updated_at')
            ->first();

        // Recent match result
        $recentMatch = $user->matches()
            ->with('grandmaster')
            ->orderByDesc('played_at')
            ->first();

        // Daily puzzle stats (today)
        $todayPuzzles = $user->puzzleAttempts()
            ->whereDate('attempted_at', today())
            ->count();

        $todaySolved = $user->puzzleAttempts()
            ->whereDate('attempted_at', today())
            ->where('solved', true)
            ->count();

        // Coaching summary
        $trainingPlan = $user->trainingPlan;
        $bktMatrix    = $user->bktMatrix;

        // Overall stats
        $totalMatches = $user->matches()->count();
        $wins   = $user->matches()->where('result', 'win')->count();
        $losses = $user->matches()->where('result', 'loss')->count();
        $draws  = $user->matches()->where('result', 'draw')->count();

        return response()->json([
            'user' => [
                'name'        => $user->name,
                'elo_rating'  => $user->elo_rating,
                'streak_days' => $user->streak_days,
                'avatar_url'  => $user->avatar_url,
            ],
            'active_lesson' => $activeLesson ? [
                'lesson_id'   => $activeLesson->lesson->id,
                'title'       => $activeLesson->lesson->title,
                'category'    => $activeLesson->lesson->category,
                'chapter'     => $activeLesson->currentChapter?->title ?? 'Chapter 1',
                'progress'    => $activeLesson->progress,
                'color_hex'   => $activeLesson->lesson->color_hex,
                'icon'        => $activeLesson->lesson->icon,
            ] : null,
            'recent_match' => $recentMatch ? [
                'grandmaster' => $recentMatch->grandmaster->name,
                'result'      => $recentMatch->result,
                'move_count'  => $recentMatch->move_count,
                'played_at'   => $recentMatch->played_at?->toISOString(),
            ] : null,
            'daily_puzzles' => [
                'attempted' => $todayPuzzles,
                'solved'    => $todaySolved,
                'goal'      => 5, // Default daily goal
            ],
            'coaching' => $trainingPlan ? [
                'primary_directive' => $trainingPlan->primary_directive,
                'weekly_focus'      => $trainingPlan->weekly_focus,
            ] : null,
            'stats' => [
                'total_matches' => $totalMatches,
                'wins'          => $wins,
                'losses'        => $losses,
                'draws'         => $draws,
            ],
        ]);
    }
}
