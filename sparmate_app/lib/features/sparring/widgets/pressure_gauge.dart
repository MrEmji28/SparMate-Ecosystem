import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Real-Time Pressure Gauge Widget (Milestone 2, Objective 2)
///
/// Displays a visual "blunder risk" indicator during live sparring.
/// Uses Deterministic Risk Metrics (piece tension, king safety,
/// time-pressure indicators) to calculate and visualize the
/// player's real-time risk of blundering.
///
/// The gauge shows a 0–100% risk value with color-coded zones:
///   🟢 0-30%  — Safe (low blunder risk)
///   🟡 30-60% — Caution (moderate risk, increasing tension)
///   🔴 60-100% — Danger (high blunder risk, likely to err)
class PressureGauge extends StatefulWidget {
  /// Pressure value from 0.0 (safe) to 1.0 (extreme danger).
  final double pressure;

  /// Label to display below the gauge (e.g., "Blunder Risk").
  final String label;

  /// Size of the gauge widget.
  final double size;

  /// Whether to show animated transitions.
  final bool animate;

  const PressureGauge({
    super.key,
    required this.pressure,
    this.label = 'Blunder Risk',
    this.size = 120,
    this.animate = true,
  });

  @override
  State<PressureGauge> createState() => _PressureGaugeState();
}

class _PressureGaugeState extends State<PressureGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousPressure = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.pressure).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(PressureGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressure != widget.pressure) {
      _previousPressure = oldWidget.pressure;
      _animation = Tween<double>(
        begin: _previousPressure,
        end: widget.pressure,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = widget.animate ? _animation.value : widget.pressure;
        return _buildGauge(context, value.clamp(0.0, 1.0));
      },
    );
  }

  Widget _buildGauge(BuildContext context, double value) {
    final percentage = (value * 100).toInt();
    final color = _getColor(value);
    final zone = _getZoneLabel(value);

    return Container(
      width: widget.size + 32,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gauge Arc ──
          SizedBox(
            width: widget.size,
            height: widget.size * 0.65,
            child: CustomPaint(
              painter: _GaugeArcPainter(
                value: value,
                color: color,
                trackColor: AppColors.border.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: widget.size * 0.15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: widget.size * 0.22,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          zone,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Label ──
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double value) {
    if (value <= 0.30) {
      // Green zone: safe
      return const Color(0xFF10B981); // emerald-500
    } else if (value <= 0.60) {
      // Yellow zone: caution — interpolate green → amber
      final t = (value - 0.30) / 0.30;
      return Color.lerp(
        const Color(0xFF10B981),
        const Color(0xFFF59E0B),
        t,
      )!;
    } else {
      // Red zone: danger — interpolate amber → red
      final t = (value - 0.60) / 0.40;
      return Color.lerp(
        const Color(0xFFF59E0B),
        const Color(0xFFEF4444),
        t,
      )!;
    }
  }

  String _getZoneLabel(double value) {
    if (value <= 0.30) return 'SAFE';
    if (value <= 0.60) return 'CAUTION';
    return 'DANGER';
  }
}

/// Custom painter that draws the semi-circular gauge arc.
class _GaugeArcPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  _GaugeArcPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    const strokeWidth = 10.0;

    // ── Track (background arc) ──
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // ── Value arc (foreground) ──
    if (value > 0) {
      final valuePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            const Color(0xFF10B981), // green
            const Color(0xFFF59E0B), // amber
            const Color(0xFFEF4444), // red
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * value,
        false,
        valuePaint,
      );

      // ── Needle dot ──
      final needleAngle = startAngle + sweepAngle * value;
      final needleX = center.dx + radius * math.cos(needleAngle);
      final needleY = center.dy + radius * math.sin(needleAngle);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(needleX, needleY), 6, dotPaint);

      final dotGlow = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(needleX, needleY), 10, dotGlow);
    }
  }

  @override
  bool shouldRepaint(_GaugeArcPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

/// Calculates the pressure value from chess position metrics.
///
/// Uses the same risk features from `feature_engineering.py`:
/// - pieces_en_prise (0-5): Number of undefended pieces
/// - king_exposure (0-1): How exposed the king is
/// - time_remaining_pct (0-1): Percentage of clock remaining
/// - material_deficit (-15 to 15): Material balance
/// - fork_potential (0-1): Risk of tactical forks
///
/// Returns a value from 0.0 (safe) to 1.0 (extreme danger).
double calculatePressure({
  int piecesEnPrise = 0,
  double kingExposure = 0.0,
  double timeRemainingPct = 1.0,
  double materialDeficit = 0.0,
  double forkPotential = 0.0,
}) {
  // Weighted combination of risk factors
  double pressure = 0.0;

  // Pieces en prise: 0-5 pieces → 0.0-0.35
  pressure += (piecesEnPrise.clamp(0, 5) / 5.0) * 0.35;

  // King exposure: direct mapping → 0.0-0.25
  pressure += kingExposure.clamp(0.0, 1.0) * 0.25;

  // Time pressure: low time = high pressure → 0.0-0.20
  pressure += (1.0 - timeRemainingPct.clamp(0.0, 1.0)) * 0.20;

  // Material deficit: losing material = pressure → 0.0-0.10
  final deficitNormalized = (materialDeficit.clamp(-10, 0).abs() / 10.0);
  pressure += deficitNormalized * 0.10;

  // Fork potential → 0.0-0.10
  pressure += forkPotential.clamp(0.0, 1.0) * 0.10;

  return pressure.clamp(0.0, 1.0);
}
