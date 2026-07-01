<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\Puzzle;
use App\Models\UserBktMatrix;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * BKT-driven content recommendations.
 *
 * Reads the user's current mastery matrix and returns ranked lessons
 * and puzzles sorted by the skills they need most — weakest first.
 *
 * Skill → Content mapping:
 *   opening_theory       → Opening lessons / Tactics puzzles
 *   tactical_oversight   → Tactics lessons / Tactics puzzles
 *   endgame_fundamentals → Endgame lessons / Endgame puzzles
 *   king_safety          → Tactics lessons / Tactics puzzles
 *   pawn_structure       → Strategy lessons / Strategy puzzles
 *   positional_error     → Middlegame/Strategy lessons
 *   piece_coordination   → Middlegame/Strategy lessons
 *   time_management      → Tactics lessons (fast-solving drills)
 */
class RecommendationController extends Controller
{
    /**
     * Skill → lesson category mapping.
     * A skill can map to multiple lesson categories (ordered by priority).
     */
    private const SKILL_TO_LESSON_CATEGORY = [
        'opening_theory'       => ['Opening'],
        'tactical_oversight'   => ['Tactics'],
        'endgame_fundamentals' => ['Endgame'],
        'king_safety'          => ['Tactics', 'Strategy'],
        'pawn_structure'       => ['Strategy', 'Middlegame'],
        'positional_error'     => ['Strategy', 'Middlegame'],
        'piece_coordination'   => ['Middlegame', 'Strategy'],
        'time_management'      => ['Tactics'],
    ];

    /**
     * Skill → puzzle category/theme mapping.
     */
    private const SKILL_TO_PUZZLE_CATEGORY = [
        'opening_theory'       => 'Tactics',
        'tactical_oversight'   => 'Tactics',
        'endgame_fundamentals' => 'Endgame',
        'king_safety'          => 'Tactics',
        'pawn_structure'       => 'Strategy',
        'positional_error'     => 'Strategy',
        'piece_coordination'   => 'Strategy',
        'time_management'      => 'Tactics',
    ];

    /**
     * GET /api/v1/recommendations
     *
     * Returns:
     * - weak_skills:        top 3 skills the user needs to work on (with mastery %)
     * - recommended_lessons: up to 4 lessons ranked by relevance to weak skills
     * - recommended_puzzles: up to 4 puzzles ranked by relevance to weak skills
     * - focus_message:      a human-readable coaching nudge
     */
    public function index(Request $request): JsonResponse
    {
        $user   = $request->user();
        $bkt    = $user->bktMatrix;
        $matrix = $bkt?->matrix ?? UserBktMatrix::defaultMatrix();

        // ── 1. Rank skills worst→best ────────────────────────────────────
        asort($matrix);  // sort ascending (lowest mastery first)
        $weakSkills = array_slice($matrix, 0, 3, true);

        $weakSkillsPayload = array_map(fn ($skill, $score) => [
            'skill'       => $skill,
            'mastery_pct' => round($score * 100),
            'label'       => $this->skillLabel($skill),
            'icon'        => $this->skillIcon($skill),
        ], array_keys($weakSkills), array_values($weakSkills));

        // ── 2. Prioritised lesson categories (from weakest skill → strongest) ──
        $lessonCategories = [];
        foreach (array_keys($weakSkills) as $skill) {
            $cats = self::SKILL_TO_LESSON_CATEGORY[$skill] ?? [];
            foreach ($cats as $cat) {
                if (!in_array($cat, $lessonCategories)) {
                    $lessonCategories[] = $cat;
                }
            }
        }

        $recommendedLessons = Lesson::whereIn('category', $lessonCategories)
            ->limit(12)
            ->get()
            ->sortBy(fn ($l) => array_search($l->category, $lessonCategories))
            ->take(4)
            ->values();

        // ── 3. Prioritised puzzle categories ─────────────────────────────
        $puzzleCategories = [];
        foreach (array_keys($weakSkills) as $skill) {
            $cat = self::SKILL_TO_PUZZLE_CATEGORY[$skill] ?? 'Tactics';
            if (!in_array($cat, $puzzleCategories)) {
                $puzzleCategories[] = $cat;
            }
        }

        $recommendedPuzzles = Puzzle::whereIn('category', $puzzleCategories)
            ->limit(12)
            ->get()
            ->sortBy(fn ($p) => array_search($p->category, $puzzleCategories))
            ->take(4)
            ->values();

        // ── 4. Human-readable focus message ──────────────────────────────
        $weakestSkill  = array_key_first($weakSkills);
        $weakestLabel  = $this->skillLabel($weakestSkill);
        $weakestPct    = round($weakSkills[$weakestSkill] * 100);
        $focusMessage  = "Your {$weakestLabel} is at {$weakestPct}% mastery — "
            . "the content below is personalised to help you improve it fastest.";

        return response()->json([
            'weak_skills'          => $weakSkillsPayload,
            'recommended_lessons'  => $recommendedLessons,
            'recommended_puzzles'  => $recommendedPuzzles,
            'focus_message'        => $focusMessage,
        ]);
    }

    // ── Helpers ───────────────────────────────────────────────────────────

    private function skillLabel(string $skill): string
    {
        return match ($skill) {
            'tactical_oversight'   => 'Tactical Awareness',
            'positional_error'     => 'Positional Play',
            'endgame_fundamentals' => 'Endgame Technique',
            'opening_theory'       => 'Opening Theory',
            'king_safety'          => 'King Safety',
            'pawn_structure'       => 'Pawn Structure',
            'piece_coordination'   => 'Piece Coordination',
            'time_management'      => 'Time Management',
            default                => ucwords(str_replace('_', ' ', $skill)),
        };
    }

    private function skillIcon(string $skill): string
    {
        return match ($skill) {
            'tactical_oversight'   => 'bolt',
            'positional_error'     => 'psychology',
            'endgame_fundamentals' => 'flag',
            'opening_theory'       => 'door_front_door',
            'king_safety'          => 'security',
            'pawn_structure'       => 'grid_view',
            'piece_coordination'   => 'hub',
            'time_management'      => 'timer',
            default                => 'star',
        };
    }
}
