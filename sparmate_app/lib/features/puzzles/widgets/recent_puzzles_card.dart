import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Recent Puzzles list showing completed and failed puzzle history.
class RecentPuzzlesCard extends StatelessWidget {
  const RecentPuzzlesCard({super.key});

  static const _puzzles = [
    _PuzzleResult(id: '#5492', rating: '1620', passed: true),
    _PuzzleResult(id: '#9102', rating: '1610', passed: true),
    _PuzzleResult(id: '#1029', rating: '1700', passed: false),
  ];

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
          Text('Recent Puzzles', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 14),
          ..._puzzles.asMap().entries.map((e) {
            final isLast = e.key == _puzzles.length - 1;
            return _buildRow(context, e.value, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _PuzzleResult puzzle, bool isLast) {
    final tt = Theme.of(context).textTheme;
    final statusColor = puzzle.passed ? AppColors.successGreen : AppColors.liveRed;
    final statusIcon = puzzle.passed ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Puzzle ${puzzle.id}',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rating ${puzzle.rating}',
                  style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(statusIcon, size: 24, color: statusColor),
        ],
      ),
    );
  }
}

class _PuzzleResult {
  final String id;
  final String rating;
  final bool passed;
  const _PuzzleResult({required this.id, required this.rating, required this.passed});
}
