import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Chapter list card with tappable chapter rows and completion tracking.
/// Accepts dynamic chapter count, completed set, and tap callback.
class ChapterListCard extends StatelessWidget {
  final int totalChapters;
  final Set<int> completedChapters;
  final Color color;
  final void Function(int index) onChapterTap;

  const ChapterListCard({
    super.key,
    this.totalChapters = 12,
    this.completedChapters = const {},
    this.color = const Color(0xFF3949AB),
    required this.onChapterTap,
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

  static const _durations = [
    '5 min', '8 min', '10 min', '8 min', '7 min', '9 min',
    '6 min', '10 min', '12 min', '8 min', '7 min', '15 min',
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final completed = completedChapters.length;

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
              Icon(Icons.list_rounded, size: 20, color: color),
              const SizedBox(width: 8),
              Text('Chapters',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completed/$totalChapters',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: totalChapters > 0
                  ? completed / totalChapters
                  : 0,
              minHeight: 4,
              backgroundColor: AppColors.progressTrack,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 16),

          // ── Chapter rows ──
          for (var i = 0; i < totalChapters; i++)
            _buildChapterRow(context, i),
        ],
      ),
    );
  }

  Widget _buildChapterRow(BuildContext context, int index) {
    final tt = Theme.of(context).textTheme;
    final isDone = completedChapters.contains(index);

    // Current = first incomplete chapter
    final isCurrent = !isDone &&
        (index == 0 || completedChapters.contains(index - 1));

    // Locked = not done and not current
    final isLocked = !isDone && !isCurrent;

    final title = index < _chapterTitles.length
        ? _chapterTitles[index]
        : 'Chapter ${index + 1}';
    final duration = index < _durations.length
        ? _durations[index]
        : '${5 + (index % 8)} min';

    return GestureDetector(
      onTap: isLocked ? null : () => onChapterTap(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent
              ? color.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
            width: isCurrent ? 1 : 0,
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.successGreen
                    : isCurrent
                        ? color
                        : AppColors.progressTrack,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white)
                    : isCurrent
                        ? const Icon(Icons.play_arrow_rounded,
                            size: 16, color: Colors.white)
                        : isLocked
                            ? Icon(Icons.lock_rounded,
                                size: 12,
                                color: AppColors.textLight)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight,
                                ),
                              ),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isLocked
                          ? AppColors.textLight
                          : AppColors.textDark,
                      fontSize: 13,
                    ),
                  ),
                  if (isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Tap to continue',
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  if (isDone)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Completed ✓',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            // Duration
            Text(
              duration,
              style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight, fontSize: 11),
            ),
            const SizedBox(width: 8),
            Icon(
              isCurrent
                  ? Icons.arrow_forward_ios_rounded
                  : isDone
                      ? Icons.replay_rounded
                      : Icons.chevron_right_rounded,
              size: 16,
              color: isCurrent
                  ? color
                  : isLocked
                      ? AppColors.progressTrack
                      : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
