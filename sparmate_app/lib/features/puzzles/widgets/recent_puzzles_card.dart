import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Recent Puzzles list showing completed and failed puzzle history.
/// Accepts dynamic data from the API.
class RecentPuzzlesCard extends StatelessWidget {
  final List<RecentPuzzleData> puzzles;

  const RecentPuzzlesCard({super.key, this.puzzles = const []});

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
          Row(
            children: [
              Icon(Icons.history_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Recent Puzzles',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              if (puzzles.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${puzzles.length}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (puzzles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.extension_rounded,
                        size: 32, color: AppColors.textLight),
                    const SizedBox(height: 8),
                    Text('No puzzles attempted yet.',
                        style: tt.bodySmall
                            ?.copyWith(color: AppColors.textLight)),
                  ],
                ),
              ),
            )
          else
            ...puzzles.asMap().entries.map((e) {
              final isLast = e.key == puzzles.length - 1;
              return _buildRow(context, e.value, isLast);
            }),
        ],
      ),
    );
  }

  Widget _buildRow(
      BuildContext context, RecentPuzzleData puzzle, bool isLast) {
    final tt = Theme.of(context).textTheme;
    final statusColor =
        puzzle.solved ? AppColors.successGreen : AppColors.liveRed;
    final statusIcon = puzzle.solved
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    final diffColor = switch (puzzle.difficulty.toLowerCase()) {
      'beginner' => AppColors.successGreen,
      'intermediate' => Colors.amber.shade700,
      'advanced' => AppColors.liveRed,
      _ => AppColors.textMedium,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.1),
            ),
            child: Icon(statusIcon, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      puzzle.theme,
                      style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: diffColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        puzzle.difficulty,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: diffColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Rating ${puzzle.rating}',
                      style: tt.bodySmall?.copyWith(
                          color: AppColors.textLight, fontSize: 11),
                    ),
                    if (puzzle.timeSeconds != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.timer_rounded,
                          size: 11, color: AppColors.textLight),
                      const SizedBox(width: 2),
                      Text(
                        '${puzzle.timeSeconds}s',
                        style: tt.bodySmall?.copyWith(
                            color: AppColors.textLight, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            puzzle.solved ? 'Solved' : 'Failed',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor),
          ),
        ],
      ),
    );
  }
}

class RecentPuzzleData {
  final int puzzleId;
  final String theme;
  final String difficulty;
  final int rating;
  final bool solved;
  final int? timeSeconds;

  const RecentPuzzleData({
    required this.puzzleId,
    required this.theme,
    required this.difficulty,
    required this.rating,
    required this.solved,
    this.timeSeconds,
  });
}
