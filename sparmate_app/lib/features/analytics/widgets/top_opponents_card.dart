import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Top Opponents card listing grandmaster opponents and win rates.
/// Accepts optional [opponents] from the analytics API.
class TopOpponentsCard extends StatelessWidget {
  final List<dynamic>? opponents;

  const TopOpponentsCard({super.key, this.opponents});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final items = _buildOpponentList();

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
          for (var i = 0; i < items.length; i++)
            _buildRow(context, items[i], i == items.length - 1),
        ],
      ),
    );
  }

  List<_Opponent> _buildOpponentList() {
    if (opponents != null && opponents!.isNotEmpty) {
      // Color palette for opponents
      const colors = [
        Color(0xFF1565C0),
        Color(0xFF6A1B9A),
        Color(0xFF2E7D32),
        Color(0xFF00838F),
        Color(0xFFE65100),
      ];

      return opponents!.asMap().entries.map((entry) {
        final map = entry.value as Map<String, dynamic>;
        final gm = map['grandmaster'] as Map<String, dynamic>?;
        final name = gm?['full_name'] ?? gm?['name'] ?? 'Unknown';
        final style = gm?['style'] ?? 'Unknown';
        final winRate = map['win_rate'] ?? 0;
        final initials = (name as String).split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
        final color = colors[entry.key % colors.length];

        return _Opponent(initials, 'GM $name', style, '$winRate%', color);
      }).toList();
    }

    // Default fallback
    return const [
      _Opponent('To', 'GM Torre', 'Attacking Style', '68%', Color(0xFF1565C0)),
      _Opponent('Ta', 'GM Tal', 'Tactical Master', '42%', Color(0xFF6A1B9A)),
      _Opponent('Pe', 'GM Petrosian', 'Positional', '55%', Color(0xFF2E7D32)),
      _Opponent('Ca', 'GM Carlsen', 'Universal', '30%', Color(0xFF00838F)),
    ];
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
