import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Daily Goal card with progress indicator and current streak.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key});

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
          // ── Goal row ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Goal', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'Solve 5 puzzles to maintain your edge.',
                      style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Circular progress
              SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: _CircularPainter(progress: 2 / 5),
                  child: Center(
                    child: Text(
                      '2/5',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.4,
              minHeight: 6,
              backgroundColor: AppColors.progressTrack,
              valueColor: AlwaysStoppedAnimation(AppColors.progressFill),
            ),
          ),
          const SizedBox(height: 20),

          // ── Current Streak ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryNavy.withValues(alpha: 0.06),
                  AppColors.primaryBlue.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT STREAK',
                      style: tt.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '12 Days',
                      style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 28, color: AppColors.textDark),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.local_fire_department_rounded, size: 36, color: Colors.orange.shade600),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularPainter extends CustomPainter {
  final double progress;
  _CircularPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    canvas.drawCircle(c, r, Paint()..color = AppColors.progressTrack..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * progress, false, Paint()..color = AppColors.primaryBlue..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _CircularPainter old) => old.progress != progress;
}
