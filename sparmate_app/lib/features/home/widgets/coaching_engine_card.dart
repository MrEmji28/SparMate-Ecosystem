import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../coaching/screens/coaching_screen.dart';

/// Coaching Engine card showing weekly focus areas with percentage chips,
/// a NEW INSIGHTS badge, and personalized feedback text.
class CoachingEngineCard extends StatelessWidget {
  const CoachingEngineCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CoachingScreen()),
      ),
      child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coaching Engine',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Weekly Focus',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _insightsBadge(),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CoachingScreen()),
                    ),
                    child: Text(
                      'View Report',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Focus chips ──
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FocusChip(label: 'Opening', value: '80%'),
              _FocusChip(label: 'Tactics', value: '62%'),
              _FocusChip(label: 'Endgame', value: '45%'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Feedback ──
          Text(
            'Personalized feedback: "Focus on pawn structure in the mid-game."',
            style: tt.bodyMedium?.copyWith(
              color: AppColors.textMedium,
              fontStyle: FontStyle.normal,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _insightsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.insightsGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.insightsGreen.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: const Text(
        'NEW INSIGHTS',
        style: TextStyle(
          color: AppColors.successGreen,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  final String label;
  final String value;

  const _FocusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.chipBlueBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          color: AppColors.chipBlueText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
