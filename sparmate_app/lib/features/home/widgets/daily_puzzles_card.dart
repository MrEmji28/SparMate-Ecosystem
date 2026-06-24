import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../puzzles/screens/puzzles_screen.dart';

/// Daily puzzles card — shows real puzzle attempt count from dashboard data.
class DailyPuzzlesCard extends StatelessWidget {
  const DailyPuzzlesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();
    final dashboard = state.dashboardData;
    final puzzleData = dashboard?['daily_puzzles'] as Map<String, dynamic>?;

    final solved = (puzzleData?['solved'] as num?)?.toInt() ?? 0;
    final goal = (puzzleData?['goal'] as num?)?.toInt() ?? 5;
    final progress = goal > 0 ? (solved / goal).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PuzzlesScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.extension_rounded, size: 22, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Puzzles', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    solved >= goal
                        ? 'Goal reached! Great work 🎉'
                        : 'Solve $goal to reach your goal',
                    style: tt.bodySmall?.copyWith(color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 52, height: 52,
              child: CustomPaint(
                painter: _CircularPainter(progress: progress),
                child: Center(
                  child: Text(
                    '$solved/$goal',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: solved >= goal ? AppColors.successGreen : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
