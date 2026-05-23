import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Insights card showing AI-generated coaching recommendations.
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key});

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
              Icon(Icons.tips_and_updates_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Insights', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Insight text ──
          RichText(
            text: TextSpan(
              style: tt.bodyMedium?.copyWith(
                color: AppColors.textMedium,
                height: 1.5,
                fontSize: 13.5,
              ),
              children: [
                const TextSpan(
                  text: 'Your endgame conversion rate has dropped below 50%. Focus on ',
                ),
                TextSpan(
                  text: 'Rook and Pawn',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textDark.withValues(alpha: 0.4),
                  ),
                ),
                const TextSpan(
                  text: ' endgames to secure more wins.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── CTA Button ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Text('Train Endgames'),
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
}
