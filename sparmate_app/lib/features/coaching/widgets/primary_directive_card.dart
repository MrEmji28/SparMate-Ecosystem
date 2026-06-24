import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Primary Directive card with AI coaching quote and recent game indicators.
/// Accepts optional [directive] from the BKT coaching engine API and
/// [recentIndicators] list from the coaching-insights endpoint.
class PrimaryDirectiveCard extends StatefulWidget {
  final String? directive;
  final List<dynamic>? recentIndicators;

  const PrimaryDirectiveCard({
    super.key,
    this.directive,
    this.recentIndicators,
  });

  @override
  State<PrimaryDirectiveCard> createState() => _PrimaryDirectiveCardState();
}

class _PrimaryDirectiveCardState extends State<PrimaryDirectiveCard>
    with SingleTickerProviderStateMixin {
  bool _showAllIndicators = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final displayDirective =
        widget.directive ?? 'Focus on pawn structure in the mid-game.';
    final hasLiveData = widget.directive != null;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Directive',
                      style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: tt.bodyMedium?.copyWith(
                          color: AppColors.textMedium,
                          height: 1.5,
                          fontSize: 13.5,
                        ),
                        children: [
                          TextSpan(
                            text: '"$displayDirective" ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          TextSpan(
                            text: hasLiveData
                                ? 'Based on your BKT mastery analysis.'
                                : 'Your recent matches show a tendency to create isolated pawns under pressure.',
                          ),
                        ],
                      ),
                    ),
                    if (hasLiveData)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LIVE FROM API',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Recent Indicators ──
          _buildIndicatorsSection(context, tt),
        ],
      ),
    );
  }

  Widget _buildIndicatorsSection(BuildContext context, TextTheme tt) {
    final indicators = widget.recentIndicators;
    final hasLiveIndicators = indicators != null && indicators.isNotEmpty;

    // Determine which indicators to show
    final List<dynamic> displayIndicators;
    if (hasLiveIndicators) {
      displayIndicators = _showAllIndicators
          ? indicators
          : indicators.take(3).toList();
    } else {
      // Fallback static indicators
      displayIndicators = [];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'RECENT INDICATORS',
                style: tt.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
              const Spacer(),
              if (hasLiveIndicators)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${indicators.length} GAMES',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (!hasLiveIndicators) ...[
            // ── Empty State ──
            _buildEmptyIndicators(tt),
          ] else ...[
            // ── Live Indicators ──
            for (var i = 0; i < displayIndicators.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildLiveIndicator(context, displayIndicators[i]),
            ],

            // Show more/less toggle
            if (indicators.length > 3) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () =>
                    setState(() => _showAllIndicators = !_showAllIndicators),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAllIndicators ? 'Show Less' : 'Show More',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAllIndicators
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildLiveIndicator(BuildContext context, dynamic indicator) {
    final tt = Theme.of(context).textTheme;
    final map = indicator as Map<String, dynamic>;
    final iconType = map['icon_type'] as String? ?? 'negative';
    final opponent = map['opponent'] as String? ?? 'Opponent';
    final text = map['text'] as String? ?? '';

    final isPositive = iconType == 'positive';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            isPositive
                ? Icons.check_circle_rounded
                : Icons.error_rounded,
            size: 18,
            color: isPositive ? AppColors.successGreen : AppColors.liveRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: tt.bodySmall?.copyWith(
                color: AppColors.textMedium,
                height: 1.45,
                fontSize: 12,
              ),
              children: [
                const TextSpan(text: 'Game vs. '),
                TextSpan(
                  text: '@$opponent',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
                TextSpan(text: ': $text'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyIndicators(TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.textLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Play some sparring matches to see personalized coaching insights here.',
              style: tt.bodySmall?.copyWith(
                color: AppColors.textLight,
                height: 1.4,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
