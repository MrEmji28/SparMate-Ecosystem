import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Current chapter content preview showing theory and key concepts.
class LessonContentCard extends StatelessWidget {
  const LessonContentCard({super.key});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Current Chapter', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chapter 8: Pawn Structures & Plans',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // ── Key concepts ──
          Text(
            'KEY CONCEPTS',
            style: tt.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          _concept(context, Icons.grid_on_rounded, 'Maroczy Bind',
              'Control the center with pawns on c4 and e4 to restrict Black\'s counterplay.'),
          const SizedBox(height: 10),
          _concept(context, Icons.swap_vert_rounded, 'Hedgehog Formation',
              'Flexible pawn structure allowing dynamic piece play from the first three ranks.'),
          const SizedBox(height: 10),
          _concept(context, Icons.security_rounded, 'Isolated d-pawn',
              'Understanding when the isolated pawn is a strength vs. weakness.'),
          const SizedBox(height: 20),

          // ── Mini board preview ──
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(painter: _MiniPositionPainter()),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Maroczy Bind: White controls d5',
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
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Continue Lesson'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _concept(BuildContext context, IconData icon, String title, String desc) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: tt.bodySmall?.copyWith(color: AppColors.textMedium, height: 1.4, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Draws a simplified chess position showing the Maroczy Bind.
class _MiniPositionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sq = size.width / 8;
    final boardH = sq * 8;
    final yOff = (size.height - boardH) / 2;

    final light = Paint()..color = const Color(0xFFF0D9B5);
    final dark = Paint()..color = const Color(0xFFB58863);

    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        canvas.drawRect(Rect.fromLTWH(c * sq, yOff + r * sq, sq, sq), (r + c) % 2 == 0 ? light : dark);
      }
    }

    // Highlight controlled squares
    final highlight = Paint()..color = AppColors.primaryBlue.withValues(alpha: 0.2);
    canvas.drawRect(Rect.fromLTWH(3 * sq, yOff + 3 * sq, sq, sq), highlight); // d5

    // White pawns (Maroczy Bind: c4, e4)
    _p(canvas, 4, 2, sq, yOff, '♙', true);  // c4
    _p(canvas, 4, 4, sq, yOff, '♙', true);  // e4
    _p(canvas, 6, 0, sq, yOff, '♙', true);
    _p(canvas, 6, 1, sq, yOff, '♙', true);
    _p(canvas, 6, 5, sq, yOff, '♙', true);
    _p(canvas, 6, 6, sq, yOff, '♙', true);
    _p(canvas, 6, 7, sq, yOff, '♙', true);
    // White pieces
    _p(canvas, 7, 4, sq, yOff, '♔', true);
    _p(canvas, 5, 2, sq, yOff, '♘', true);
    _p(canvas, 5, 5, sq, yOff, '♗', true);

    // Black pawns
    _p(canvas, 1, 0, sq, yOff, '♟', false);
    _p(canvas, 1, 1, sq, yOff, '♟', false);
    _p(canvas, 2, 3, sq, yOff, '♟', false);  // d6
    _p(canvas, 1, 4, sq, yOff, '♟', false);
    _p(canvas, 1, 5, sq, yOff, '♟', false);
    _p(canvas, 1, 6, sq, yOff, '♟', false);
    _p(canvas, 1, 7, sq, yOff, '♟', false);
    // Black pieces
    _p(canvas, 0, 4, sq, yOff, '♚', false);
    _p(canvas, 2, 5, sq, yOff, '♞', false);
  }

  void _p(Canvas canvas, int r, int c, double sq, double yOff, String piece, bool white) {
    final tp = TextPainter(
      text: TextSpan(
        text: piece,
        style: TextStyle(
          fontSize: sq * 0.7,
          color: white ? Colors.white : const Color(0xFF2D2D2D),
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 1.5, offset: const Offset(0.5, 0.5))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c * sq + (sq - tp.width) / 2, yOff + r * sq + (sq - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
