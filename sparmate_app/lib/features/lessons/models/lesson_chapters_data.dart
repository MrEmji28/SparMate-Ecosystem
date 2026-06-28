import 'lesson_step.dart';

/// Static teaching content for lesson chapters, keyed by lesson title.
///
/// Each lesson has its own set of chapter titles and step-by-step board
/// teaching content, making every lesson feel unique and purpose-built.
class LessonChaptersData {
  LessonChaptersData._();

  /// Returns chapter titles for a given lesson.
  static List<String> getChapterTitles(String lessonTitle) {
    return _chapterTitles[lessonTitle] ?? _defaultChapterTitles;
  }

  /// Returns the steps for a given lesson + chapter.
  static List<LessonStep> getSteps(String lessonTitle, int chapterIndex) {
    final lessonData = _lessonContent[lessonTitle];
    if (lessonData != null && chapterIndex < lessonData.length) {
      return lessonData[chapterIndex];
    }
    return _generateFallbackSteps(lessonTitle, chapterIndex);
  }

  // ── Chapter titles per lesson ────────────────────────────────────────

  static const _defaultChapterTitles = [
    'Introduction & Overview',
    'Core Principles',
    'Key Variations',
    'Tactical Patterns',
    'Positional Ideas',
    'Strategic Plans',
    'Common Mistakes',
    'Pawn Structures & Plans',
    'Typical Middlegame Ideas',
    'Endgame Transitions',
    'Common Traps & Pitfalls',
    'Putting It All Together',
  ];

  static const _chapterTitles = <String, List<String>>{
    'Sicilian Defense': [
      'The Sicilian Move Order',
      'Open Sicilian Basics',
      'The Najdorf Variation',
      'The Dragon Variation',
      'Scheveningen System',
      'Anti-Sicilians',
      'Pawn Structures',
      'Attacking the King',
      'Typical Endgames',
      'Sicilian Tactics',
      'Common Mistakes',
      'Master Games Analysis',
    ],
    'Italian Game': [
      'Giuoco Piano Setup',
      'Center Control with e4 d4',
      'The Evans Gambit',
      'Two Knights Defense',
      'Slow Italian (Giuoco Pianissimo)',
      'Attacking f7',
      'Middlegame Plans',
      'Putting It Together',
    ],
    "Queen's Gambit": [
      'The Queen\'s Gambit Move',
      'Accepted: Taking the Pawn',
      'Declined: Holding the Center',
      'The Slav Defense',
      'Semi-Slav Systems',
      'Minority Attack',
      'Central Pawn Breaks',
      'IQP Positions',
      'Endgame Technique',
      'Master Games',
    ],
    'Rook Endgames': [
      'Rook Endgame Basics',
      'The Lucena Position',
      'The Philidor Defense',
      'Rook + Pawn vs Rook',
      'Active vs Passive Rook',
      'Cutting Off the King',
      'Two Pawns Advantage',
      'Rook & Passed Pawns',
      'Practical Rook Endings',
      'Defending Worse Positions',
      'Converting Advantages',
      'Complex Rook Endgames',
    ],
    'Pawn Structure Mastery': [
      'What Is Pawn Structure?',
      'Isolated Queen\'s Pawn',
      'Hanging Pawns',
      'Pawn Chains',
      'Doubled Pawns',
      'Backward Pawns',
      'Pawn Majority',
      'Passed Pawns',
      'Structure & Piece Placement',
    ],
    'Discovered Attacks': [
      'What Is a Discovered Attack?',
      'Discovered Check',
      'Double Check',
      'Setting Up Discoveries',
      'Famous Discovered Attacks',
      'Practice Puzzles',
    ],
    'King & Pawn Endings': [
      'Opposition',
      'Key Squares',
      'Triangulation',
      'Pawn Races',
      'Outside Passed Pawn',
      'Breakthrough',
      'Complex K+P Endings',
    ],
    'Middlegame Planning': [
      'How to Make a Plan',
      'Evaluating the Position',
      'Piece Activity',
      'Weak Squares & Outposts',
      'Open Files & Diagonals',
      'Pawn Breaks',
      'Prophylaxis',
      'Attack & Defense',
      'Piece Coordination',
      'Converting Advantages',
      'Practical Decision Making',
    ],
    'Pin & Fork Tactics': [
      'What Is a Pin?',
      'Absolute vs Relative Pins',
      'Exploiting Pins',
      'What Is a Fork?',
      'Knight Forks',
      'Pawn Forks',
      'Queen & Bishop Forks',
      'Combined Tactics',
    ],
    'Exchange Sacrifice': [
      'What Is an Exchange Sacrifice?',
      'Positional Exchange Sac',
      'Petrosian\'s Method',
      'Attacking Exchange Sac',
      'When to Sacrifice',
    ],
  };

  // ── Lesson content: each lesson → list of chapters → list of steps ──

