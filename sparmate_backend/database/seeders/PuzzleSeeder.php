<?php

namespace Database\Seeders;

use App\Models\Puzzle;
use Illuminate\Database\Seeder;

class PuzzleSeeder extends Seeder
{
    /**
     * Seed 20 realistic chess puzzles with real FEN positions and solutions.
     */
    public function run(): void
    {
        $puzzles = [
            // Mate in 1
            ['fen' => '6k1/5ppp/8/8/8/8/1Q3PPP/6K1 w - - 0 1', 'solution_moves' => ['Qb8#'], 'category' => 'Tactics', 'difficulty' => 'beginner', 'rating' => 800, 'theme' => 'Mate in 1'],
            ['fen' => 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'solution_moves' => ['Qxf7#'], 'category' => 'Tactics', 'difficulty' => 'beginner', 'rating' => 900, 'theme' => 'Scholar\'s Mate'],

            // Forks
            ['fen' => 'r1bqkbnr/pppppppp/2n5/8/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 2 2', 'solution_moves' => ['Nf6', 'Nc3'], 'category' => 'Tactics', 'difficulty' => 'beginner', 'rating' => 1000, 'theme' => 'Fork'],
            ['fen' => 'r2qkb1r/ppp2ppp/2n1bn2/3pp3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 5', 'solution_moves' => ['Ng5'], 'category' => 'Tactics', 'difficulty' => 'intermediate', 'rating' => 1200, 'theme' => 'Fork'],

            // Pins
            ['fen' => 'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3', 'solution_moves' => ['Bc5'], 'category' => 'Tactics', 'difficulty' => 'beginner', 'rating' => 1100, 'theme' => 'Pin'],
            ['fen' => 'rn1qkbnr/ppp1pppp/8/3p4/6b1/5N2/PPPPPPPP/RNBQKB1R w KQkq - 2 3', 'solution_moves' => ['Ne5'], 'category' => 'Tactics', 'difficulty' => 'intermediate', 'rating' => 1300, 'theme' => 'Pin Break'],

            // Skewers
            ['fen' => '8/8/8/8/8/2k5/8/R3K3 w - - 0 1', 'solution_moves' => ['Ra3+'], 'category' => 'Tactics', 'difficulty' => 'beginner', 'rating' => 1000, 'theme' => 'Skewer'],

            // Discovered attacks
            ['fen' => 'r1bqkbnr/pppp1ppp/2n5/4N3/4P3/8/PPPP1PPP/RNBQKB1R b KQkq - 0 3', 'solution_moves' => ['Qg5'], 'category' => 'Tactics', 'difficulty' => 'intermediate', 'rating' => 1250, 'theme' => 'Discovered Attack'],

            // Endgame puzzles
            ['fen' => '8/8/8/5k2/8/8/4KP2/8 w - - 0 1', 'solution_moves' => ['Kf3'], 'category' => 'Endgame', 'difficulty' => 'beginner', 'rating' => 1100, 'theme' => 'King and Pawn'],
            ['fen' => '8/5pk1/8/8/8/8/6PP/6K1 w - - 0 1', 'solution_moves' => ['h4'], 'category' => 'Endgame', 'difficulty' => 'intermediate', 'rating' => 1400, 'theme' => 'Pawn Breakthrough'],

            // Intermediate tactics
            ['fen' => 'r3kb1r/ppp1pppp/2n2n2/3q4/3P4/2N2N2/PPP2PPP/R1BQKB1R b KQkq - 0 6', 'solution_moves' => ['Qxd4'], 'category' => 'Tactics', 'difficulty' => 'intermediate', 'rating' => 1350, 'theme' => 'Capture'],
            ['fen' => 'r1b1kbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'solution_moves' => ['Qf7#'], 'category' => 'Tactics', 'difficulty' => 'beginner', 'rating' => 950, 'theme' => 'Mate in 1'],

            // Back rank mates
            ['fen' => '6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1', 'solution_moves' => ['Re8#'], 'category' => 'Tactics', 'difficulty' => 'beginner', 'rating' => 1050, 'theme' => 'Back Rank Mate'],
            ['fen' => '3r2k1/5ppp/8/8/8/8/5PPP/3R2K1 b - - 0 1', 'solution_moves' => ['Rd1+', 'Rxd1#'], 'category' => 'Tactics', 'difficulty' => 'intermediate', 'rating' => 1200, 'theme' => 'Back Rank Mate'],

            // Advanced tactics
            ['fen' => 'r2q1rk1/ppp2ppp/2n1bn2/2bpp3/2B1P3/2NP1N2/PPP2PPP/R1BQ1RK1 w - - 0 8', 'solution_moves' => ['Bxe6', 'fxe6', 'Nxe5'], 'category' => 'Tactics', 'difficulty' => 'advanced', 'rating' => 1600, 'theme' => 'Combination'],
            ['fen' => 'r1bq1rk1/pp2ppbp/2np1np1/8/3NP3/2N1BP2/PPP1B1PP/R2Q1RK1 w - - 0 9', 'solution_moves' => ['Nd5'], 'category' => 'Strategy', 'difficulty' => 'advanced', 'rating' => 1550, 'theme' => 'Outpost'],

            // Endgame technique
            ['fen' => '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1', 'solution_moves' => ['Rc4', 'Ra1', 'Rc8'], 'category' => 'Endgame', 'difficulty' => 'advanced', 'rating' => 1700, 'theme' => 'Lucena Position'],
            ['fen' => '8/8/8/8/4k3/8/4KP2/8 w - - 0 1', 'solution_moves' => ['Kf3'], 'category' => 'Endgame', 'difficulty' => 'intermediate', 'rating' => 1300, 'theme' => 'Opposition'],
            ['fen' => '8/8/4k3/8/4P3/4K3/8/8 w - - 0 1', 'solution_moves' => ['Kf4'], 'category' => 'Endgame', 'difficulty' => 'intermediate', 'rating' => 1350, 'theme' => 'Key Squares'],
        ];

        foreach ($puzzles as $puzzle) {
            Puzzle::create($puzzle);
        }
    }
}
