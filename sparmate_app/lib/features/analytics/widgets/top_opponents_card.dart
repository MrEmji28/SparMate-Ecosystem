import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Top Opponents card listing grandmaster opponents and win rates.
class TopOpponentsCard extends StatelessWidget {
  const TopOpponentsCard({super.key});

  static const _opponents = [
    _Opponent('To', 'GM Torre', 'Attacking Style', '68%', Color(0xFF1565C0)),
    _Opponent('Ta', 'GM Tal', 'Tactical Master', '42%', Color(0xFF6A1B9A)),
    _Opponent('Pe', 'GM Petrosian', 'Positional', '55%', Color(0xFF2E7D32)),
    _Opponent('Ca', 'GM Carlsen', 'Universal', '30%', Color(0xFF00838F)),
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
          // ── Header ──
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Top Opponents', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          // ── Opponent rows ──
          ..._opponents.asMap().entries.map((e) {
            final isLast = e.key == _opponents.length - 1;
            return _buildRow(context, e.value, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _Opponent opp, bool isLast) {
    final tt = Theme.of(context).textTheme;

    // Parse win rate to determine color
    final wr = int.tryParse(opp.winRate.replaceAll('%', '')) ?? 50;
    final wrColor = wr >= 55 ? AppColors.successGreen : (wr >= 40 ? AppColors.primaryBlue : AppColors.liveRed);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: opp.color.withValues(alpha: 0.12),
              border: Border.all(color: opp.color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Center(
              child: Text(
                opp.initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: opp.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + style
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opp.name,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  opp.style,
                  style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
          // Win rate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: wrColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${opp.winRate} WR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: wrColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Opponent {
  final String initials;
  final String name;
  final String style;
  final String winRate;
  final Color color;
  const _Opponent(this.initials, this.name, this.style, this.winRate, this.color);
}
