import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Rating Overview card with current rating, trend badge, and a 30-day line chart.
/// Accepts optional [ratingData] from the analytics API.
///
/// ratingData shape (from Laravel AnalyticsController):
/// {
///   "current": 1200,
///   "highest": 1240,
///   "history": [ { "date": "2025-06-01", "rating": 1180 }, ... ]
/// }
class RatingOverviewCard extends StatelessWidget {
  final Map<String, dynamic>? ratingData;

  const RatingOverviewCard({super.key, this.ratingData});

  // ── Parse live history or fall back to demo data ──────────────────

  List<int> get _ratings {
    final history = ratingData?['history'];
    if (history is List && history.isNotEmpty) {
      return history
          .map((h) => (h['rating'] as num?)?.toInt() ?? 1200)
          .toList();
    }
    // Demo fallback
    return const [
      1180, 1183, 1178, 1181, 1186, 1184, 1188, 1190, 1187, 1193,
      1191, 1196, 1194, 1198, 1197, 1200, 1196, 1203, 1201, 1206,
      1204, 1208, 1206, 1210, 1208, 1211, 1213, 1216, 1214, 1213,
    ];
  }

  int get _currentRating => (ratingData?['current'] as num?)?.toInt() ?? _ratings.last;
  int get _highestRating => (ratingData?['highest'] as num?)?.toInt() ?? _ratings.reduce((a, b) => a > b ? a : b);

  int get _trend {
    final h = _ratings;
    if (h.length < 2) return 0;
    return h.last - h.first;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final trend = _trend;
    final trendPositive = trend >= 0;
    final trendColor = trendPositive ? AppColors.successGreen : AppColors.liveRed;
    final trendIcon = trendPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    final trendLabel = '${trendPositive ? '+' : ''}$trend';

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
          // ── Header row ──
          Row(
            children: [
              Icon(Icons.monitor_heart_outlined, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rating', style: tt.bodySmall?.copyWith(color: AppColors.textLight)),
                    Text('Overview', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              // Current rating
              Text(
                '$_currentRating',
                style: tt.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Trend badge
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Highest rating chip
              Text(
                'Peak $_highestRating',
                style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 11),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 14, color: trendColor),
                    const SizedBox(width: 3),
                    Text(
                      trendLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── "Last 30 Days" label ──
          Text(
            ratingData != null ? 'Your ELO History' : 'Last 30 Days (demo)',
            style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // ── Chart ──
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(painter: _RatingChartPainter(ratings: _ratings)),
          ),
        ],
      ),
    );
  }
}

class _RatingChartPainter extends CustomPainter {
  final List<int> ratings;

  const _RatingChartPainter({required this.ratings});

  @override
  void paint(Canvas canvas, Size size) {
    if (ratings.isEmpty) return;

    final minRating = ratings.reduce((a, b) => a < b ? a : b);
    final maxRating = ratings.reduce((a, b) => a > b ? a : b);
    // Add 2% padding to avoid clipping
    final range = (maxRating - minRating).toDouble().clamp(10, double.infinity);

    const chartLeft = 40.0;
    final chartRight = size.width - 8;
    const chartTop = 4.0;
    final chartBottom = size.height - 4;
    final chartW = chartRight - chartLeft;
    final chartH = chartBottom - chartTop;

    // ── Grid lines + Y-axis labels ──
    final gridValues = [minRating, ((minRating + maxRating) / 2).round(), maxRating];
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;

    for (final v in gridValues) {
      final y = chartBottom - ((v - minRating) / range) * chartH;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$v',
          style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // ── Line path ──
    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < ratings.length; i++) {
      final x = chartLeft + (i / (ratings.length - 1)) * chartW;
      final y = chartBottom - ((ratings[i] - minRating) / range) * chartH;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartBottom);
        fillPath.lineTo(x, y);
      } else {
        final prevX = chartLeft + ((i - 1) / (ratings.length - 1)) * chartW;
        final prevY = chartBottom - ((ratings[i - 1] - minRating) / range) * chartH;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    // Fill
    fillPath.lineTo(chartRight, chartBottom);
    fillPath.close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryBlue.withValues(alpha: 0.18),
          AppColors.primaryBlue.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(chartLeft, chartTop, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // End dot
    final lastX = chartRight;
    final lastY = chartBottom - ((ratings.last - minRating) / range) * chartH;
    canvas.drawCircle(Offset(lastX, lastY), 4.5, Paint()..color = AppColors.primaryBlue);
    canvas.drawCircle(Offset(lastX, lastY), 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RatingChartPainter old) => old.ratings != ratings;
}
