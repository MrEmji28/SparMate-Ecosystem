import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Daily Goal card with dynamic progress indicator and streak.
class DailyGoalCard extends StatelessWidget {
  final int solved;
  final int dailyGoal;
  final int streakDays;

  const DailyGoalCard({
    super.key,
    this.solved = 0,
    this.dailyGoal = 5,
    this.streakDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final progress = dailyGoal > 0 ? (solved / dailyGoal).clamp(0.0, 1.0) : 0.0;
    final isComplete = solved >= dailyGoal;

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
                    Row(
                      children: [
                        Text('Daily Goal',
                            style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        if (isComplete) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Complete!',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.successGreen)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isComplete
                          ? 'Great job! You hit your daily goal. 🎉'
                          : 'Solve $dailyGoal puzzles to maintain your edge.',
                      style: tt.bodySmall
                          ?.copyWith(color: AppColors.textLight, fontSize: 12),
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
                  painter: _CircularPainter(
                    progress: progress,
                    isComplete: isComplete,
                  ),
                  child: Center(
                    child: Text(
                      '$solved/$dailyGoal',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isComplete
                            ? AppColors.successGreen
                            : AppColors.primaryBlue,
                      ),
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
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.progressTrack,
              valueColor: AlwaysStoppedAnimation(
                  isComplete ? AppColors.successGreen : AppColors.progressFill),
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
                      style: tt.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$streakDays ${streakDays == 1 ? 'Day' : 'Days'}',
                      style: tt.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                          color: AppColors.textDark),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.local_fire_department_rounded,
                    size: 36,
                    color: streakDays > 0
                        ? Colors.orange.shade600
                        : AppColors.textLight),
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
  final bool isComplete;
  _CircularPainter({required this.progress, this.isComplete = false});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 3;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = AppColors.progressTrack
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = isComplete ? AppColors.successGreen : AppColors.primaryBlue
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _CircularPainter old) =>
      old.progress != progress || old.isComplete != isComplete;
}
