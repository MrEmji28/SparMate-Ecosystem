import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Training Plan card with task list and Start Session CTA.
/// Accepts optional [planItems] from the coaching API; falls back to demo data.
class TrainingPlanCard extends StatelessWidget {
  final List<dynamic>? planItems;

  const TrainingPlanCard({super.key, this.planItems});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final items = _buildItems();

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
              Icon(Icons.route_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Training Plan', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length} Tasks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Task items ──
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildTask(
              context,
              icon: items[i]['icon'] as IconData,
              typeLabel: items[i]['type'] as String,
              typeColor: AppColors.primaryBlue,
              title: items[i]['title'] as String,
              subtitle: items[i]['subtitle'] as String?,
            ),
          ],
          const SizedBox(height: 20),

          // ── Start Session button ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildItems() {
    if (planItems == null || planItems!.isEmpty) {
      // Demo/fallback items
      return [
        {
          'icon': Icons.school_rounded,
          'type': 'LESSON',
          'title': 'Pawn Structure Masterclass',
          'subtitle': null,
        },
        {
          'icon': Icons.extension_rounded,
          'type': 'PUZZLES',
          'title': 'Mid-game Tactical Drills',
          'subtitle': null,
        },
        {
          'icon': Icons.sports_esports_rounded,
          'type': 'PRACTICE',
          'title': 'Spar with Petrosian',
          'subtitle': 'Focusing on positional play',
        },
      ];
    }

    // Map API plan items to UI items
    return planItems!.map((item) {
      final map = item as Map<String, dynamic>;
      final type = (map['type'] ?? 'lesson').toString().toUpperCase();
      final icon = switch (type) {
        'LESSON' => Icons.school_rounded,
        'PUZZLE' || 'PUZZLES' => Icons.extension_rounded,
        'PRACTICE' || 'SPARRING' => Icons.sports_esports_rounded,
        _ => Icons.assignment_rounded,
      };
      return {
        'icon': icon,
        'type': type,
        'title': map['activity'] ?? map['title'] ?? 'Training Activity',
        'subtitle': map['day'] != null
            ? '${map['day']} • ${map['duration_min'] ?? 20} min'
            : null,
      };
    }).toList();
  }

  Widget _buildTask(
    BuildContext context, {
    required IconData icon,
    required String typeLabel,
    required Color typeColor,
    required String title,
    String? subtitle,
  }) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primaryBlue.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: tt.bodySmall?.copyWith(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textLight),
        ],
      ),
    );
  }
}
