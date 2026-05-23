import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/grandmaster.dart';

/// Interactive chess board card with game controls for sparring.
class GameBoardCard extends StatelessWidget {
  final Grandmaster gm;
  const GameBoardCard({super.key, required this.gm});

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
          // ── Opponent label ──
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gm.color.withValues(alpha: 0.12),
                ),
                child: Icon(gm.icon, size: 14, color: gm.color),
              ),
              const SizedBox(width: 8),
              Text('${gm.title} ${gm.fullName}', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Online', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.successGreen)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Chess board ──
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(painter: _GameBoardPainter()),
          ),
          const SizedBox(height: 10),

          // ── Your turn label ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: AppColors.textMedium, width: 1.5))),
                const SizedBox(width: 6),
                Text('Your turn — White to move', style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textMedium, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Player label ──
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryLight]),
                ),
                child: const Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text('You', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13)),
              const Spacer(),
              Text('15:00', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 18),

          // ── Game controls ──
          Row(
            children: [
              Expanded(
                child: _controlBtn(Icons.flag_rounded, 'Resign', AppColors.liveRed),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _controlBtn(Icons.handshake_rounded, 'Draw', AppColors.textMedium),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _controlBtn(Icons.lightbulb_rounded, 'Hint', AppColors.successGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, String label, Color color) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _GameBoardPainter extends CustomPainter {
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

    // Starting position pieces
    const blackBack = ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'];
    const whiteBack = ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'];
    for (var c = 0; c < 8; c++) {
      _p(canvas, 0, c, sq, yOff, blackBack[c], false);
      _p(canvas, 1, c, sq, yOff, '♟', false);
      _p(canvas, 6, c, sq, yOff, '♙', true);
      _p(canvas, 7, c, sq, yOff, whiteBack[c], true);
    }
  }

  void _p(Canvas canvas, int r, int c, double sq, double yOff, String piece, bool white) {
    final tp = TextPainter(
      text: TextSpan(
        text: piece,
        style: TextStyle(
          fontSize: sq * 0.72,
          color: white ? Colors.white : const Color(0xFF2D2D2D),
          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2, offset: const Offset(1, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c * sq + (sq - tp.width) / 2, yOff + r * sq + (sq - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
