import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../puzzles/screens/puzzles_screen.dart';

class TacticsCard extends StatelessWidget {
  const TacticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Mini chess board
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(painter: _MiniBoardPainter()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TACTICS', style: tt.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                const SizedBox(height: 2),
                Text('#482', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Intermediate Challenge', style: tt.bodySmall?.copyWith(color: AppColors.textLight)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 18, color: AppColors.starFilled),
                    const Icon(Icons.star_rounded, size: 18, color: AppColors.starFilled),
                    const Icon(Icons.star_rounded, size: 18, color: AppColors.starEmpty),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38, width: 80,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PuzzlesScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SOLVE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sq = size.width / 4;
    final light = Paint()..color = const Color(0xFFE8E0D4);
    final dark = Paint()..color = const Color(0xFF8B7D6B);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        canvas.drawRect(Rect.fromLTWH(c * sq, r * sq, sq, sq), (r + c) % 2 == 0 ? light : dark);
      }
    }
    // Draw a knight icon hint
    final knightPaint = Paint()..color = const Color(0xFF3D3D3D).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(sq * 2.5, sq * 1.5), sq * 0.35, knightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
