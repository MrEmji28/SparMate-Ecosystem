import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

/// Current chapter content preview showing theory and key concepts.
/// Accepts dynamic data and a functional continue callback.
/// Uses Lichess-style board with SVG pieces.
class LessonContentCard extends StatelessWidget {
  final String title;
  final int chapterIndex;
  final int totalChapters;
  final Color color;
  final VoidCallback? onContinue;

  const LessonContentCard({
    super.key,
    this.title = 'Sicilian Defense',
    this.chapterIndex = 7,
    this.totalChapters = 12,
    this.color = const Color(0xFF3949AB),
    this.onContinue,
  });

  static const _chapterTitles = [
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

  // Key concepts vary by chapter index to feel dynamic
  static const _conceptSets = [
    [
      _ConceptData(Icons.school_rounded, 'Fundamentals',
          'Learn the basic ideas and setup positions for this opening system.'),
      _ConceptData(Icons.timeline_rounded, 'Historical Context',
          'Understand how this opening evolved through chess history.'),
    ],
    [
      _ConceptData(Icons.grid_on_rounded, 'Center Control',
          'Control the central squares to maximize piece activity and mobility.'),
      _ConceptData(Icons.swap_vert_rounded, 'Piece Development',
          'Develop minor pieces actively and castle early for king safety.'),
    ],
    [
      _ConceptData(Icons.account_tree_rounded, 'Main Lines',
          'Study the most popular and theoretically important variations.'),
      _ConceptData(Icons.alt_route_rounded, 'Sidelines',
          'Explore lesser-known but dangerous surprise weapons.'),
    ],
    [
      _ConceptData(Icons.bolt_rounded, 'Tactical Motifs',
          'Recognize pins, forks, and discovered attacks in typical positions.'),
      _ConceptData(Icons.visibility_rounded, 'Pattern Recognition',
          'Train your eye to spot recurring tactical themes quickly.'),
    ],
    [
      _ConceptData(Icons.psychology_rounded, 'Strategic Thinking',
          'Develop long-term plans based on pawn structure and piece placement.'),
      _ConceptData(Icons.dashboard_rounded, 'Piece Placement',
          'Learn optimal squares for your pieces in different pawn structures.'),
    ],
    [
      _ConceptData(Icons.route_rounded, 'Planning',
          'Create concrete plans based on the specific features of the position.'),
      _ConceptData(Icons.compare_arrows_rounded, 'Pawn Breaks',
          'Identify and execute the correct pawn breaks at the right moment.'),
    ],
    [
      _ConceptData(Icons.warning_rounded, 'Common Errors',
          'Avoid the most frequent mistakes players make in this system.'),
      _ConceptData(Icons.shield_rounded, 'Defensive Ideas',
          'Learn key defensive resources when under attack.'),
    ],
    [
      _ConceptData(Icons.grid_on_rounded, 'Maroczy Bind',
          'Control the center with pawns on c4 and e4 to restrict counterplay.'),
      _ConceptData(Icons.swap_vert_rounded, 'Hedgehog Formation',
          'Flexible pawn structure allowing dynamic piece play from the first three ranks.'),
      _ConceptData(Icons.security_rounded, 'Isolated d-pawn',
          'Understanding when the isolated pawn is a strength vs. weakness.'),
    ],
  ];

  // Pre-defined positions for different chapter types
  // Each position: list of (row, col, pieceCode) where pieceCode e.g. 'wP', 'bK'
  static const _positions = [
    // Position 0: Starting position (for intro chapters)
    [
      [0, 0, 'bR'], [0, 1, 'bN'], [0, 2, 'bB'], [0, 3, 'bQ'],
      [0, 4, 'bK'], [0, 5, 'bB'], [0, 6, 'bN'], [0, 7, 'bR'],
      [1, 0, 'bP'], [1, 1, 'bP'], [1, 2, 'bP'], [1, 3, 'bP'],
      [1, 4, 'bP'], [1, 5, 'bP'], [1, 6, 'bP'], [1, 7, 'bP'],
      [6, 0, 'wP'], [6, 1, 'wP'], [6, 2, 'wP'], [6, 3, 'wP'],
      [6, 4, 'wP'], [6, 5, 'wP'], [6, 6, 'wP'], [6, 7, 'wP'],
      [7, 0, 'wR'], [7, 1, 'wN'], [7, 2, 'wB'], [7, 3, 'wQ'],
      [7, 4, 'wK'], [7, 5, 'wB'], [7, 6, 'wN'], [7, 7, 'wR'],
    ],
    // Position 1: Sicilian 1.e4 c5
    [
      [0, 0, 'bR'], [0, 1, 'bN'], [0, 2, 'bB'], [0, 3, 'bQ'],
      [0, 4, 'bK'], [0, 5, 'bB'], [0, 6, 'bN'], [0, 7, 'bR'],
      [1, 0, 'bP'], [1, 1, 'bP'], [1, 3, 'bP'],
      [1, 4, 'bP'], [1, 5, 'bP'], [1, 6, 'bP'], [1, 7, 'bP'],
      [3, 2, 'bP'],
      [4, 4, 'wP'],
      [6, 0, 'wP'], [6, 1, 'wP'], [6, 2, 'wP'], [6, 3, 'wP'],
      [6, 5, 'wP'], [6, 6, 'wP'], [6, 7, 'wP'],
      [7, 0, 'wR'], [7, 1, 'wN'], [7, 2, 'wB'], [7, 3, 'wQ'],
      [7, 4, 'wK'], [7, 5, 'wB'], [7, 6, 'wN'], [7, 7, 'wR'],
    ],
    // Position 2: Maroczy Bind
    [
      [0, 4, 'bK'], [2, 3, 'bP'], [2, 5, 'bN'],
      [1, 0, 'bP'], [1, 1, 'bP'], [1, 4, 'bP'],
      [1, 5, 'bP'], [1, 6, 'bP'], [1, 7, 'bP'],
      [4, 2, 'wP'], [4, 4, 'wP'],
      [5, 2, 'wN'], [5, 5, 'wB'],
      [6, 0, 'wP'], [6, 1, 'wP'], [6, 5, 'wP'], [6, 6, 'wP'], [6, 7, 'wP'],
      [7, 4, 'wK'],
    ],
    // Position 3: Knight outpost
    [
      [0, 4, 'bK'], [0, 7, 'bR'],
      [1, 5, 'bP'], [1, 6, 'bP'], [1, 7, 'bP'],
      [2, 1, 'bB'], [2, 3, 'bP'],
      [3, 4, 'wN'], // Knight on outpost e5
      [4, 3, 'wP'],
      [6, 4, 'wP'], [6, 5, 'wP'], [6, 6, 'wP'], [6, 7, 'wP'],
      [7, 4, 'wK'], [7, 7, 'wR'],
    ],
  ];

  // Highlighted squares per position (e.g. key control squares)
  static const _highlights = [
    <List<int>>[], // No highlights for starting pos
    [[3, 2]], // c5 highlighted
    [[3, 3]], // d5 control highlighted
    [[3, 4]], // e5 outpost highlighted
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final chapterTitle = chapterIndex < _chapterTitles.length
        ? _chapterTitles[chapterIndex]
        : 'Chapter ${chapterIndex + 1}';
    final concepts = chapterIndex < _conceptSets.length
        ? _conceptSets[chapterIndex]
        : _conceptSets[chapterIndex % _conceptSets.length];

    final posIdx = chapterIndex % _positions.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 20, color: color),
              const SizedBox(width: 8),
              Text('Up Next',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chapter ${chapterIndex + 1}: $chapterTitle',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // ── Key concepts ──
          Text(
            'KEY CONCEPTS',
            style: tt.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < concepts.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _buildConcept(context, concepts[i]),
          ],
          const SizedBox(height: 20),

          // ── Lichess-style mini board ──
          LayoutBuilder(builder: (context, constraints) {
            final boardSize = constraints.maxWidth;
            final sqSize = boardSize / 8;
            final position = _positions[posIdx];
            final highlights =
                posIdx < _highlights.length ? _highlights[posIdx] : <List<int>>[];

            return Container(
              width: boardSize,
              height: boardSize * 0.55, // Show ~4.5 rows
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Board squares
                  for (var r = 0; r < 8; r++)
                    for (var c = 0; c < 8; c++)
                      _buildSquare(r, c, sqSize, highlights),

                  // Pieces
                  for (final p in position)
                    Positioned(
                      left: (p[1] as int) * sqSize,
                      top: (p[0] as int) * sqSize,
                      width: sqSize,
                      height: sqSize,
                      child: Padding(
                        padding: EdgeInsets.all(sqSize * 0.08),
                        child: SvgPicture.asset(
                          'assets/pieces/${p[2]}.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                  // Rank labels (Lichess-style, on right edge)
                  for (var r = 0; r < 8; r++)
                    Positioned(
                      top: r * sqSize + 2,
                      right: 3,
                      child: Text(
                        '${8 - r}',
                        style: TextStyle(
                          fontSize: sqSize * 0.2,
                          fontWeight: FontWeight.w700,
                          color: (r + 7) % 2 == 0
                              ? const Color(0xFFB48764)
                              : const Color(0xFFEDD6B0),
                        ),
                      ),
                    ),

                  // File labels (Lichess-style, on bottom edge)
                  for (var c = 0; c < 8; c++)
                    Positioned(
                      bottom: 2,
                      left: c * sqSize + 3,
                      child: Text(
                        String.fromCharCode('a'.codeUnitAt(0) + c),
                        style: TextStyle(
                          fontSize: sqSize * 0.2,
                          fontWeight: FontWeight.w700,
                          color: (7 + c) % 2 == 0
                              ? const Color(0xFFB48764)
                              : const Color(0xFFEDD6B0),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: Text(
              chapterIndex < 8
                  ? 'Position from $chapterTitle'
                  : 'Key position to study',
              style: tt.bodySmall?.copyWith(
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Continue button ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Continue Lesson'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquare(
      int row, int col, double sqSize, List<List<int>> highlights) {
    final isLight = (row + col) % 2 == 0;
    final isHighlighted =
        highlights.any((h) => h[0] == row && h[1] == col);

    // Lichess brown theme
    const lightSquare = Color(0xFFEDD6B0);
    const darkSquare = Color(0xFFB48764);
    const highlightLight = Color(0xFFC8D88B);
    const highlightDark = Color(0xFF9AAD5B);

    final bgColor = isHighlighted
        ? (isLight ? highlightLight : highlightDark)
        : (isLight ? lightSquare : darkSquare);

    return Positioned(
      left: col * sqSize,
      top: row * sqSize,
      width: sqSize,
      height: sqSize,
      child: Container(color: bgColor),
    );
  }

  Widget _buildConcept(BuildContext context, _ConceptData concept) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(concept.icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(concept.title,
                  style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontSize: 13)),
              const SizedBox(height: 2),
              Text(concept.description,
                  style: tt.bodySmall?.copyWith(
                      color: AppColors.textMedium,
                      height: 1.4,
                      fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConceptData {
  final IconData icon;
  final String title;
  final String description;
  const _ConceptData(this.icon, this.title, this.description);
}
