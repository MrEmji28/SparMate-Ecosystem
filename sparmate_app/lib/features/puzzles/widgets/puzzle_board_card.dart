import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Chess board display card with puzzle details, difficulty, and action buttons.
class PuzzleBoardCard extends StatelessWidget {
  const PuzzleBoardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // ── Chess board ──
          Container(
            width: double.infinity,
            height: 260,
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
            child: CustomPaint(painter: _ChessBoardPainter()),
          ),
          const SizedBox(height: 8),
          // "White to move" label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(
              'White to move',
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textMedium, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title + description ──
          Text(
            'Find the Best Move',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Evaluate the position carefully. Look for forcing moves, checks, captures, and threats.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: AppColors.textMedium, height: 1.5),
          ),
          const SizedBox(height: 20),

          // ── Difficulty + Rating row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoColumn(context, 'Difficulty', 'Intermediate'),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 28),
                color: AppColors.divider,
              ),
              _infoColumn(context, 'Rating', '1650'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Theme ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Theme', style: tt.bodySmall?.copyWith(color: AppColors.textLight)),
              const SizedBox(width: 8),
              Text(
                'Pin & Skewer',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── Action buttons ──
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.lightbulb_rounded, size: 18),
              label: const Text('Get Hint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryNavy,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('View Solution'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(BuildContext context, String label, String value) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}

/// Draws a full 8×8 chess board with piece representations.
class _ChessBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sq = size.width / 8;
    final boardH = sq * 8;
    final yOffset = (size.height - boardH) / 2;

    final light = Paint()..color = const Color(0xFFF0D9B5);
    final dark = Paint()..color = const Color(0xFFB58863);

    // Draw board
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        canvas.drawRect(
          Rect.fromLTWH(c * sq, yOffset + r * sq, sq, sq),
          (r + c) % 2 == 0 ? light : dark,
        );
      }
    }

    // Draw piece representations (circles with letters)
    // Black pieces (top rows)
    _drawPiece(canvas, 0, 0, sq, yOffset, '♜', false);
    _drawPiece(canvas, 0, 1, sq, yOffset, '♞', false);
    _drawPiece(canvas, 0, 2, sq, yOffset, '♝', false);
    _drawPiece(canvas, 0, 3, sq, yOffset, '♛', false);
    _drawPiece(canvas, 0, 4, sq, yOffset, '♚', false);
    _drawPiece(canvas, 0, 5, sq, yOffset, '♝', false);
    _drawPiece(canvas, 0, 7, sq, yOffset, '♜', false);
    // Black pawns
    for (var c in [0, 1, 2, 5, 6, 7]) {
      _drawPiece(canvas, 1, c, sq, yOffset, '♟', false);
    }
    // Advanced black pawns
    _drawPiece(canvas, 3, 3, sq, yOffset, '♟', false);
    _drawPiece(canvas, 2, 4, sq, yOffset, '♞', false);

    // White pieces (bottom rows)
    _drawPiece(canvas, 7, 0, sq, yOffset, '♖', true);
    _drawPiece(canvas, 7, 1, sq, yOffset, '♘', true);
    _drawPiece(canvas, 7, 2, sq, yOffset, '♗', true);
    _drawPiece(canvas, 7, 3, sq, yOffset, '♕', true);
    _drawPiece(canvas, 7, 4, sq, yOffset, '♔', true);
    _drawPiece(canvas, 7, 5, sq, yOffset, '♗', true);
    _drawPiece(canvas, 7, 7, sq, yOffset, '♖', true);
    // White pawns
    for (var c in [0, 1, 5, 6, 7]) {
      _drawPiece(canvas, 6, c, sq, yOffset, '♙', true);
    }
    // Advanced white pawns
    _drawPiece(canvas, 4, 3, sq, yOffset, '♙', true);
    _drawPiece(canvas, 5, 2, sq, yOffset, '♘', true);
  }

  void _drawPiece(Canvas canvas, int row, int col, double sq, double yOffset, String piece, bool isWhite) {
    final tp = TextPainter(
      text: TextSpan(
        text: piece,
        style: TextStyle(
          fontSize: sq * 0.7,
          color: isWhite ? Colors.white : const Color(0xFF2D2D2D),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        col * sq + (sq - tp.width) / 2,
        yOffset + row * sq + (sq - tp.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