  static const _lessonContent = <String, List<List<LessonStep>>>{
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // SICILIAN DEFENSE
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'Sicilian Defense': [
      // Chapter 0: The Sicilian Move Order
      [
        LessonStep(
          fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
          move: 'e2e4',
          highlights: ['e4'],
          commentary: '1. e4 — The King\'s Pawn opening. White claims the center and opens lines for the queen and bishop.',
          concept: 'Center Control',
        ),
        LessonStep(
          fen: 'rnbqkbnr/pp1ppppp/8/2p5/4P3/8/PPPP1PPP/RNBQKBNR w KQkq c6 0 2',
          move: 'c7c5',
          highlights: ['c5', 'd4'],
          commentary: '1...c5 — The Sicilian! Black fights for d4 control asymmetrically rather than mirroring White\'s pawn.',
          concept: 'Asymmetric Play',
        ),
        LessonStep(
          fen: 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
          move: 'g1f3',
          highlights: ['f3'],
          arrows: [['f3', 'd4']],
          commentary: '2. Nf3 — Developing toward d4. This prepares the Open Sicilian, the most critical and popular approach.',
          concept: 'Development',
        ),
        LessonStep(
          fen: 'rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
          highlights: ['d4', 'e4', 'd5', 'e5'],
          commentary: 'The center is the battlefield. White wants d4, Black fights against it. This tension defines the Sicilian character.',
          concept: 'Central Tension',
        ),
      ],
      // Chapter 1: Open Sicilian Basics
      [
        LessonStep(
          fen: 'rnbqkbnr/pp2pppp/3p4/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3',
          move: 'd7d6',
          highlights: ['d6'],
          commentary: '2...d6 — The most flexible response, supporting the c5 pawn and preparing Nf6. This can lead to the Najdorf, Dragon, or Scheveningen.',
          concept: 'Flexible Setup',
        ),
        LessonStep(
          fen: 'rnbqkbnr/pp2pppp/3p4/2p5/3PP3/5N2/PPP2PPP/RNBQKB1R b KQkq d3 0 3',
          move: 'd2d4',
          highlights: ['d4'],
          arrows: [['c5', 'd4']],
          commentary: '3. d4! White strikes in the center. This pawn will be captured, but White gets rapid development in return.',
          concept: 'Open Sicilian',
        ),
        LessonStep(
          fen: 'rnbqkbnr/pp2pppp/3p4/8/3pP3/5N2/PPP2PPP/RNBQKB1R w KQkq - 0 4',
          move: 'c5d4',
          highlights: ['d4'],
          commentary: '3...cxd4 — Black captures, opening the c-file. This is the key structural trade: Black gets the semi-open c-file, White gets the central majority.',
          concept: 'Pawn Structure',
        ),
        LessonStep(
          fen: 'rnbqkbnr/pp2pppp/3p4/8/3NP3/8/PPP2PPP/RNBQKB1R b KQkq - 0 4',
          move: 'f3d4',
          highlights: ['d4'],
          commentary: '4. Nxd4 — The knight lands on a commanding central square. The Open Sicilian has begun!',
          concept: 'Knight Center',
        ),
      ],
      // Chapter 2: The Najdorf Variation
      [
        LessonStep(
          fen: 'rnbqkb1r/pp2pppp/3p1n2/8/3NP3/2N5/PPP2PPP/R1BQKB1R b KQkq - 2 5',
          highlights: ['c3', 'd4'],
          commentary: 'The Najdorf starting position. White has developed both knights, Black will play ...a6 to prepare counterplay.',
          concept: 'Najdorf Setup',
        ),
        LessonStep(
          fen: 'rnbqkb1r/1p2pppp/p2p1n2/8/3NP3/2N5/PPP2PPP/R1BQKB1R w KQkq - 0 6',
          move: 'a7a6',
          highlights: ['a6'],
          arrows: [['a6', 'b5']],
          commentary: '5...a6 — The Najdorf move! It prevents Bb5, prepares ...e5 or ...b5, and keeps maximum flexibility.',
          concept: 'The Najdorf Move',
        ),
        LessonStep(
          fen: 'rnbqkb1r/1p2pppp/p2p1n2/8/3NP3/2N5/PPP1BPPP/R1BQK2R b KQkq - 1 6',
          move: 'f1e2',
          highlights: ['e2'],
          commentary: '6. Be2 — A solid, classical approach. White develops calmly and prepares castling. Other options include 6.Bg5 (the main line) and 6.f3 (English Attack).',
        ),
        LessonStep(
          fen: 'rnbqkb1r/1p3ppp/p2ppn2/8/3NP3/2N5/PPP1BPPP/R1BQK2R w KQkq - 0 7',
          move: 'e7e6',
          highlights: ['e6', 'd5'],
          commentary: '6...e6 — The Scheveningen-Najdorf hybrid. Black builds a solid pawn wall on d6-e6, keeping the position flexible.',
          concept: 'Solid Center',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ITALIAN GAME
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'Italian Game': [
      // Chapter 0: Giuoco Piano Setup
      [
        LessonStep(
          fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
          move: 'e2e4',
          highlights: ['e4'],
          commentary: '1. e4 — Opening the game with the king\'s pawn, claiming central space immediately.',
          concept: 'King\'s Pawn',
        ),
        LessonStep(
          fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2',
          move: 'e7e5',
          highlights: ['e5', 'e4'],
          commentary: '1...e5 — Black mirrors White\'s claim to the center. Both sides have equal central presence — a classical start.',
          concept: 'Symmetrical Center',
        ),
        LessonStep(
          fen: 'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
          move: 'g1f3',
          highlights: ['f3'],
          arrows: [['f3', 'e5']],
          commentary: '2. Nf3 — Attacking Black\'s e5 pawn while developing a piece. The most natural move in chess.',
          concept: 'Development',
        ),
        LessonStep(
          fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
          move: 'b8c6',
          highlights: ['c6'],
          commentary: '2...Nc6 — Defending the e5 pawn with a developing move. Perfect efficiency!',
        ),
        LessonStep(
          fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3',
          move: 'f1c4',
          highlights: ['c4'],
          arrows: [['c4', 'f7']],
          commentary: '3. Bc4 — The Italian Game! The bishop targets f7, the weakest square in Black\'s camp (defended only by the king).',
          concept: 'Italian Bishop',
        ),
      ],
      // Chapter 1: Center Control with e4 d4
      [
        LessonStep(
          fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
          highlights: ['e4', 'e5', 'c4', 'f7'],
          commentary: 'The Italian Game position after 3...Nf6. White\'s bishop is powerfully placed on c4. Now the question: how to fight for the center?',
          concept: 'Position Assessment',
        ),
        LessonStep(
          fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2BPP3/5N2/PPP2PPP/RNBQK2R b KQkq d3 0 4',
          move: 'd2d4',
          highlights: ['d4', 'e5'],
          arrows: [['d4', 'e5']],
          commentary: 'd4! — White opens the center aggressively. This challenges Black\'s e5 pawn and opens lines for all White\'s pieces.',
          concept: 'Central Strike',
        ),
        LessonStep(
          fen: 'r1bqkb1r/pppp1ppp/2n2n2/8/2BpP3/5N2/PPP2PPP/RNBQK2R w KQkq - 0 5',
          move: 'e5d4',
          highlights: ['d4'],
          commentary: '4...exd4 — Black captures but opens the center. White now has excellent development and piece activity.',
          concept: 'Open Center',
        ),
        LessonStep(
          fen: 'r1bqkb1r/pppp1ppp/2n2n2/8/2BpP3/5N2/PPP2PPP/RNBQK2R w KQkq - 0 5',
          arrows: [['f3', 'd4'], ['f1', 'c4'], ['c1', 'g5']],
          commentary: 'White has rapid development and an open center. The lead in development is critical — White must attack before Black catches up!',
          concept: 'Development Lead',
        ),
      ],
      // Chapter 2: The Evans Gambit
      [
        LessonStep(
          fen: 'r1bqk1nr/pppp1ppp/2n5/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
          highlights: ['c5', 'c4'],
          commentary: 'After 3...Bc5, Black develops the bishop actively. Now White can play the bold Evans Gambit!',
          concept: 'Giuoco Piano',
        ),
        LessonStep(
          fen: 'r1bqk1nr/pppp1ppp/2n5/2b1p3/1PB1P3/5N2/P1PP1PPP/RNBQK2R b KQkq b3 0 4',
          move: 'b2b4',
          highlights: ['b4'],
          arrows: [['b4', 'c5']],
          commentary: '4. b4! — The Evans Gambit! White sacrifices a pawn to deflect the bishop and gain a massive lead in development.',
          concept: 'Evans Gambit',
        ),
        LessonStep(
          fen: 'r1bqk1nr/pppp1ppp/2n5/4p3/1bB1P3/5N2/P1PP1PPP/RNBQK2R w KQkq - 0 5',
          move: 'c5b4',
          highlights: ['b4'],
          commentary: '4...Bxb4 — Black accepts the gambit. Now White plays c3 to build a powerful pawn center with d4.',
        ),
        LessonStep(
          fen: 'r1bqk1nr/pppp1ppp/2n5/4p3/1bB1P3/2P2N2/P2P1PPP/RNBQK2R b KQkq - 0 5',
          move: 'c2c3',
          highlights: ['c3'],
          arrows: [['c3', 'd4']],
          commentary: '5. c3 — Preparing d4 with tempo. The bishop must retreat, and White builds the ideal pawn center. Rapid development and attacking chances ahead!',
          concept: 'Pawn Center',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // QUEEN'S GAMBIT
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    "Queen's Gambit": [
      // Chapter 0: The Queen's Gambit Move
      [
        LessonStep(
          fen: 'rnbqkbnr/pppppppp/8/8/3P4/8/PPP1PPPP/RNBQKBNR b KQkq d3 0 1',
          move: 'd2d4',
          highlights: ['d4'],
          commentary: '1. d4 — The Queen\'s Pawn opening. White occupies the center with a pawn already protected by the queen.',
          concept: 'Queen\'s Pawn',
        ),
        LessonStep(
          fen: 'rnbqkbnr/ppp1pppp/8/3p4/3P4/8/PPP1PPPP/RNBQKBNR w KQkq d6 0 2',
          move: 'd7d5',
          highlights: ['d5', 'd4'],
          commentary: '1...d5 — Black mirrors the center control. Both sides claim d4/d5 — a classical standoff.',
          concept: 'Symmetrical Center',
        ),
        LessonStep(
          fen: 'rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2',
          move: 'c2c4',
          highlights: ['c4'],
          arrows: [['c4', 'd5']],
          commentary: '2. c4 — The Queen\'s Gambit! White offers a pawn to undermine Black\'s d5 control. It\'s not a true gambit — White can usually recover the pawn.',
          concept: 'Queen\'s Gambit',
        ),
        LessonStep(
          fen: 'rnbqkbnr/ppp1pppp/8/3p4/2PP4/8/PP2PPPP/RNBQKBNR b KQkq c3 0 2',
          arrows: [['d5', 'c4'], ['e7', 'e6']],
          commentary: 'Black faces a critical choice: accept the gambit (dxc4) or decline it (e6). Each leads to fundamentally different positions.',
          concept: 'Critical Decision',
        ),
      ],
      // Chapter 1: Accepted — Taking the Pawn
      [
        LessonStep(
          fen: 'rnbqkbnr/ppp1pppp/8/8/2pP4/8/PP2PPPP/RNBQKBNR w KQkq - 0 3',
          move: 'd5c4',
          highlights: ['c4'],
          commentary: '2...dxc4 — The Queen\'s Gambit Accepted! Black takes the pawn but gives up the center. White will aim to dominate with e4.',
          concept: 'QGA',
        ),
        LessonStep(
          fen: 'rnbqkbnr/ppp1pppp/8/8/2pPP3/8/PP3PPP/RNBQKBNR b KQkq e3 0 3',
          move: 'e2e4',
          highlights: ['e4', 'd4'],
          commentary: 'e4! — White builds the ideal pawn center. Two pawns on d4 and e4 control everything. Black must find counterplay quickly.',
          concept: 'Ideal Center',
        ),
        LessonStep(
          fen: 'rnbqkbnr/ppp1pppp/8/8/2pPP3/8/PP3PPP/RNBQKBNR b KQkq e3 0 3',
          arrows: [['c8', 'g4'], ['b7', 'b5']],
          commentary: 'Black\'s plans: develop quickly with ...Nf6, ...e6, and ...c5 to challenge the center. Holding the c4 pawn long-term is usually not advisable.',
          concept: 'Counterplay',
        ),
      ],
      // Chapter 2: Declined — Holding the Center
      [
        LessonStep(
          fen: 'rnbqkbnr/ppp2ppp/4p3/3p4/2PP4/8/PP2PPPP/RNBQKBNR w KQkq - 0 2',
          move: 'e7e6',
          highlights: ['e6', 'd5'],
          commentary: '2...e6 — The Queen\'s Gambit Declined. Black solidly defends d5 with the e-pawn. Very solid but slightly passive.',
          concept: 'QGD',
        ),
        LessonStep(
          fen: 'rnbqkbnr/ppp2ppp/4p3/3p4/2PP4/2N5/PP2PPPP/R1BQKBNR b KQkq - 1 3',
          move: 'b1c3',
          highlights: ['c3'],
          arrows: [['c3', 'd5']],
          commentary: '3. Nc3 — Developing with pressure on d5. White\'s knight adds force to the central tension.',
          concept: 'Central Pressure',
        ),
        LessonStep(
          fen: 'rnbqkb1r/ppp2ppp/4pn2/3p4/2PP4/2N5/PP2PPPP/R1BQKBNR w KQkq - 2 3',
          move: 'g8f6',
          highlights: ['f6'],
          commentary: '3...Nf6 — Black develops and adds another defender to d5. The position is solid and Black can gradually equalize.',
        ),
        LessonStep(
          fen: 'rnbqkb1r/ppp2ppp/4pn2/3p2B1/2PP4/2N5/PP2PPPP/R2QKBNR b KQkq - 3 4',
          move: 'c1g5',
          highlights: ['g5', 'f6'],
          arrows: [['g5', 'f6']],
          commentary: '4. Bg5 — Pinning the knight! This is the classical main line. The pin on f6 creates indirect pressure on d5.',
          concept: 'Pin on f6',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ROOK ENDGAMES
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'Rook Endgames': [
      // Chapter 0: Rook Endgame Basics
      [
        LessonStep(
          fen: '8/8/8/8/8/4k3/4P3/4K2R w - - 0 1',
          highlights: ['e2', 'e3'],
          commentary: 'Rook endgames are the most common endgame type. The key principle: rooks belong BEHIND passed pawns, whether yours or your opponent\'s.',
          concept: 'Rook Behind Pawns',
        ),
        LessonStep(
          fen: '8/8/8/8/8/4k3/4P3/4K2R w - - 0 1',
          arrows: [['h1', 'h8'], ['e1', 'd2']],
          commentary: 'The rook is most active on open files. Here White\'s rook can swing to the h-file to support the pawn or control the back rank.',
          concept: 'Rook Activity',
        ),
        LessonStep(
          fen: '4R3/8/4k3/8/8/4K3/4P3/8 w - - 0 1',
          highlights: ['e8', 'e6', 'e3'],
          arrows: [['e8', 'e6']],
          commentary: 'Cutting off the king is crucial! The rook on e8 prevents Black\'s king from approaching the pawn. The farther the cut-off, the easier the win.',
          concept: 'King Cut-Off',
        ),
      ],
      // Chapter 1: The Lucena Position
      [
        LessonStep(
          fen: '4K3/4P1k1/8/8/8/8/8/4R3 w - - 0 1',
          highlights: ['e8', 'e7'],
          commentary: 'The Lucena Position — the most important position in all of chess endgames. White has a pawn on the 7th rank with the king in front, but needs to escape the check.',
          concept: 'Lucena Position',
        ),
        LessonStep(
          fen: '4K3/4P1k1/8/8/8/8/8/4R3 w - - 0 1',
          arrows: [['e8', 'd7'], ['e1', 'd1']],
          commentary: 'The key idea is "building a bridge." White needs to bring the rook to d1, then shield the king from checks by placing the rook on d4.',
          concept: 'Building the Bridge',
        ),
        LessonStep(
          fen: '3K4/4P1k1/8/8/8/8/8/3R4 w - - 0 1',
          move: 'e8d8',
          highlights: ['d8', 'd1'],
          commentary: 'Kd8! Step 1 — The king steps aside. Now the pawn can promote once it\'s safe. The rook on d1 will provide the bridge.',
        ),
        LessonStep(
          fen: '3K4/4P3/6k1/8/3R4/8/8/8 w - - 0 1',
          highlights: ['d4'],
          arrows: [['d4', 'd8']],
          commentary: 'The rook reaches d4 — the bridge is ready! After Ke7 and any Black check, Rd4-d8 shields the king. The pawn promotes!',
          concept: 'The Bridge',
        ),
      ],
      // Chapter 2: The Philidor Defense
      [
        LessonStep(
          fen: '8/3KP3/8/8/8/4r3/5k2/8 b - - 0 1',
          highlights: ['e3', 'e7'],
          commentary: 'The Philidor Defense — the key defensive technique. Black\'s rook on the 3rd rank prevents the White king from advancing.',
          concept: 'Philidor Defense',
        ),
        LessonStep(
          fen: '8/3KP3/8/8/8/4r3/5k2/8 b - - 0 1',
          arrows: [['e3', 'a3']],
          commentary: 'When the pawn advances to the 6th rank (from Black\'s view), the rook retreats to the back rank to give checks from behind. This is the drawing technique!',
          concept: 'Checking Distance',
        ),
        LessonStep(
          fen: '8/3KP3/8/8/8/r7/5k2/8 b - - 0 1',
          highlights: ['a3'],
          commentary: 'The rook stays on the 3rd rank, keeping the White king cut off. As long as Black maintains this setup, the position is drawn!',
          concept: 'Third Rank Defense',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // PAWN STRUCTURE MASTERY
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'Pawn Structure Mastery': [
      // Chapter 0: What Is Pawn Structure?
      [
        LessonStep(
          fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
          highlights: ['a2','b2','c2','d2','e2','f2','g2','h2'],
          commentary: 'Pawns are the soul of chess! Unlike pieces, pawns can never go backwards. Their structure shapes the entire game — plans, piece placement, and endgame prospects.',
          concept: 'Pawn Soul',
        ),
        LessonStep(
          fen: 'r1bqkbnr/pp2pppp/2np4/8/3NP3/2N5/PPP2PPP/R1BQKB1R w KQkq - 0 5',
          highlights: ['d6', 'e4'],
          commentary: 'Every pawn move creates permanent changes. Here, Black\'s d6 pawn controls e5 but blocks the bishop. White\'s e4 pawn claims space but can become a target.',
          concept: 'Permanent Changes',
        ),
        LessonStep(
          fen: 'r1bqkb1r/pp3ppp/2nppn2/8/3NP3/2N1B3/PPP2PPP/R2QKB1R w KQkq - 0 7',
          arrows: [['e4', 'e5'], ['d6', 'd5']],
          commentary: 'Pawn breaks are how you change the structure. White might play e5, Black might play ...d5. Each break opens new possibilities and risks.',
          concept: 'Pawn Breaks',
        ),
      ],
      // Chapter 1: Isolated Queen's Pawn
      [
        LessonStep(
          fen: 'r1bqkb1r/pp3ppp/2n1pn2/8/3P4/2N2N2/PP3PPP/R1BQKB1R w KQkq - 0 7',
          highlights: ['d4'],
          commentary: 'The Isolated Queen\'s Pawn (IQP) — a d4 pawn with no neighboring pawns on c or e files. It can be both a strength and a weakness!',
          concept: 'IQP',
        ),
        LessonStep(
          fen: 'r1bqkb1r/pp3ppp/2n1pn2/8/3P4/2N2N2/PP3PPP/R1BQKB1R w KQkq - 0 7',
          arrows: [['d4', 'd5']],
          highlights: ['d4', 'd5'],
          commentary: 'Strength: The IQP can advance to d5 creating powerful attacks. It also gives White open lines and active piece play on both sides of the pawn.',
          concept: 'IQP Strength',
        ),
        LessonStep(
          fen: 'r2q1rk1/pp1b1ppp/2n1pn2/8/3P4/2N2N2/PP2BPPP/R1BQ1RK1 w - - 0 10',
          highlights: ['d4'],
          arrows: [['c6', 'd4'], ['f6', 'd5']],
          commentary: 'Weakness: In the endgame, the IQP becomes a static target. Black can blockade it on d5 with a knight and attack it with rooks.',
          concept: 'IQP Weakness',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // DISCOVERED ATTACKS
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'Discovered Attacks': [
      // Chapter 0: What Is a Discovered Attack?
      [
        LessonStep(
          fen: 'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
          highlights: ['f3'],
          arrows: [['f3', 'g5'], ['d1', 'h5']],
          commentary: 'A discovered attack happens when you move one piece out of the way, revealing an attack from another piece behind it. It\'s like a one-two punch!',
          concept: 'Discovered Attack',
        ),
        LessonStep(
          fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p1N1/2B1P3/8/PPPP1PPP/RNBQK2R b KQkq - 5 4',
          highlights: ['g5', 'c4', 'f7'],
          arrows: [['g5', 'f7'], ['c4', 'f7']],
          commentary: 'The knight on g5 and bishop on c4 both target f7! This double attack on the weakest point creates massive pressure.',
          concept: 'Double Attack',
        ),
        LessonStep(
          fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p1N1/2B1P3/8/PPPP1PPP/RNBQK2R b KQkq - 5 4',
          arrows: [['g5', 'e6'], ['c4', 'f7']],
          commentary: 'If the knight moves to e6 or captures on f7, it "discovers" attacks along the a2-g8 diagonal. The bishop was hiding behind the knight!',
          concept: 'Discovery Mechanism',
        ),
      ],
      // Chapter 1: Discovered Check
      [
        LessonStep(
          fen: 'rnb1k2r/ppppqppp/5n2/2b1N3/2B1P3/8/PPPP1PPP/RNBQK2R w KQkq - 4 5',
          highlights: ['e5', 'c4'],
          arrows: [['e5', 'f7']],
          commentary: 'A discovered check is a discovered attack where the revealed attack is a check. The king MUST deal with the check, so the moving piece gets a "free" move!',
          concept: 'Discovered Check',
        ),
        LessonStep(
          fen: 'rnb1k2r/ppppqppp/5n2/2b1N3/2B1P3/8/PPPP1PPP/RNBQK2R w KQkq - 4 5',
          arrows: [['e5', 'g6'], ['c4', 'e6']],
          commentary: 'If the knight moves away, the bishop gives check through the e-file. The knight can go anywhere — even to capture an undefended piece!',
          concept: 'Free Piece',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // KING & PAWN ENDINGS
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'King & Pawn Endings': [
      // Chapter 0: Opposition
      [
        LessonStep(
          fen: '8/8/4k3/8/4K3/8/4P3/8 w - - 0 1',
          highlights: ['e4', 'e6'],
          commentary: 'The Opposition — when kings face each other with one square between them. The side NOT to move has the opposition and controls the position.',
          concept: 'Opposition',
        ),
        LessonStep(
          fen: '8/8/4k3/8/4K3/8/4P3/8 w - - 0 1',
          arrows: [['e4', 'e5'], ['e6', 'e5']],
          commentary: 'White wants to advance the king, but with Black to move, White HAS the opposition. Black must step aside, and White can penetrate!',
          concept: 'Who Has Opposition?',
        ),
        LessonStep(
          fen: '8/8/3k4/8/4K3/8/4P3/8 w - - 0 2',
          move: 'e6d6',
          highlights: ['d6'],
          arrows: [['e4', 'e5']],
          commentary: 'Black steps aside — now White plays Ke5! The king advances and will escort the pawn to promotion.',
          concept: 'King Advance',
        ),
        LessonStep(
          fen: '8/8/3k4/4K3/8/8/4P3/8 b - - 1 2',
          move: 'e4e5',
          highlights: ['e5'],
          commentary: 'Ke5! The White king is in front of the pawn — this is winning. The key rule: the king must lead the pawn, not follow it!',
          concept: 'King Leads Pawn',
        ),
      ],
      // Chapter 1: Key Squares
      [
        LessonStep(
          fen: '8/8/8/8/4k3/8/4P3/4K3 w - - 0 1',
          highlights: ['d5', 'e5', 'f5'],
          commentary: 'Key squares are the squares in front of the pawn. If the king reaches any of them, the pawn promotes regardless of the opponent\'s play.',
          concept: 'Key Squares',
        ),
        LessonStep(
          fen: '8/8/8/8/4k3/8/4P3/4K3 w - - 0 1',
          highlights: ['d6', 'e6', 'f6'],
          arrows: [['e1', 'e2'], ['e2', 'd3']],
          commentary: 'For a pawn on e2, the key squares are d4/e4/f4 (two ranks ahead) and d6/e6/f6 (for guaranteed promotion). Get your king there!',
          concept: 'Two Rows of Keys',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MIDDLEGAME PLANNING
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'Middlegame Planning': [
      // Chapter 0: How to Make a Plan
      [
        LessonStep(
          fen: 'r1bq1rk1/ppp2ppp/2n1pn2/3p4/3P4/2N1PN2/PPP2PPP/R1BQKB1R w KQ - 0 6',
          commentary: 'A plan is a series of moves with a clear objective. Without a plan, you\'re just making random moves. Ask yourself: what does the position need?',
          concept: 'What Is a Plan?',
        ),
        LessonStep(
          fen: 'r1bq1rk1/ppp2ppp/2n1pn2/3p4/3P4/2N1PN2/PPP2PPP/R1BQKB1R w KQ - 0 6',
          arrows: [['f1', 'd3'], ['e1', 'g1']],
          commentary: 'Step 1: Evaluate the position. Who has more space? Where are the weaknesses? Which pieces are active or passive?',
          concept: 'Evaluation',
        ),
        LessonStep(
          fen: 'r1bq1rk1/ppp2ppp/2n1pn2/3p4/3P4/2N1PN2/PPP2PPP/R1BQKB1R w KQ - 0 6',
          highlights: ['d4', 'd5'],
          arrows: [['e3', 'e4']],
          commentary: 'Step 2: Identify the target. Here, the pawn tension on d4/d5 is key. White might plan e4 to challenge the center, or a kingside attack.',
          concept: 'Find the Target',
        ),
        LessonStep(
          fen: 'r1bq1rk1/ppp2ppp/2n1pn2/3p4/3P4/2N1PN2/PPP2PPP/R1BQKB1R w KQ - 0 6',
          arrows: [['f1', 'd3'], ['c1', 'd2'], ['a1', 'e1']],
          commentary: 'Step 3: Execute piece by piece. Bd3 develops toward the kingside, then Qe2, 0-0, and e4 — each move serves the plan!',
          concept: 'Execute the Plan',
        ),
      ],
      // Chapter 1: Evaluating the Position
      [
        LessonStep(
          fen: 'r2q1rk1/pp2bppp/2n1pn2/3p4/3P1B2/2NBPN2/PPP2PPP/R2QK2R w KQ - 4 8',
          commentary: 'Position evaluation uses several factors: material balance, king safety, pawn structure, piece activity, and space. Let\'s analyze each one.',
          concept: 'Evaluation Factors',
        ),
        LessonStep(
          fen: 'r2q1rk1/pp2bppp/2n1pn2/3p4/3P1B2/2NBPN2/PPP2PPP/R2QK2R w KQ - 4 8',
          highlights: ['f4', 'd3', 'f3', 'c3'],
          commentary: 'White\'s pieces are well developed: bishop on f4 is active, knight on c3 eyes d5, and the d3 bishop points at the kingside. Good coordination!',
          concept: 'Piece Activity',
        ),
        LessonStep(
          fen: 'r2q1rk1/pp2bppp/2n1pn2/3p4/3P1B2/2NBPN2/PPP2PPP/R2QK2R w KQ - 4 8',
          arrows: [['e1', 'g1'], ['d1', 'e2']],
          commentary: 'White should castle and then plan the central push e4. The position is slightly better for White due to more active pieces and better central control.',
          concept: 'Assessment',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // PIN & FORK TACTICS
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'Pin & Fork Tactics': [
      // Chapter 0: What Is a Pin?
      [
        LessonStep(
          fen: 'r1b1k2r/ppppqppp/2n2n2/4p1B1/1bB1P3/2NP1N2/PPP2PPP/R2QK2R b KQkq - 5 5',
          highlights: ['g5', 'f6'],
          arrows: [['g5', 'd8']],
          commentary: 'A pin immobilizes a piece because moving it would expose a more valuable piece behind it. Here Bg5 pins the knight on f6 to the queen on d8!',
          concept: 'The Pin',
        ),
        LessonStep(
          fen: 'r1b1k2r/ppppqppp/2n2n2/4p1B1/1bB1P3/2NP1N2/PPP2PPP/R2QK2R b KQkq - 5 5',
          highlights: ['f6'],
          commentary: 'The knight on f6 is pinned — it cannot move without losing the queen! This restricts Black\'s options and ties down the position.',
          concept: 'Pinned Piece',
        ),
        LessonStep(
          fen: 'r1b1k2r/ppppqppp/2n2n2/4p1B1/1bB1P3/2NP1N2/PPP2PPP/R2QK2R b KQkq - 5 5',
          arrows: [['b4', 'c3']],
          highlights: ['b4', 'c3'],
          commentary: 'Notice Black also has a pin! The bishop on b4 pins the knight on c3 to the king. Both sides use pins here — they\'re everywhere in chess!',
          concept: 'Counter-Pin',
        ),
      ],
      // Chapter 1: Absolute vs Relative Pins
      [
        LessonStep(
          fen: 'r1b1k2r/ppppqppp/2n2n2/4p1B1/1bB1P3/2NP1N2/PPP2PPP/R2QK2R b KQkq - 5 5',
          highlights: ['b4', 'c3'],
          arrows: [['b4', 'e1']],
          commentary: 'An ABSOLUTE pin targets the king. The knight on c3 literally cannot move — it would leave the king in check. This is the strongest type of pin.',
          concept: 'Absolute Pin',
        ),
        LessonStep(
          fen: 'r1b1k2r/ppppqppp/2n2n2/4p1B1/1bB1P3/2NP1N2/PPP2PPP/R2QK2R b KQkq - 5 5',
          highlights: ['g5', 'f6'],
          arrows: [['g5', 'd8']],
          commentary: 'A RELATIVE pin targets a valuable piece (here the queen). The knight CAN legally move, but doing so would lose material. It\'s pinned by economics, not rules!',
          concept: 'Relative Pin',
        ),
      ],
    ],

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // EXCHANGE SACRIFICE
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    'Exchange Sacrifice': [
      // Chapter 0: What Is an Exchange Sacrifice?
      [
        LessonStep(
          fen: 'r4rk1/pp2bppp/2n1pn2/3p4/3P1B2/2NBPN2/PPP2PPP/2KR3R w - - 0 11',
          commentary: 'An exchange sacrifice means giving up a rook for a minor piece (bishop or knight). In return, you get positional compensation — better pieces, structure, or attack.',
          concept: 'Exchange Sacrifice',
        ),
        LessonStep(
          fen: 'r4rk1/pp2bppp/2n1pn2/3p4/3P1B2/2NBPN2/PPP2PPP/2KR3R w - - 0 11',
          arrows: [['d1', 'c1'], ['d3', 'h7']],
          commentary: 'A rook is worth 5 points, a minor piece 3 points. So you\'re "giving up" 2 points of material. But positional advantages can outweigh material!',
          concept: 'Material vs Position',
        ),
        LessonStep(
          fen: 'r4rk1/pp2bppp/2n1pn2/3p4/3P1B2/2NBPN2/PPP2PPP/2KR3R w - - 0 11',
          highlights: ['d3', 'f4', 'f3'],
          commentary: 'When your minor pieces are very active and your opponent\'s rooks have no open files, the exchange sacrifice becomes attractive. Piece quality over quantity!',
          concept: 'Piece Quality',
        ),
      ],
      // Chapter 1: Positional Exchange Sac
      [
        LessonStep(
          fen: 'r2q1rk1/pp2bppp/2n1pn2/3pN3/3P1B2/2NBPP2/PPP3PP/R2Q1RK1 w - - 0 11',
          highlights: ['e5'],
          arrows: [['f1', 'c1']],
          commentary: 'Petrosian taught us: sometimes you sacrifice the exchange not for an attack, but to improve your pawn structure or eliminate a dangerous piece.',
          concept: 'Petrosian\'s Idea',
        ),
        LessonStep(
          fen: 'r2q1rk1/pp2bppp/2n1pn2/3pN3/3P1B2/2NBPP2/PPP3PP/R2Q1RK1 w - - 0 11',
          arrows: [['e5', 'c6']],
          commentary: 'If White plays Nxc6 and Black recaptures with the bishop, White could sacrifice Rxf6! to damage Black\'s pawn structure and gain a strong initiative.',
          concept: 'Structure Damage',
        ),
      ],
    ],
  };

  /// Generate fallback steps for lessons/chapters without bespoke content.
  static List<LessonStep> _generateFallbackSteps(String lessonTitle, int chapterIndex) {
    final titles = getChapterTitles(lessonTitle);
    final chapterTitle = chapterIndex < titles.length
        ? titles[chapterIndex]
        : 'Chapter ${chapterIndex + 1}';

    final positions = [
      'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
      'rnbqkb1r/pp2pppp/3p1n2/2p5/3PP3/5N2/PPP2PPP/RNBQKB1R w KQkq - 0 4',
      'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
      'rnbqkb1r/pppppppp/5n2/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 1 2',
      'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4',
    ];

    return [
      LessonStep(
        fen: positions[(chapterIndex) % positions.length],
        commentary: 'Welcome to "$chapterTitle". This chapter explores key concepts that will strengthen your understanding of this topic.',
        concept: chapterTitle,
      ),
      LessonStep(
        fen: positions[(chapterIndex + 1) % positions.length],
        highlights: ['e4', 'd5'],
        commentary: 'Pay attention to the center and pawn structure in this position. They dictate the plans for both sides.',
        concept: 'Position Analysis',
      ),
      LessonStep(
        fen: positions[(chapterIndex + 2) % positions.length],
        arrows: [['e2', 'e4'], ['d7', 'd5']],
        commentary: 'Consider the plans available to both sides. Look for weaknesses to exploit and strengths to leverage.',
        concept: 'Strategic Thinking',
      ),
      LessonStep(
        fen: positions[(chapterIndex + 3) % positions.length],
        commentary: 'Remember the key principles from this chapter. Apply them in your own games and watch your play improve!',
        concept: 'Key Takeaway',
      ),
    ];
  }
}
