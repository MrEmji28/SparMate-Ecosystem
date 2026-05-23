import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Weekly Focus card showing Opening/Tactics/Endgame progress bars.
class WeeklyFocusCard extends StatelessWidget {
  const WeeklyFocusCard({super.key});

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
              Icon(Icons.donut_large_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Weekly Focus', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 22),
          _buildProgressRow(context, 'OPENING', 0.80, '80%', AppColors.primaryBlue),
          const SizedBox(height: 18),
          _buildProgressRow(context, 'TACTICS', 0.62, '62%', AppColors.primaryBlue),
          const SizedBox(height: 18),
          _buildProgressRow(context, 'ENDGAME (PRIORITY)', 0.45, '45%', AppColors.liveRed),
        ],
      ),
    );
  }

  Widget _buildProgressRow(
    BuildContext context,
    String label,
    double value,
    String percent,
    Color barColor,
  ) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: tt.labelSmall?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium,
                fontSize: 11,
              ),
            ),
            Text(
              percent,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: AppColors.progressTrack,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}
