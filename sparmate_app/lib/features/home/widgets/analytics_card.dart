import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

/// Analytics card — shows the user's current ELO rating from the
/// backend user data, BKT mastery average, and match stats.
/// All data is live from AppState (dashboard + user + BKT matrix).
class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();

    // Real ELO from user data
    final user = state.user;
    final eloRating = (user?['elo_rating'] as num?)?.toInt() ?? 0;

    // BKT mastery average
    final bktSkills = state.bktMatrix?['skills'] as Map<String, dynamic>?;
    final avgMastery = _computeAvgMastery(bktSkills);

    // Match stats from dashboard
    final dashboard = state.dashboardData;
    final stats = dashboard?['stats'] as Map<String, dynamic>?;
    final totalMatches = (stats?['total_matches'] as num?)?.toInt() ?? 0;
    final wins = (stats?['wins'] as num?)?.toInt() ?? 0;

    // Win rate
    final winRate = totalMatches > 0 ? ((wins / totalMatches) * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(
                Icons.analytics_outlined,
                size: 20,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'Analytics',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Label ──
          Text(
            'CURRENT RATING',
            style: tt.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),

          // ── Rating ──
          Text(
            '$eloRating',
            style: tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 26,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          // ── Stats row ──
          Row(
            children: [
              _StatChip(
                label: 'Matches',
                value: '$totalMatches',
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Win Rate',
                value: totalMatches > 0 ? '$winRate%' : '—',
                color: AppColors.successGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Mastery Average ──
          Row(
            children: [
              Text(
                'AVG MASTERY:',
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${avgMastery}%',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compute the average mastery percentage across all BKT skills.
  int _computeAvgMastery(Map<String, dynamic>? bktSkills) {
    if (bktSkills == null || bktSkills.isEmpty) return 0;
    double sum = 0;
    for (final v in bktSkills.values) {
      sum += (v is num) ? v.toDouble() : 0;
    }
    return ((sum / bktSkills.length) * 100).round();
  }
}

/// A small stat chip for inline metrics.
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.7),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
