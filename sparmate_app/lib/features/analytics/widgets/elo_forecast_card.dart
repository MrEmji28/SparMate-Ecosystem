import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// ELO Forecast card — AI-powered 14-day rating prediction.
///
/// Shows a friendly interpretation of the Linear Regression output from
/// the FastAPI ML microservice. Designed for chess players, not data scientists.
class EloForecastCard extends StatelessWidget {
  final Map<String, dynamic>? forecastData;
  final int currentElo;

  const EloForecastCard({
    super.key,
    this.forecastData,
    this.currentElo = 1200,
  });

  // ── Parsed values ─────────────────────────────────────────────────

  String get _trend => forecastData?['trend'] as String? ?? 'stable';
  int get _projectedElo =>
      (forecastData?['projected_elo'] as num?)?.toInt() ?? currentElo;
  double get _slope =>
      (forecastData?['slope'] as num?)?.toDouble() ?? 0.0;
  double get _r2 =>
      (forecastData?['r2_score'] as num?)?.toDouble() ?? 0.0;

  List<int> get _predicted => _parseIntList(forecastData?['predicted_ratings']);
  List<int> get _lower => _parseIntList(forecastData?['lower_bound']);
  List<int> get _upper => _parseIntList(forecastData?['upper_bound']);

  List<int> _parseIntList(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => (e as num).toInt()).toList();
    }
    return List.generate(14, (_) => currentElo);
  }

  // ── User-friendly labels ──────────────────────────────────────────

  Color get _trendColor => switch (_trend) {
        'improving' => AppColors.successGreen,
        'declining' => AppColors.liveRed,
        _ => const Color(0xFF6B7A99),
      };

  IconData get _trendIcon => switch (_trend) {
        'improving' => Icons.trending_up_rounded,
        'declining' => Icons.trending_down_rounded,
        _ => Icons.trending_flat_rounded,
      };

  String get _trendLabel => switch (_trend) {
        'improving' => 'On the Rise 🚀',
        'declining' => 'Needs Focus 📉',
        _ => 'Holding Steady',
      };

  /// Convert slope to plain English
  String get _progressLabel {
    if (_slope > 3) return 'Fast growth';
    if (_slope > 1.5) return 'Improving';
    if (_slope < -3) return 'Dropping fast';
    if (_slope < -1.5) return 'Declining';
    return 'Stable';
  }

  /// Confidence label based on R²
  String get _confidenceLabel {
    if (_r2 >= 0.85) return 'High';
    if (_r2 >= 0.6) return 'Medium';
    return 'Low';
  }

  Color get _confidenceColor {
    if (_r2 >= 0.85) return AppColors.successGreen;
    if (_r2 >= 0.6) return const Color(0xFFF59E0B);
    return AppColors.liveRed;
  }

  int get _eloDelta => _projectedElo - currentElo;
  bool get _hasEnoughData => forecastData != null;

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
          // ── Header ──────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_graph_rounded,
                    size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rating Forecast',
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Where your ELO is headed in 14 days',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.textLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Trend pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_trendIcon, size: 13, color: _trendColor),
                    const SizedBox(width: 4),
                    Text(
                      _trendLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── 3-stat row (compact, no wrapping) ───────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                _statBox(
                  context,
                  label: 'In 14 Days',
                  value: '$_projectedElo',
                  sub: '${_eloDelta >= 0 ? '+' : ''}$_eloDelta ELO',
                  subColor: _trendColor,
                ),
                _divider(),
                _statBox(
                  context,
                  label: 'Trend',
                  value: _progressLabel,
                  sub: '${_slope >= 0 ? '+' : ''}${_slope.toStringAsFixed(1)}/game',
                  subColor: AppColors.textLight,
                ),
                _divider(),
                _statBox(
                  context,
                  label: 'Confidence',
                  value: _confidenceLabel,
                  sub: '${(_r2 * 100).toStringAsFixed(0)}% fit',
                  subColor: _confidenceColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Chart ────────────────────────────────────────────────
          if (_hasEnoughData)
            SizedBox(
              height: 110,
              width: double.infinity,
              child: CustomPaint(
                painter: _ForecastPainter(
                  predicted: _predicted,
                  lower: _lower,
                  upper: _upper,
                  currentElo: currentElo,
                  trendColor: _trendColor,
                ),
              ),
            )
          else
            _emptyChart(context),

          const SizedBox(height: 12),

          // ── Legend / footer ──────────────────────────────────────
          Row(
            children: [
              _legendDash(AppColors.primaryBlue, 'Predicted path'),
              const SizedBox(width: 14),
              _legendDash(AppColors.primaryBlue.withValues(alpha: 0.2),
                  'Confidence range'),
              const Spacer(),
              Text(
                'AI-powered · updates after each game',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────

  Widget _statBox(
    BuildContext context, {
    required String label,
    required String value,
    required String sub,
    required Color subColor,
  }) {
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: tt.bodySmall?.copyWith(
                  color: AppColors.textLight, fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: subColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 0.5,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: AppColors.border,
      );

  Widget _legendDash(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Text(label,
              style:
                  TextStyle(fontSize: 10, color: AppColors.textLight)),
        ],
      );

  Widget _emptyChart(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          'Play more games to unlock your forecast 🎯',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textLight,
                fontSize: 12,
              ),
        ),
      ),
    );
  }
}

