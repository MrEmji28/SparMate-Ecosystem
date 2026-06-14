import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Primary Directive card with AI coaching quote and recent game indicators.
/// Accepts optional [directive] from the BKT coaching engine API.
class PrimaryDirectiveCard extends StatelessWidget {
  final String? directive;

  const PrimaryDirectiveCard({super.key, this.directive});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final displayDirective = directive ?? 'Focus on pawn structure in the mid-game.';

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
                child: const Icon(Icons.smart_toy_rounded, size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Directive',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
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
                            text: directive != null
                                ? 'Based on your BKT mastery analysis.'
                                : 'Your recent matches show a tendency to create isolated pawns under pressure.',
                          ),
                        ],
                      ),
                    ),
                    if (directive != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.1),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBgSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT INDICATORS',
                  style: tt.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 14),
                _buildIndicator(
                  context,
                  icon: Icons.error_rounded,
                  iconColor: AppColors.liveRed,
                  opponent: '@KasparovFan',
                  text: 'Doubled pawns on the f-file restricted your bishop pair.',
                ),
                const SizedBox(height: 12),
                _buildIndicator(
                  context,
                  icon: Icons.error_rounded,
                  iconColor: AppColors.liveRed,
                  opponent: '@RookAndRoll',
                  text: 'An isolated queen\'s pawn became a long-term weakness in the endgame.',
                ),
                const SizedBox(height: 12),
                _buildIndicator(
                  context,
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.successGreen,
                  opponent: '@KnightRider',
                  text: 'Excellent central pawn chain maintained control. Replicate this.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String opponent,
    required String text,
  }) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: iconColor),
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
                  text: opponent,
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                TextSpan(text: ': $text'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
