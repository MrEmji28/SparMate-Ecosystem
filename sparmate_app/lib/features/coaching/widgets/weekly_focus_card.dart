import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Weekly Focus card showing BKT mastery progress bars.
/// Accepts optional [bktMatrix] from the coaching API; falls back to demo data.
class WeeklyFocusCard extends StatelessWidget {
  final Map<String, dynamic>? bktMatrix;

  const WeeklyFocusCard({super.key, this.bktMatrix});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Build skill list from live BKT matrix or use defaults
    final skills = _buildSkillList();

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
              const Spacer(),
              if (bktMatrix != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIVE BKT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.successGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          // ── Skill progress bars ──
          for (var i = 0; i < skills.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _buildProgressRow(
              context,
              skills[i]['label'] as String,
              skills[i]['value'] as double,
              '${((skills[i]['value'] as double) * 100).toInt()}%',
              skills[i]['isPriority'] as bool
                  ? AppColors.liveRed
                  : AppColors.primaryBlue,
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildSkillList() {
    if (bktMatrix == null) {
      return [
        {'label': 'OPENING', 'value': 0.80, 'isPriority': false},
        {'label': 'TACTICS', 'value': 0.62, 'isPriority': false},
        {'label': 'ENDGAME (PRIORITY)', 'value': 0.45, 'isPriority': true},
      ];
    }

    // Sort by mastery ascending → weakest first
    final entries = bktMatrix!.entries.toList()
      ..sort((a, b) => (a.value as num).compareTo(b.value as num));

    // Take top 5 weakest skills to display
    return entries.take(5).map((e) {
      final mastery = (e.value as num).toDouble();
      final label = e.key.replaceAll('_', ' ').toUpperCase();
      return {
        'label': mastery < 0.40 ? '$label (PRIORITY)' : label,
        'value': mastery,
        'isPriority': mastery < 0.40,
      };
    }).toList();
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