// ── Custom Painter ──────────────────────────────────────────────────────

class _ForecastPainter extends CustomPainter {
  final List<int> predicted;
  final List<int> lower;
  final List<int> upper;
  final int currentElo;
  final Color trendColor;

  const _ForecastPainter({
    required this.predicted,
    required this.lower,
    required this.upper,
    required this.currentElo,
    required this.trendColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (predicted.isEmpty) return;

    // Always enforce a minimum visible range so the chart never looks flat
    final allValues = [currentElo, ...predicted, ...lower, ...upper];
    var minY = allValues.reduce(min).toDouble();
    var maxY = allValues.reduce(max).toDouble();
    if ((maxY - minY) < 30) {
      final mid = (minY + maxY) / 2;
      minY = mid - 20;
      maxY = mid + 20;
    }
    final range = maxY - minY;

    const leftPad = 40.0;
    final right = size.width;
    const top = 4.0;
    final bottom = size.height - 4;
    final chartW = right - leftPad;
    final chartH = bottom - top;

    double toX(int i) => leftPad + (i / (predicted.length)) * chartW;
    double toY(double v) => bottom - ((v - minY) / range) * chartH;

    // ── Y-axis labels (3 ticks) ──
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;

    for (final v in [minY, (minY + maxY) / 2, maxY]) {
      final y = toY(v);
      canvas.drawLine(Offset(leftPad, y), Offset(right, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: v.round().toString(),
          style: const TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // ── Confidence band ──
    if (lower.length == upper.length && upper.isNotEmpty) {
      final bandPath = Path();
      bandPath.moveTo(toX(0), toY(upper[0].toDouble()));
      for (var i = 1; i < upper.length; i++) {
        bandPath.lineTo(toX(i), toY(upper[i].toDouble()));
      }
      for (var i = lower.length - 1; i >= 0; i--) {
        bandPath.lineTo(toX(i), toY(lower[i].toDouble()));
      }
      bandPath.close();
      canvas.drawPath(
        bandPath,
        Paint()..color = trendColor.withValues(alpha: 0.1),
      );
    }

    // ── Dashed forecast line ──
    final path = Path();
    path.moveTo(leftPad, toY(currentElo.toDouble())); // anchor at current ELO
    for (var i = 0; i < predicted.length; i++) {
      path.lineTo(toX(i), toY(predicted[i].toDouble()));
    }

    final linePaint = Paint()
      ..color = trendColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dashes
    const dashLen = 7.0;
    const gapLen = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final next = (dist + (draw ? dashLen : gapLen))
            .clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(metric.extractPath(dist, next), linePaint);
        }
        dist = next;
        draw = !draw;
      }
    }

    // ── End dot ──
    final lastX = toX(predicted.length - 1);
    final lastY = toY(predicted.last.toDouble());
    canvas.drawCircle(
        Offset(lastX, lastY), 5.5, Paint()..color = trendColor);
    canvas.drawCircle(
        Offset(lastX, lastY), 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ForecastPainter old) =>
      old.predicted != predicted || old.currentElo != currentElo;
}
