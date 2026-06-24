import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Weekly Focus card showing BKT mastery progress bars with animations.
/// Accepts optional [bktMatrix] from the coaching API; falls back to demo data.
/// Shows all 8 skills with mastery level labels and color-coded progress.
class WeeklyFocusCard extends StatefulWidget {
  final Map<String, dynamic>? bktMatrix;

  const WeeklyFocusCard({super.key, this.bktMatrix});

  @override
  State<WeeklyFocusCard> createState() => _WeeklyFocusCardState();
}

class _WeeklyFocusCardState extends State<WeeklyFocusCard>
    with SingleTickerProviderStateMixin {
  bool _showAll = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    // Start animation after a short delay for stagger effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Build skill list from live BKT matrix or use defaults
    final allSkills = _buildSkillList();
    final displaySkills = _showAll ? allSkills : allSkills.take(5).toList();

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
              Icon(Icons.donut_large_rounded,
                  size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Weekly Focus',
                  style: tt.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (widget.bktMatrix != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppColors.successGreen.withValues(alpha: 0.1),
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
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              return Column(
                children: [
                  for (var i = 0; i < displaySkills.length; i++) ...[
                    if (i > 0) const SizedBox(height: 18),
                    _buildProgressRow(
                      context,
                      displaySkills[i]['label'] as String,
                      displaySkills[i]['value'] as double,
                      displaySkills[i]['isPriority'] as bool,
                      displaySkills[i]['value'] as double,
                      i,
                    ),
                  ],
                ],
              );
            },
          ),

          // ── Show All / Show Less toggle ──
          if (allSkills.length > 5) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _showAll = !_showAll),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAll
                          ? 'Show Less'
                          : 'Show All ${allSkills.length} Skills',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAll
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get mastery level label and color based on mastery value.
  ({String label, Color color}) _getMasteryLevel(double mastery) {
    if (mastery >= 0.80) {
      return (label: 'Expert', color: const Color(0xFF1B5E20));
    } else if (mastery >= 0.60) {
      return (label: 'Proficient', color: AppColors.successGreen);
    } else if (mastery >= 0.40) {
      return (label: 'Developing', color: const Color(0xFFFF8F00));
    } else {
      return (label: 'Novice', color: AppColors.liveRed);
    }
  }

  /// Get progress bar color based on mastery value.
  Color _getBarColor(double mastery, bool isPriority) {
    if (isPriority) return AppColors.liveRed;
    if (mastery >= 0.80) return const Color(0xFF2E7D32);
    if (mastery >= 0.60) return AppColors.successGreen;
    if (mastery >= 0.40) return const Color(0xFFFF8F00);
    return AppColors.liveRed;
  }

  List<Map<String, dynamic>> _buildSkillList() {
    if (widget.bktMatrix == null) {
      return [
        {'label': 'OPENING', 'value': 0.80, 'isPriority': false},
        {'label': 'TACTICS', 'value': 0.62, 'isPriority': false},
        {'label': 'ENDGAME', 'value': 0.45, 'isPriority': true},
      ];
    }

    // Sort by mastery ascending → weakest first
    final entries = widget.bktMatrix!.entries.toList()
      ..sort((a, b) => (a.value as num).compareTo(b.value as num));

    // Show all skills
    return entries.map((e) {
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
    bool isPriority,
    double mastery,
    int index,
  ) {
    final tt = Theme.of(context).textTheme;
    final percent = '${(value * 100).toInt()}%';
    final barColor = _getBarColor(mastery, isPriority);
    final level = _getMasteryLevel(mastery);

    // Stagger the animation — each bar starts slightly later
    final staggerDelay = (index * 0.08).clamp(0.0, 0.5);
    final animValue = (_progressAnimation.value - staggerDelay)
        .clamp(0.0, 1.0 - staggerDelay) / (1.0 - staggerDelay);
    final animatedValue = value * animValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: tt.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: level.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                level.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: level.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
            value: animatedValue,
            minHeight: 7,
            backgroundColor: AppColors.progressTrack,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}

/// A simple widget that rebuilds when an animation changes.
/// Similar to AnimatedBuilder but accepts a nullable child.
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder._internal(
      animation: animation,
      builder: builder,
      child: child,
    );
  }

  // Use AnimatedBuilder from Flutter
  static Widget _internal({
    required Animation<double> animation,
    required Widget Function(BuildContext context, Widget? child) builder,
    Widget? child,
  }) {
    return _AnimatedBuilderWidget(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class _AnimatedBuilderWidget extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimatedBuilderWidget({
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
