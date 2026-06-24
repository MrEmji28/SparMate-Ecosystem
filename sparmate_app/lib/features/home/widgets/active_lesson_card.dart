import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../lessons/screens/lesson_detail_screen.dart';
import '../../lessons/screens/lessons_screen.dart';

/// Active lesson card — shows the user's current in-progress lesson
/// from the dashboard API. Shows an empty state if no lesson is active.
class ActiveLessonCard extends StatelessWidget {
  const ActiveLessonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();
    final dashboard = state.dashboardData;
    final activeLesson = dashboard?['active_lesson'] as Map<String, dynamic>?;

    // Determine what to display
    final hasLesson = activeLesson != null;
    final lessonTitle = activeLesson?['title'] as String? ?? 'No active lesson';
    final progressRaw = activeLesson?['progress'];
    final progress = (progressRaw is num) ? progressRaw.toDouble() / 100 : 0.0;
    final progressPct = (progress * 100).toInt();

    return GestureDetector(
      onTap: hasLesson
          ? () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LessonDetailScreen()),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon ──
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasLesson ? Icons.desktop_mac_rounded : Icons.school_outlined,
                size: 18,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),

            // ── Label ──
            Text(
              hasLesson ? 'ACTIVE LESSON' : 'GET STARTED',
              style: tt.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 6),

            // ── Lesson name + percentage ──
            if (hasLesson) ...[
              RichText(
                text: TextSpan(
                  style: tt.titleMedium?.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  children: [
                    TextSpan(text: '$lessonTitle  '),
                    TextSpan(
                      text: '$progressPct%',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Progress bar ──
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: AppColors.progressTrack,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.progressFill),
                ),
              ),
              const SizedBox(height: 14),

              // ── Resume button ──
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const LessonDetailScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('RESUME'),
                ),
              ),
            ] else ...[
              // ── Empty state ──
              Text(
                'No lessons in progress',
                style: tt.titleMedium?.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start a lesson to track your progress here.',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const LessonsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('BROWSE'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
