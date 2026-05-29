<?php

namespace Database\Seeders;

use App\Models\Grandmaster;
use App\Models\Lesson;
use App\Models\PuzzleAttempt;
use App\Models\SparringMatch;
use App\Models\TrainingPlan;
use App\Models\User;
use App\Models\UserBktMatrix;
use App\Models\UserLessonProgress;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoUserSeeder extends Seeder
{
    /**
     * Seed a demo user with realistic sample data so the API returns
     * populated responses out of the box.
     */
    public function run(): void
    {
        // ── Demo User ────────────────────────────────────────────────
        $user = User::create([
            'name'        => 'Marc',
            'email'       => 'demo@sparmate.app',
            'password'    => Hash::make('password123'),
            'elo_rating'  => 1420,
            'streak_days' => 7,
        ]);

        // ── BKT Matrix (with some realistic progress) ────────────────
        UserBktMatrix::create([
            'user_id' => $user->id,
            'matrix'  => [
                'tactical_oversight'   => 0.45,
                'positional_error'     => 0.62,
                'endgame_fundamentals' => 0.78,
                'opening_theory'       => 0.55,
                'king_safety'          => 0.40,
                'pawn_structure'       => 0.58,
                'piece_coordination'   => 0.50,
                'time_management'      => 0.35,
            ],
        ]);

        // ── Lesson Progress (Sicilian at 65%, King & Pawn started) ───
        $sicilian = Lesson::where('slug', 'sicilian-defense')->first();
        if ($sicilian) {
            $chapter8 = $sicilian->chapters()->where('sort_order', 8)->first();
            UserLessonProgress::create([
                'user_id'            => $user->id,
                'lesson_id'          => $sicilian->id,
                'current_chapter_id' => $chapter8?->id,
                'progress'           => 0.65,
                'started_at'         => now()->subDays(14),
            ]);
        }

        $kpe = Lesson::where('slug', 'king-pawn-endings')->first();
        if ($kpe) {
            $chapter2 = $kpe->chapters()->where('sort_order', 2)->first();
            UserLessonProgress::create([
                'user_id'            => $user->id,
                'lesson_id'          => $kpe->id,
                'current_chapter_id' => $chapter2?->id,
                'progress'           => 0.28,
                'started_at'         => now()->subDays(5),
            ]);
        }

        // ── Sparring Match History ───────────────────────────────────
        $grandmasters = Grandmaster::all();
        $results      = ['win', 'loss', 'draw', 'win', 'loss', 'win', 'win', 'loss', 'draw', 'win'];
        $blunderTypes  = [
            'tactical_oversight', 'positional_error', 'endgame_fundamentals',
            'king_safety', 'pawn_structure', 'time_management',
        ];

        for ($i = 0; $i < 10; $i++) {
            $gm = $grandmasters[$i % $grandmasters->count()];
            $result = $results[$i];

            SparringMatch::create([
                'user_id'          => $user->id,
                'grandmaster_id'   => $gm->id,
                'pgn'              => '1. e4 c5 2. Nf3 d6 3. d4 cxd4 4. Nxd4',
                'fen_final'        => 'rnbqkbnr/pp2pppp/3p4/8/3NP3/8/PPP2PPP/RNBQKB1R b KQkq - 0 4',
                'result'           => $result,
                'move_count'       => rand(25, 65),
                'duration_seconds' => rand(300, 1200),
                'pressure_avg'     => round(rand(20, 80) + rand(0, 99) / 100, 2),
                'analysis'         => $result === 'loss' ? [
                    ['category' => $blunderTypes[array_rand($blunderTypes)], 'move' => rand(10, 40), 'severity' => 'blunder'],
                    ['category' => $blunderTypes[array_rand($blunderTypes)], 'move' => rand(20, 50), 'severity' => 'mistake'],
                ] : ($result === 'draw' ? [
                    ['category' => $blunderTypes[array_rand($blunderTypes)], 'move' => rand(15, 35), 'severity' => 'inaccuracy'],
                ] : []),
                'played_at' => now()->subDays(10 - $i)->subHours(rand(1, 12)),
            ]);
        }

        // ── Puzzle Attempts ──────────────────────────────────────────
        $puzzles = \App\Models\Puzzle::take(8)->get();
        foreach ($puzzles as $j => $puzzle) {
            PuzzleAttempt::create([
                'user_id'      => $user->id,
                'puzzle_id'    => $puzzle->id,
                'solved'       => $j % 3 !== 0, // ~67% solve rate
                'time_seconds' => rand(15, 180),
                'attempted_at' => now()->subDays(rand(0, 7)),
            ]);
        }

        // ── Training Plan ────────────────────────────────────────────
        TrainingPlan::create([
            'user_id'           => $user->id,
            'primary_directive' => 'Your time management and king safety are your weakest areas. Focus on controlling the clock and calculating king safety before committing to aggressive plans.',
            'weekly_focus'      => ['Time Management', 'King Safety', 'Tactical Oversight'],
            'plan_items'        => [
                ['day' => 'Monday',    'activity' => 'King Safety Drill',           'duration_min' => 20, 'type' => 'lesson'],
                ['day' => 'Tuesday',   'activity' => 'Tactical Puzzles (Pins)',     'duration_min' => 15, 'type' => 'puzzle'],
                ['day' => 'Wednesday', 'activity' => 'Spar vs Petrosian',           'duration_min' => 30, 'type' => 'sparring'],
                ['day' => 'Thursday',  'activity' => 'Endgame Fundamentals Review', 'duration_min' => 20, 'type' => 'lesson'],
                ['day' => 'Friday',    'activity' => 'Speed Puzzles (Timed)',       'duration_min' => 15, 'type' => 'puzzle'],
                ['day' => 'Saturday',  'activity' => 'Spar vs Torre',              'duration_min' => 30, 'type' => 'sparring'],
                ['day' => 'Sunday',    'activity' => 'Game Review & Analysis',      'duration_min' => 25, 'type' => 'lesson'],
            ],
            'generated_at' => now()->subDays(2),
        ]);
    }
}
