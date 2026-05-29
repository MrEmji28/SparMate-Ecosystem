<?php

namespace Database\Seeders;

use App\Models\Chapter;
use App\Models\Lesson;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class LessonSeeder extends Seeder
{
    /**
     * Seed the 8 lessons matching the hardcoded data in the Flutter LessonsScreen,
     * each with realistic chess chapters containing instructional content.
     */
    public function run(): void
    {
        $lessons = [
            [
                'title'       => 'Sicilian Defense',
                'category'    => 'Opening',
                'description' => 'Master the most aggressive and popular Black response to 1.e4. Learn the key pawn structures, tactical motifs, and strategic ideas.',
                'icon'        => 'shield',
                'color_hex'   => '#3949AB',
                'difficulty'  => 'intermediate',
                'chapters'    => [
                    ['title' => 'Introduction to 1...c5', 'content' => ['type' => 'text', 'body' => 'The Sicilian Defense (1.e4 c5) is Black\'s most popular and ambitious reply to 1.e4. By playing c5, Black immediately fights for the d4 square.', 'fen' => 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2']],
                    ['title' => 'Open Sicilian: 2.Nf3 d6 3.d4', 'content' => ['type' => 'text', 'body' => 'The Open Sicilian arises after 2.Nf3 followed by 3.d4. This creates an asymmetric pawn structure that leads to dynamic, unbalanced play.', 'fen' => 'rnbqkbnr/pp2pppp/3p4/2p5/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq d3 0 3']],
                    ['title' => 'The Najdorf Variation', 'content' => ['type' => 'text', 'body' => 'The Najdorf (5...a6) is the most theoretically dense variation. Black prepares ...e5 or ...b5 while maintaining maximum flexibility.', 'fen' => 'rnbqkb1r/1p2pppp/p2p1n2/8/3NP3/2N5/PPP2PPP/R1BQKB1R w KQkq - 0 6']],
                    ['title' => 'The Dragon Variation', 'content' => ['type' => 'text', 'body' => 'The Dragon (5...g6) fianchettoes the bishop to g7, creating a powerful diagonal that targets White\'s queenside.', 'fen' => 'rnbqkb1r/pp2pp1p/3p1np1/8/3NP3/2N5/PPP2PPP/R1BQKB1R w KQkq - 0 6']],
                    ['title' => 'The Scheveningen System', 'content' => ['type' => 'text', 'body' => 'The Scheveningen setup with ...e6 and ...d6 creates a solid but flexible pawn structure. Black aims to expand in the center later.']],
                    ['title' => 'The Sveshnikov Variation', 'content' => ['type' => 'text', 'body' => 'The Sveshnikov (3...e5) is a dynamic system where Black accepts a backward d-pawn and a hole on d5 in return for active piece play.']],
                    ['title' => 'Anti-Sicilians: 2.c3 and 2.Nc3', 'content' => ['type' => 'text', 'body' => 'Not all White players enter the Open Sicilian. Learn how to handle the Alapin (2.c3), Closed (2.Nc3), and Grand Prix Attack.']],
                    ['title' => 'Pawn Structures in the Sicilian', 'content' => ['type' => 'text', 'body' => 'Understanding the Maróczy Bind, isolated d-pawn structures, and the Hedgehog formation is essential for Sicilian mastery.']],
                    ['title' => 'Typical Tactical Motifs', 'content' => ['type' => 'text', 'body' => 'Common themes include Nd5 sacrifices, the ...Rxc3 exchange sacrifice, and kingside attacks in the Yugoslav Attack.']],
                    ['title' => 'Practical Games & Analysis', 'content' => ['type' => 'text', 'body' => 'Study complete master games from Kasparov, Fischer, and Nakamura to see Sicilian ideas in action.']],
                    ['title' => 'Opening Traps to Know', 'content' => ['type' => 'text', 'body' => 'Learn the most common traps in the Sicilian that can win material or the game outright in the opening phase.']],
                    ['title' => 'Review & Mastery Quiz', 'content' => ['type' => 'quiz', 'body' => 'Test your understanding of the Sicilian Defense with FEN-based puzzles and critical position recognition.']],
                ],
            ],
            [
                'title'       => 'Italian Game',
                'category'    => 'Opening',
                'description' => 'Learn the classical Italian Game and Giuoco Piano, one of the oldest and most instructive openings in chess.',
                'icon'        => 'door_front_door',
                'color_hex'   => '#1565C0',
                'difficulty'  => 'beginner',
                'chapters'    => [
                    ['title' => 'Introduction: 1.e4 e5 2.Nf3 Nc6 3.Bc4', 'content' => ['type' => 'text', 'body' => 'The Italian Game develops the bishop to an active square, targeting f7, the weakest point in Black\'s position.', 'fen' => 'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3']],
                    ['title' => 'The Giuoco Piano: 3...Bc5', 'content' => ['type' => 'text', 'body' => 'The "Quiet Game" — both sides develop harmoniously. White aims for d4, Black counters with ...d6 and ...0-0.']],
                    ['title' => 'The Evans Gambit', 'content' => ['type' => 'text', 'body' => 'The aggressive 4.b4!? gambit sacrifices a pawn for rapid development and a strong center.']],
                    ['title' => 'The Two Knights Defense', 'content' => ['type' => 'text', 'body' => '3...Nf6 is a more aggressive response, often leading to sharp tactical play with the Fried Liver Attack.']],
                    ['title' => 'Modern Main Lines', 'content' => ['type' => 'text', 'body' => 'Modern grandmaster practice in the Giuoco Piano with the slow d3 approach and piece maneuvering plans.']],
                    ['title' => 'Strategic Plans & Pawn Breaks', 'content' => ['type' => 'text', 'body' => 'Learn the key pawn breaks (d4, f4, a4) and piece placement ideas for both colors.']],
                    ['title' => 'Traps & Tactics', 'content' => ['type' => 'text', 'body' => 'Essential traps including the Légal Trap, the Fried Liver, and typical pin tactics on the e-file.']],
                    ['title' => 'Review & Mastery Quiz', 'content' => ['type' => 'quiz', 'body' => 'Test your knowledge of Italian Game theory and practical positions.']],
                ],
            ],
            [
                'title'       => "Queen's Gambit",
                'category'    => 'Opening',
                'description' => "Study the Queen's Gambit, a cornerstone of positional chess used by world champions throughout history.",
                'icon'        => 'door_front_door',
                'color_hex'   => '#6A1B9A',
                'difficulty'  => 'intermediate',
                'chapters'    => [
                    ['title' => 'Introduction: 1.d4 d5 2.c4', 'content' => ['type' => 'text', 'body' => "The Queen's Gambit is not a true gambit — Black can capture on c4 but typically cannot hold the pawn.", 'fen' => 'rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2']],
                    ['title' => "Queen's Gambit Declined", 'content' => ['type' => 'text', 'body' => '2...e6 is the classical response, maintaining the center but locking in the light-squared bishop.']],
                    ['title' => "Queen's Gambit Accepted", 'content' => ['type' => 'text', 'body' => '2...dxc4 accepts the pawn. Black aims to hold it or use the tempo to develop freely.']],
                    ['title' => 'The Slav Defense', 'content' => ['type' => 'text', 'body' => '2...c6 supports d5 while keeping the light-squared bishop mobile — a favorite of Carlsen.']],
                    ['title' => 'The Semi-Slav', 'content' => ['type' => 'text', 'body' => 'The Semi-Slav combines ...c6 and ...e6, leading to complex, theoretically dense positions.']],
                    ['title' => 'The Tartakower Variation', 'content' => ['type' => 'text', 'body' => 'A solid system with ...b6 allowing the bishop to develop to b7, popularized by Tartakower.']],
                    ['title' => 'Exchange Variation', 'content' => ['type' => 'text', 'body' => 'After cxd5 exd5, the position becomes symmetrical but White has a small edge with the minority attack.']],
                    ['title' => 'Typical Middlegame Plans', 'content' => ['type' => 'text', 'body' => "Minority attack, central pawn breaks, and piece maneuvering in the QGD middlegame."]],
                    ['title' => 'Master Games Analysis', 'content' => ['type' => 'text', 'body' => "Study classic games from Capablanca, Karpov, and Carlsen in the Queen's Gambit."]],
                    ['title' => 'Review & Mastery Quiz', 'content' => ['type' => 'quiz', 'body' => "Assess your understanding of Queen's Gambit structures and plans."]],
                ],
            ],
            [
                'title'       => 'Rook Endgames',
                'category'    => 'Endgame',
                'description' => 'Master the most common endgame type in chess. Rook endgames occur in over 50% of all games that reach an endgame.',
                'icon'        => 'castle',
                'color_hex'   => '#00838F',
                'difficulty'  => 'intermediate',
                'chapters'    => [
                    ['title' => 'Lucena Position', 'content' => ['type' => 'text', 'body' => 'The Lucena position is the most important winning technique in rook endgames. Learn the "bridge" building method.', 'fen' => '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1']],
                    ['title' => 'Philidor Position', 'content' => ['type' => 'text', 'body' => 'The Philidor defensive technique — the drawing method when defending a rook endgame a pawn down.', 'fen' => '4k3/8/4K3/4P3/8/8/8/r4R2 w - - 0 1']],
                    ['title' => 'Rook Behind Passed Pawns', 'content' => ['type' => 'text', 'body' => 'Tarrasch\'s Rule: "Always place your rook behind passed pawns." Learn why this principle is fundamental.']],
                    ['title' => 'Active vs Passive Rook', 'content' => ['type' => 'text', 'body' => 'An active rook is worth more than material advantage. Learn when to sacrifice pawns for rook activity.']],
                    ['title' => 'Rook + Pawn vs Rook', 'content' => ['type' => 'text', 'body' => 'The most fundamental endgame with one extra pawn. Not always winning — learn the key positions.']],
                    ['title' => 'Rook + 2 Pawns vs Rook + Pawn', 'content' => ['type' => 'text', 'body' => 'When the extra pawn is enough to win and when it leads to a draw. Connected vs isolated pawns.']],
                    ['title' => 'Rook Endgame with f and h Pawns', 'content' => ['type' => 'text', 'body' => 'The tricky f+h pawn configuration and why it often draws despite the two-pawn advantage.']],
                    ['title' => 'Rook vs Pawns', 'content' => ['type' => 'text', 'body' => 'When can a rook stop multiple passed pawns? Learn the critical distances and defensive techniques.']],
                    ['title' => 'Practical Rook Endgame Drills', 'content' => ['type' => 'text', 'body' => 'Practice positions from tournament games where rook endgame technique decided the result.']],
                    ['title' => 'Common Mistakes', 'content' => ['type' => 'text', 'body' => 'The most frequent errors in rook endgames: passive rook placement, wrong pawn races, and king activity.']],
                    ['title' => 'Advanced Concepts', 'content' => ['type' => 'text', 'body' => 'Vancura position, shouldering, and the concept of the "third rank defense" in complex rook endgames.']],
                    ['title' => 'Review & Mastery Quiz', 'content' => ['type' => 'quiz', 'body' => 'Solve rook endgame positions to test your technique and pattern recognition.']],
                ],
            ],
            [
                'title'       => 'Pawn Structure Mastery',
                'category'    => 'Strategy',
                'description' => 'Understand the backbone of positional chess. Every pawn move creates permanent weaknesses and strengths.',
                'icon'        => 'psychology',
                'color_hex'   => '#2E7D32',
                'difficulty'  => 'intermediate',
                'chapters'    => [
                    ['title' => 'Why Pawns Matter', 'content' => ['type' => 'text', 'body' => '"Pawns are the soul of chess" — Philidor. Every pawn structure dictates piece placement and strategic plans.']],
                    ['title' => 'Isolated Queen Pawn (IQP)', 'content' => ['type' => 'text', 'body' => 'The IQP on d4/d5 creates dynamic imbalances: attacking potential vs endgame weakness.']],
                    ['title' => 'Hanging Pawns', 'content' => ['type' => 'text', 'body' => 'Two adjacent pawns on the 4th rank without support — dynamic strength or static weakness?']],
                    ['title' => 'Pawn Chains', 'content' => ['type' => 'text', 'body' => 'Nimzowitsch\'s theory: attack the base of the pawn chain. Understanding d4-e5 vs d5-e6 chains.']],
                    ['title' => 'Doubled Pawns', 'content' => ['type' => 'text', 'body' => 'When are doubled pawns a weakness and when are they an asset? Open files and semi-open files.']],
                    ['title' => 'Backward Pawns', 'content' => ['type' => 'text', 'body' => 'The backward pawn creates a weak square in front of it — a perfect outpost for enemy pieces.']],
                    ['title' => 'Passed Pawns', 'content' => ['type' => 'text', 'body' => '"A passed pawn is a criminal which should be kept under lock and key" — Nimzowitsch. Creating and utilizing passers.']],
                    ['title' => 'The Pawn Majority', 'content' => ['type' => 'text', 'body' => 'Using a queenside or kingside pawn majority to create a passed pawn in the endgame.']],
                    ['title' => 'Review & Mastery Quiz', 'content' => ['type' => 'quiz', 'body' => 'Identify pawn structures and choose the correct strategic plans.']],
                ],
            ],
            [
                'title'       => 'Discovered Attacks',
                'category'    => 'Tactics',
                'description' => 'Learn the devastating power of discovered attacks and discovered checks — one of the most lethal tactical weapons.',
                'icon'        => 'bolt',
                'color_hex'   => '#E53935',
                'difficulty'  => 'beginner',
                'chapters'    => [
                    ['title' => 'What is a Discovered Attack?', 'content' => ['type' => 'text', 'body' => 'A discovered attack occurs when moving one piece reveals an attack by another piece behind it.']],
                    ['title' => 'Discovered Check', 'content' => ['type' => 'text', 'body' => 'The most powerful form: the discovered check forces the opponent to deal with check while the moving piece attacks freely.']],
                    ['title' => 'Double Check', 'content' => ['type' => 'text', 'body' => 'When both the moving piece and the uncovered piece give check simultaneously — the king must move.']],
                    ['title' => 'Discovered Attack Patterns', 'content' => ['type' => 'text', 'body' => 'Common setups involving bishops, rooks, and queens that enable discovered attacks.']],
                    ['title' => 'Practice Puzzles: Easy', 'content' => ['type' => 'puzzle', 'body' => 'Solve 10 beginner-level discovered attack positions.']],
                    ['title' => 'Review & Mastery Quiz', 'content' => ['type' => 'quiz', 'body' => 'Identify and execute discovered attacks in game-like positions.']],
                ],
            ],
            [
                'title'       => 'King & Pawn Endings',
                'category'    => 'Endgame',
                'description' => 'The foundation of all endgame knowledge. If you understand king and pawn endgames, you understand chess endgames.',
                'icon'        => 'flag',
                'color_hex'   => '#00695C',
                'difficulty'  => 'beginner',
                'chapters'    => [
                    ['title' => 'The Rule of the Square', 'content' => ['type' => 'text', 'body' => 'Can the king catch the pawn? The rule of the square provides an instant visual calculation method.']],
                    ['title' => 'Key Squares (Critical Squares)', 'content' => ['type' => 'text', 'body' => 'The three key squares in front of a passed pawn determine whether the pawn promotes or not.']],
                    ['title' => 'Opposition', 'content' => ['type' => 'text', 'body' => 'Direct opposition, distant opposition, and diagonal opposition — the most fundamental endgame concept.']],
                    ['title' => 'Triangulation', 'content' => ['type' => 'text', 'body' => 'Using a triangular king maneuver to lose a tempo and transfer the move to the opponent.']],
                    ['title' => 'Pawn Breakthroughs', 'content' => ['type' => 'text', 'body' => 'When a combination of pawn sacrifices forces a passed pawn through — a beautiful tactical motif.']],
                    ['title' => 'Protected Passed Pawns', 'content' => ['type' => 'text', 'body' => 'A passed pawn protected by another pawn is a tremendous asset in king and pawn endgames.']],
                    ['title' => 'Review & Mastery Quiz', 'content' => ['type' => 'quiz', 'body' => 'Evaluate king and pawn positions and determine the correct result with best play.']],
                ],
            ],
            [
                'title'       => 'Middlegame Planning',
                'category'    => 'Middlegame',
                'description' => 'Learn how to create and execute strategic plans in the middlegame — the phase where games are won and lost.',
                'icon'        => 'swap_horiz',
                'color_hex'   => '#EF6C00',
                'difficulty'  => 'advanced',
                'chapters'    => [
                    ['title' => 'What is a Plan?', 'content' => ['type' => 'text', 'body' => '"Even a bad plan is better than no plan at all" — Chigorin. Learn how to formulate strategic objectives.']],
                    ['title' => 'Evaluating the Position', 'content' => ['type' => 'text', 'body' => 'Material, king safety, piece activity, pawn structure, space — the five elements of position evaluation.']],
                    ['title' => 'Piece Coordination', 'content' => ['type' => 'text', 'body' => 'Making your pieces work together harmoniously. Avoiding piece collisions and redundancy.']],
                    ['title' => 'Prophylactic Thinking', 'content' => ['type' => 'text', 'body' => 'Petrosian\'s secret weapon: asking "What does my opponent want?" before making your own plans.']],
                    ['title' => 'Attacking the King', 'content' => ['type' => 'text', 'body' => 'When to attack, how to prepare, and the typical piece configurations needed for a successful assault.']],
                    ['title' => 'Queenside Play', 'content' => ['type' => 'text', 'body' => 'The minority attack, queenside pawn expansion, and creating weaknesses on the opponent\'s queenside.']],
                    ['title' => 'Maneuvering', 'content' => ['type' => 'text', 'body' => 'When there\'s no clear plan: improve piece placement through patient maneuvering. The Karpov method.']],
                    ['title' => 'Converting Advantages', 'content' => ['type' => 'text', 'body' => 'Techniques for converting a positional advantage into a winning endgame or decisive attack.']],
                    ['title' => 'Typical Mistakes', 'content' => ['type' => 'text', 'body' => 'Premature attacks, lack of prophylaxis, ignoring opponent\'s counterplay — common middlegame errors.']],
                    ['title' => 'Practical Planning Exercises', 'content' => ['type' => 'text', 'body' => 'Find the correct plan in complex middlegame positions from grandmaster practice.']],
                    ['title' => 'Review & Mastery Quiz', 'content' => ['type' => 'quiz', 'body' => 'Test your ability to formulate and execute middlegame plans.']],
                ],
            ],
        ];

        foreach ($lessons as $i => $lessonData) {
            $chapters = $lessonData['chapters'];
            unset($lessonData['chapters']);

            $lesson = Lesson::create(array_merge($lessonData, [
                'slug'          => Str::slug($lessonData['title']),
                'chapter_count' => count($chapters),
                'sort_order'    => $i + 1,
            ]));

            foreach ($chapters as $j => $chapter) {
                Chapter::create([
                    'lesson_id'  => $lesson->id,
                    'title'      => $chapter['title'],
                    'sort_order' => $j + 1,
                    'content'    => $chapter['content'],
                ]);
            }
        }
    }
}
