import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Match Results card with a donut chart showing W/L/D distribution.
class MatchResultsCard extends StatelessWidget {
  const MatchResultsCard({super.key});

  static const _wins = 65;
  static const _losses = 35;
  static const _draws = 20;
  static const _total = _wins + _losses + _draws; // 120

  static const _winColor = Color(0xFF43A047);
  static const _lossColor = Color(0xFFE53935);
  static const _drawColor = Color(0xFF78909C);

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
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(Icons.query_stats_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Match Results', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 24),

          // ── Donut chart ──
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _DonutPainter(
                wins: _wins,
                losses: _losses,
                draws: _draws,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_total',
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    Text(
                      'Games',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Legend ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(_winColor, '${_wins}W'),
              const SizedBox(width: 20),
              _legendDot(_lossColor, '${_losses}L'),
              const SizedBox(width: 20),
              _legendDot(_drawColor, '${_draws}D'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int wins;
  final int losses;
  final int draws;

  _DonutPainter({required this.wins, required this.losses, required this.draws});

  @override
  void paint(Canvas canvas, Size size) {
    final total = wins + losses + draws;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;
    const gapAngle = 0.04; // small gap between segments

    final segments = [
      _Segment(wins / total, const Color(0xFF43A047)),
      _Segment(losses / total, const Color(0xFFE53935)),
      _Segment(draws / total, const Color(0xFF78909C)),
    ];

    var startAngle = -pi / 2;

    for (final seg in segments) {
      final sweepAngle = seg.fraction * 2 * pi - gapAngle;
      final paint = Paint()
        ..color = seg.color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += seg.fraction * 2 * pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.wins != wins || old.losses != losses || old.draws != draws;
}

class _Segment {
  final double fraction;
  final Color color;
  const _Segment(this.fraction, this.color);
}
