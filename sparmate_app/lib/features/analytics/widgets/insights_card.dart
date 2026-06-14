import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Insights card showing AI-generated coaching recommendations.
/// Accepts optional [insights] from the analytics API.
class InsightsCard extends StatelessWidget {
  final List<dynamic>? insights;

  const InsightsCard({super.key, this.insights});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Build insight items from API data or use defaults
    final items = _buildInsightItems();

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
              Icon(Icons.tips_and_updates_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Insights', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (insights != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIVE',
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
          const SizedBox(height: 16),

          // ── Insight items ──
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildInsightRow(
              context,
              icon: items[i]['icon'] as IconData,
              iconColor: items[i]['color'] as Color,
              title: items[i]['title'] as String,
              message: items[i]['message'] as String,
            ),
          ],

          const SizedBox(height: 18),

          // ── CTA Button ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Text('Train Weaknesses'),
              label: const Icon(Icons.arrow_forward_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildInsightItems() {
    if (insights != null && insights!.isNotEmpty) {
      return insights!.map((item) {
        final map = item as Map<String, dynamic>;
        final type = map['type'] ?? 'stat';
        final iconData = switch (type) {
          'strength' => Icons.trending_up_rounded,
          'weakness' => Icons.warning_rounded,
          'tip' => Icons.lightbulb_rounded,
          _ => Icons.analytics_rounded,
        };
        final color = switch (type) {
          'strength' => AppColors.successGreen,
          'weakness' => AppColors.liveRed,
          'tip' => const Color(0xFFF59E0B),
          _ => AppColors.primaryBlue,
        };
        return {
          'icon': iconData,
          'color': color,
          'title': map['title'] ?? 'Insight',
          'message': map['message'] ?? '',
        };
      }).toList();
    }

    // Default fallback
    return [
      {
        'icon': Icons.warning_rounded,
        'color': AppColors.liveRed,
        'title': 'Endgame Conversion',
        'message': 'Your endgame conversion rate has dropped below 50%. Focus on Rook and Pawn endgames to secure more wins.',
      },
    ];
  }

  Widget _buildInsightRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: tt.bodySmall?.copyWith(
                  color: AppColors.textMedium,
                  height: 1.45,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
