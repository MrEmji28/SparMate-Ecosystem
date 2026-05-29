<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\SparringMatch;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnalyticsController extends Controller
{
    /**
     * Return comprehensive analytics for the Analytics screen.
     *
     * Includes: rating overview, phase accuracy, match results,
     * insights, and top opponents.
     */
    public function overview(Request $request): JsonResponse
    {
        $user = $request->user();

        // ── Rating Overview ──────────────────────────────────────────
        $ratingHistory = $user->matches()
            ->where('result', '!=', 'in_progress')
            ->orderBy('played_at')
            ->limit(30)
            ->get(['id', 'played_at', 'result'])
            ->map(function ($match, $index) use ($user) {
                // Simulate a rating progression based on results
                $baseRating = $user->elo_rating - (30 - $index) * 5;
                $delta = match ($match->result) {
                    'win'  => rand(8, 15),
                    'loss' => rand(-15, -8),
                    'draw' => rand(-3, 3),
                    default => 0,
                };

                return [
                    'date'   => $match->played_at?->toDateString(),
                    'rating' => max(800, $baseRating + $delta),
                ];
            });

        // ── Match Results ────────────────────────────────────────────
        $totalMatches = $user->matches()->where('result', '!=', 'in_progress')->count();
        $wins   = $user->matches()->where('result', 'win')->count();
        $losses = $user->matches()->where('result', 'loss')->count();
        $draws  = $user->matches()->where('result', 'draw')->count();

        // ── Phase Accuracy ───────────────────────────────────────────
        // Derived from BKT matrix skills
        $bktMatrix = $user->bktMatrix;
        $matrix = $bktMatrix?->matrix ?? \App\Models\UserBktMatrix::defaultMatrix();

        $phaseAccuracy = [
            'opening'    => round(($matrix['opening_theory'] ?? 0.5) * 100),
            'middlegame' => round((($matrix['tactical_oversight'] ?? 0.5) + ($matrix['positional_error'] ?? 0.5)) / 2 * 100),
            'endgame'    => round(($matrix['endgame_fundamentals'] ?? 0.5) * 100),
        ];

        // ── Insights ─────────────────────────────────────────────────
        $insights = $this->generateInsights($matrix, $wins, $losses, $totalMatches);

        // ── Top Opponents ────────────────────────────────────────────
        $topOpponents = $user->matches()
            ->select('grandmaster_id', DB::raw('COUNT(*) as games_played'))
            ->selectRaw("SUM(CASE WHEN result = 'win' THEN 1 ELSE 0 END) as wins")
            ->selectRaw("SUM(CASE WHEN result = 'loss' THEN 1 ELSE 0 END) as losses")
            ->selectRaw("SUM(CASE WHEN result = 'draw' THEN 1 ELSE 0 END) as draws")
            ->where('result', '!=', 'in_progress')
            ->groupBy('grandmaster_id')
            ->with('grandmaster:id,name,full_name,style,color_hex,icon,elo_rating')
            ->orderByDesc('games_played')
            ->limit(5)
            ->get()
            ->map(fn ($row) => [
                'grandmaster'  => $row->grandmaster,
                'games_played' => $row->games_played,
                'wins'         => $row->wins,
                'losses'       => $row->losses,
                'draws'        => $row->draws,
                'win_rate'     => $row->games_played > 0
                    ? round($row->wins / $row->games_played * 100)
                    : 0,
            ]);

        return response()->json([
            'rating' => [
                'current'  => $user->elo_rating,
                'highest'  => $ratingHistory->max('rating') ?? $user->elo_rating,
                'history'  => $ratingHistory,
            ],
            'matches' => [
                'total'  => $totalMatches,
                'wins'   => $wins,
                'losses' => $losses,
                'draws'  => $draws,
                'win_rate' => $totalMatches > 0 ? round($wins / $totalMatches * 100) : 0,
            ],
            'phase_accuracy' => $phaseAccuracy,
            'insights'       => $insights,
            'top_opponents'  => $topOpponents,
        ]);
    }

    /**
     * Generate coaching insights based on the user's BKT matrix and match data.
     */
    private function generateInsights(array $matrix, int $wins, int $losses, int $total): array
    {
        $insights = [];

        // Find weakest and strongest skills
        $sorted = $matrix;
        asort($sorted);
        $weakest = array_key_first($sorted);
        arsort($sorted);
        $strongest = array_key_first($sorted);

        $insights[] = [
            'type'    => 'strength',
            'icon'    => 'trending_up',
            'title'   => 'Strongest Skill',
            'message' => 'Your ' . str_replace('_', ' ', $strongest) . ' is your best area at ' . round($matrix[$strongest] * 100) . '% mastery.',
        ];

        $insights[] = [
            'type'    => 'weakness',
            'icon'    => 'warning',
            'title'   => 'Area for Improvement',
            'message' => 'Your ' . str_replace('_', ' ', $weakest) . ' needs work at only ' . round($matrix[$weakest] * 100) . '% mastery.',
        ];

        if ($total >= 5) {
            $winRate = $total > 0 ? round($wins / $total * 100) : 0;
            $insights[] = [
                'type'    => 'stat',
                'icon'    => 'analytics',
                'title'   => 'Win Rate Trend',
                'message' => "You're winning {$winRate}% of your matches. " . ($winRate >= 50 ? 'Keep it up!' : 'Focus on your weaknesses to improve.'),
            ];
        }

        if ($losses > $wins && $total >= 3) {
            $insights[] = [
                'type'    => 'tip',
                'icon'    => 'lightbulb',
                'title'   => 'Coaching Tip',
                'message' => 'Consider lowering the difficulty and practicing against Petrosian to build solid positional habits.',
            ];
        }

        return $insights;
    }
}
