import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Phase Accuracy card showing Opening, Tactics, and Endgame accuracy
/// as horizontal progress bars.
/// Accepts optional [phaseData] from the analytics API.
class PhaseAccuracyCard extends StatelessWidget {
  final Map<String, dynamic>? phaseData;

  const PhaseAccuracyCard({super.key, this.phaseData});

  List<_Phase> get _phases {
    if (phaseData != null) {
      return [
        _Phase('Opening', (phaseData!['opening'] as num? ?? 80) / 100, '${phaseData!['opening'] ?? 80}%', const Color(0xFF3D5AFE)),
        _Phase('Middlegame', (phaseData!['middlegame'] as num? ?? 62) / 100, '${phaseData!['middlegame'] ?? 62}%', const Color(0xFFE53935)),
        _Phase('Endgame', (phaseData!['endgame'] as num? ?? 45) / 100, '${phaseData!['endgame'] ?? 45}%', const Color(0xFF43A047)),
      ];
    }
    return const [
      _Phase('Opening', 0.80, '80%', Color(0xFF3D5AFE)),
      _Phase('Tactics', 0.62, '62%', Color(0xFFE53935)),
      _Phase('Endgame', 0.45, '45%', Color(0xFF43A047)),
    ];
  }

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
              Icon(Icons.pie_chart_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Phase Accuracy', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          // ── Bars ──
          ..._phases.map((p) => _buildBar(context, p)),
        ],
      ),
    );
  }

  Widget _buildBar(BuildContext context, _Phase phase) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                phase.name,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontSize: 13,
                ),
              ),
              Text(
                phase.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: phase.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: phase.value,
              minHeight: 6,
              backgroundColor: AppColors.progressTrack,
              valueColor: AlwaysStoppedAnimation(phase.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Phase {
  final String name;
  final double value;
  final String label;
  final Color color;
  const _Phase(this.name, this.value, this.label, this.color);
}
