import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../lessons/screens/lessons_screen.dart';
import '../../puzzles/screens/puzzles_screen.dart';
import '../../sparring/screens/gm_selection_screen.dart';

/// Training Plan card with tappable task list and functional Start Session CTA.
/// Accepts optional [planItems] from the coaching API; falls back to demo data.
/// Each task navigates to the relevant feature screen (lessons, puzzles, sparring).
class TrainingPlanCard extends StatefulWidget {
  final List<dynamic>? planItems;

  const TrainingPlanCard({super.key, this.planItems});

  @override
  State<TrainingPlanCard> createState() => _TrainingPlanCardState();
}

class _TrainingPlanCardState extends State<TrainingPlanCard> {
  final Set<int> _completedTasks = {};

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final items = _buildItems();
    final todayIndex = _getTodayIndex(items);

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
              Icon(Icons.route_rounded,
                  size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Training Plan',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              index: i,
              icon: items[i]['icon'] as IconData,
              typeLabel: items[i]['type'] as String,
              title: items[i]['title'] as String,
              subtitle: items[i]['subtitle'] as String?,
              activityType: items[i]['activityType'] as String,
              isToday: i == todayIndex,
              isCompleted: _completedTasks.contains(i),
            ),
          ],
          const SizedBox(height: 20),

          // ── Start Session button ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _startSession(context, items, todayIndex),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(todayIndex >= 0
                  ? 'Start Today\'s Session'
                  : 'Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Determine which task index corresponds to today's day of the week.
  int _getTodayIndex(List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final todayName = days[now.weekday - 1];

    for (var i = 0; i < items.length; i++) {
      final subtitle = items[i]['subtitle'] as String?;
      if (subtitle != null && subtitle.startsWith(todayName)) {
        return i;
      }
    }
    return items.isNotEmpty ? 0 : -1;
  }

  /// Navigate to the appropriate screen based on activity type.
  void _navigateToActivity(BuildContext context, String activityType) {
    Widget? screen;

    switch (activityType.toLowerCase()) {
      case 'lesson':
        screen = const LessonsScreen();
        break;
      case 'puzzle':
      case 'puzzles':
        screen = const PuzzlesScreen();
        break;
      case 'sparring':
      case 'practice':
        screen = const GmSelectionScreen();
        break;
    }

    if (screen != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen!),
      );
    }
  }

  /// Start today's session — navigate to the appropriate activity.
  void _startSession(
    BuildContext context,
    List<Map<String, dynamic>> items,
    int todayIndex,
  ) {
    if (todayIndex >= 0 && todayIndex < items.length) {
      final actType = items[todayIndex]['activityType'] as String;
      _navigateToActivity(context, actType);
    }
  }

  List<Map<String, dynamic>> _buildItems() {
    if (widget.planItems == null || widget.planItems!.isEmpty) {
      // Demo/fallback items
      return [
        {
          'icon': Icons.school_rounded,
          'type': 'LESSON',
          'title': 'Pawn Structure Masterclass',
          'subtitle': null,
          'activityType': 'lesson',
        },
        {
          'icon': Icons.extension_rounded,
          'type': 'PUZZLES',
          'title': 'Mid-game Tactical Drills',
          'subtitle': null,
          'activityType': 'puzzle',
        },
        {
          'icon': Icons.sports_esports_rounded,
          'type': 'PRACTICE',
          'title': 'Spar with Petrosian',
          'subtitle': 'Focusing on positional play',
          'activityType': 'sparring',
        },
      ];
    }

    // Map API plan items to UI items
    return widget.planItems!.map((item) {
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
        'activityType': (map['type'] ?? 'lesson').toString().toLowerCase(),
      };
    }).toList();
  }

  Widget _buildTask(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String typeLabel,
    required String title,
    String? subtitle,
    required String activityType,
    bool isToday = false,
    bool isCompleted = false,
  }) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _navigateToActivity(context, activityType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.primaryBlue.withValues(alpha: 0.04)
              : AppColors.cardBgSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? AppColors.primaryBlue.withValues(alpha: 0.3)
                : AppColors.border,
            width: isToday ? 1.0 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Completion checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_completedTasks.contains(index)) {
                    _completedTasks.remove(index);
                  } else {
                    _completedTasks.add(index);
                  }
                });
              },
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.successGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.successGreen
                        : AppColors.textLight,
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
            Icon(icon,
                size: 22,
                color: AppColors.primaryBlue.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? AppColors.textLight
                          : AppColors.textDark,
                      fontSize: 13,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
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
            const Icon(Icons.chevron_right_rounded,
                size: 22, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
