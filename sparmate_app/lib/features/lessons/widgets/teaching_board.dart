import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/lesson_step.dart';

/// Interactive teaching chess board for lesson demonstrations.
///
/// Features:
/// - Full 8×8 board with SVG pieces
/// - Animated piece movement when steps change
/// - Highlighted squares with colored overlays
/// - Arrow annotations showing recommended moves
/// - Board coordinates (a–h, 1–8) in Lichess style
class TeachingBoard extends StatefulWidget {
  final LessonStep step;
  final LessonStep? previousStep;
  final Color accentColor;

  const TeachingBoard({
    super.key,
    required this.step,
    this.previousStep,
    this.accentColor = const Color(0xFF3949AB),
  });

  @override
  State<TeachingBoard> createState() => _TeachingBoardState();
}

class _TeachingBoardState extends State<TeachingBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _moveAnim;
  late Animation<Offset> _slideAnimation;

  // Move animation state
  String? _animatingPiece; // e.g. 'wP'
  int? _toRow, _toCol;
  bool _animating = false;

  // Parsed board state (8x8 grid, null = empty)
  List<List<String?>> _board = List.generate(8, (_) => List.filled(8, null));

  @override
  void initState() {
    super.initState();
    _moveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _moveAnim, curve: Curves.easeInOutCubic));

    _parseFen(widget.step.fen);
    _tryAnimate();
  }

  @override
  void didUpdateWidget(TeachingBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _parseFen(widget.step.fen);
      _tryAnimate();
    }
  }

  @override
  void dispose() {
    _moveAnim.dispose();
    super.dispose();
  }

  /// Parse a FEN string into the 8x8 board grid.
  void _parseFen(String fen) {
    final rows = fen.split(' ')[0].split('/');
    final newBoard = List.generate(8, (_) => List<String?>.filled(8, null));

    for (var r = 0; r < 8 && r < rows.length; r++) {
      var c = 0;
      for (final ch in rows[r].split('')) {
        if (c >= 8) break;
        final digit = int.tryParse(ch);
        if (digit != null) {
          c += digit;
        } else {
          // Map FEN char to piece code (e.g. 'P' -> 'wP', 'p' -> 'bP')
          final color = ch == ch.toUpperCase() ? 'w' : 'b';
          final piece = ch.toUpperCase();
          newBoard[r][c] = '$color$piece';
          c++;
        }
      }
    }
    _board = newBoard;
  }

  /// Attempt to animate a move if the current step has one.
  void _tryAnimate() {
    final move = widget.step.move;
    if (move == null || move.length < 4) {
      _animating = false;
      _moveAnim.reset();
      return;
    }

    // Parse move like 'e2e4' -> (6,4) -> (4,4)

    final fromCol = move.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = 8 - int.parse(move[1]);
    final toCol = move.codeUnitAt(2) - 'a'.codeUnitAt(0);
    final toRow = 8 - int.parse(move[3]);

    // The piece is already at the destination in the FEN.
    // For animation, we show it moving FROM source TO destination.
    _animatingPiece = _board[toRow][toCol];
    _toRow = toRow;
    _toCol = toCol;

    if (_animatingPiece != null) {
      _animating = true;
      _slideAnimation = Tween<Offset>(
        begin: Offset(
          (fromCol - toCol).toDouble(),
          (fromRow - toRow).toDouble(),
        ),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _moveAnim, curve: Curves.easeInOutCubic),
      );
      _moveAnim.reset();
      _moveAnim.forward().then((_) {
        if (mounted) {
          setState(() => _animating = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final boardSize = constraints.maxWidth;
      final sqSize = boardSize / 8;

      return Container(
        width: boardSize,
        height: boardSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // ── Board squares ──
            for (var r = 0; r < 8; r++)
              for (var c = 0; c < 8; c++)
                _buildSquare(r, c, sqSize),

            // ── Highlighted squares ──
            for (final sq in widget.step.highlights)
              _buildHighlight(sq, sqSize),

            // ── Arrow annotations ──
            if (widget.step.arrows.isNotEmpty)
              CustomPaint(
                size: Size(boardSize, boardSize),
                painter: _ArrowPainter(
                  arrows: widget.step.arrows,
                  sqSize: sqSize,
                  color: widget.accentColor.withValues(alpha: 0.6),
                ),
              ),

            // ── Pieces ──
            for (var r = 0; r < 8; r++)
              for (var c = 0; c < 8; c++)
                if (_board[r][c] != null)
                  _buildPiece(r, c, sqSize, _board[r][c]!),

            // ── Rank labels ──
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

            // ── File labels ──
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
    });
  }

  Widget _buildSquare(int row, int col, double sqSize) {
    final isLight = (row + col) % 2 == 0;
    const lightSquare = Color(0xFFEDD6B0);
    const darkSquare = Color(0xFFB48764);

    return Positioned(
      left: col * sqSize,
      top: row * sqSize,
      width: sqSize,
      height: sqSize,
      child: Container(color: isLight ? lightSquare : darkSquare),
    );
  }

  Widget _buildHighlight(String square, double sqSize) {
    if (square.length < 2) return const SizedBox.shrink();
    final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(square[1]);
    if (row < 0 || row > 7 || col < 0 || col > 7) return const SizedBox.shrink();

    return Positioned(
      left: col * sqSize,
      top: row * sqSize,
      width: sqSize,
      height: sqSize,
      child: Container(
        decoration: BoxDecoration(
          color: widget.accentColor.withValues(alpha: 0.3),
          border: Border.all(
            color: widget.accentColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildPiece(int row, int col, double sqSize, String piece) {
    final isAnimatingThis =
        _animating && row == _toRow && col == _toCol && piece == _animatingPiece;

    Widget pieceWidget = Padding(
      padding: EdgeInsets.all(sqSize * 0.06),
      child: SvgPicture.asset(
        'assets/pieces/$piece.svg',
        fit: BoxFit.contain,
      ),
    );

    if (isAnimatingThis) {
      return Positioned(
        left: col * sqSize,
        top: row * sqSize,
        width: sqSize,
        height: sqSize,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _slideAnimation.value.dx * sqSize,
                _slideAnimation.value.dy * sqSize,
              ),
              child: child,
            );
          },
          child: pieceWidget,
        ),
      );
    }

    return Positioned(
      left: col * sqSize,
      top: row * sqSize,
      width: sqSize,
      height: sqSize,
      child: pieceWidget,
    );
  }
}

/// Paints arrow annotations on the board.
class _ArrowPainter extends CustomPainter {
  final List<List<String>> arrows;
  final double sqSize;
  final Color color;

  _ArrowPainter({
    required this.arrows,
    required this.sqSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = sqSize * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final arrow in arrows) {
      if (arrow.length < 2 || arrow[0].length < 2 || arrow[1].length < 2) continue;

      final fromCol = arrow[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
      final fromRow = 8 - int.parse(arrow[0][1]);
      final toCol = arrow[1].codeUnitAt(0) - 'a'.codeUnitAt(0);
      final toRow = 8 - int.parse(arrow[1][1]);

      final from = Offset(
        (fromCol + 0.5) * sqSize,
        (fromRow + 0.5) * sqSize,
      );
      final to = Offset(
        (toCol + 0.5) * sqSize,
        (toRow + 0.5) * sqSize,
      );

      // Draw line
      canvas.drawLine(from, to, paint);

      // Draw arrowhead
      final angle = atan2(to.dy - from.dy, to.dx - from.dx);
      final headLen = sqSize * 0.25;
      final p1 = Offset(
        to.dx - headLen * cos(angle - 0.5),
        to.dy - headLen * sin(angle - 0.5),
      );
      final p2 = Offset(
        to.dx - headLen * cos(angle + 0.5),
        to.dy - headLen * sin(angle + 0.5),
      );

      final headPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(path, headPaint);
    }
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      arrows != oldDelegate.arrows || sqSize != oldDelegate.sqSize;
}
