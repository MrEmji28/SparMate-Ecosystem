import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

/// Destination tells the banner which content type to show.
enum RecommendationContext { lessons, puzzles }

/// BKT-driven "Recommended for You" banner.
///
/// Reads [AppState.recommendationsData] and renders:
/// - A focus message ("Your King Safety is at 10% mastery…")
/// - The top-3 weak skill chips
/// - Tappable content cards (lessons OR puzzles depending on [context])
///
/// Automatically fetches if data is not yet loaded.
class BktRecommendationBanner extends StatefulWidget {
  final RecommendationContext context;

  /// Called when the user taps a recommended lesson.
  /// Receives the lesson map: { id, title, category, difficulty, ... }
  final void Function(Map<String, dynamic> lesson)? onLessonTap;

  /// Called when the user taps a recommended puzzle.
  /// Receives the puzzle map: { id, theme, category, difficulty, ... }
  final void Function(Map<String, dynamic> puzzle)? onPuzzleTap;

  const BktRecommendationBanner({
    super.key,
    required this.context,
    this.onLessonTap,
    this.onPuzzleTap,
  });

  @override
  State<BktRecommendationBanner> createState() =>
      _BktRecommendationBannerState();
}

class _BktRecommendationBannerState extends State<BktRecommendationBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.recommendationsData == null && !state.recommendationsLoading) {
        state.fetchRecommendations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rec = state.recommendationsData;
    final isLoading = state.recommendationsLoading;

    if (isLoading) return _buildSkeleton(context);
    if (rec == null) return const SizedBox.shrink();

    final weakSkills = (rec['weak_skills'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final focusMessage = rec['focus_message'] as String? ?? '';
    final items = widget.context == RecommendationContext.lessons
        ? (rec['recommended_lessons'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            []
        : (rec['recommended_puzzles'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];

    if (items.isEmpty) return const SizedBox.shrink();

    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.08),
            AppColors.primaryBlue.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 16, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended for You',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Based on your BKT mastery profile',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.textLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              InkWell(
                onTap: () => context.read<AppState>().fetchRecommendations(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.refresh_rounded,
                      size: 16, color: AppColors.textLight),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Focus message ────────────────────────────────────────
          Text(
            focusMessage,
            style: tt.bodySmall?.copyWith(
              color: AppColors.textDark,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 10),

          // ── Weak skill chips ─────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: weakSkills.map((skill) {
              final pct = skill['mastery_pct'] as int? ?? 0;
              final label = skill['label'] as String? ?? '';
              final chipColor = pct < 30
                  ? AppColors.liveRed
                  : pct < 60
                      ? const Color(0xFFF59E0B)
                      : AppColors.successGreen;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: chipColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: chipColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$label · $pct%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: chipColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // ── Recommended content cards (horizontal scroll) ─────────
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final item = items[i];
                return widget.context == RecommendationContext.lessons
                    ? _LessonChip(
                        data: item,
                        onTap: widget.onLessonTap != null
                            ? () => widget.onLessonTap!(item)
                            : null,
                      )
                    : _PuzzleChip(
                        data: item,
                        onTap: widget.onPuzzleTap != null
                            ? () => widget.onPuzzleTap!(item)
                            : null,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(16),
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading recommendations…',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

// ── Lesson chip ────────────────────────────────────────────────────────

class _LessonChip extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _LessonChip({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final category = data['category'] as String? ?? '';
    final difficulty = data['difficulty'] as String? ?? '';
    final chapters = data['chapter_count'] as int? ?? 0;

    final Color color = _categoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$chapters chapters · $difficulty',
              style: TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) => switch (category) {
        'Opening' => const Color(0xFF3949AB),
        'Tactics' => const Color(0xFFE53935),
        'Endgame' => const Color(0xFF00838F),
        'Strategy' => const Color(0xFF2E7D32),
        'Middlegame' => const Color(0xFFEF6C00),
        _ => AppColors.primaryBlue,
      };
}

// ── Puzzle chip ────────────────────────────────────────────────────────

class _PuzzleChip extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const _PuzzleChip({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = data['theme'] as String? ?? 'Tactics';
    final category = data['category'] as String? ?? '';
    final difficulty = data['difficulty'] as String? ?? '';
    final rating = data['rating'] as int? ?? 1200;

    final Color color = _categoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
            Text(
              theme,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Rating $rating · $difficulty',
              style: TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) => switch (category) {
        'Tactics' => const Color(0xFFE53935),
        'Endgame' => const Color(0xFF00838F),
        'Strategy' => const Color(0xFF2E7D32),
        _ => AppColors.primaryBlue,
      };
}
