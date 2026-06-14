import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Rating Overview card with current rating, trend badge, and a 30-day line chart.
/// Accepts optional [ratingData] from the analytics API.
class RatingOverviewCard extends StatelessWidget {
  final Map<String, dynamic>? ratingData;

  const RatingOverviewCard({super.key, this.ratingData});

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
                '${ratingData?['current'] ?? 1845}',
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
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up_rounded, size: 14, color: AppColors.successGreen),
                  const SizedBox(width: 3),
                  Text(
                    '+24',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── "Last 30 Days" label ──
          Text('Last 30 Days', style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          // ── Chart ──
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(painter: _RatingChartPainter()),
          ),
        ],
      ),
    );
  }
}

class _RatingChartPainter extends CustomPainter {
  // Simulated rating data points over 30 days
  static const _ratings = [
    1812, 1815, 1810, 1813, 1818, 1816, 1820, 1822, 1819, 1825,
    1823, 1828, 1826, 1830, 1829, 1832, 1828, 1835, 1833, 1838,
    1836, 1840, 1838, 1842, 1840, 1843, 1845, 1848, 1846, 1845,
  ];

  static const _minRating = 1810;
  static const _maxRating = 1850;

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = 36.0;
    final chartRight = size.width - 8;
    final chartTop = 4.0;
    final chartBottom = size.height - 4;
    final chartW = chartRight - chartLeft;
    final chartH = chartBottom - chartTop;
    final range = (_maxRating - _minRating).toDouble();

    // ── Grid lines + Y-axis labels ──
    final gridValues = [1810, 1830, 1850];
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;

    for (final v in gridValues) {
      final y = chartBottom - ((v - _minRating) / range) * chartH;
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

    for (var i = 0; i < _ratings.length; i++) {
      final x = chartLeft + (i / (_ratings.length - 1)) * chartW;
      final y = chartBottom - ((_ratings[i] - _minRating) / range) * chartH;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartBottom);
        fillPath.lineTo(x, y);
      } else {
        final prevX = chartLeft + ((i - 1) / (_ratings.length - 1)) * chartW;
        final prevY = chartBottom - ((_ratings[i - 1] - _minRating) / range) * chartH;
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
    final lastY = chartBottom - ((_ratings.last - _minRating) / range) * chartH;
    canvas.drawCircle(Offset(lastX, lastY), 4.5, Paint()..color = AppColors.primaryBlue);
    canvas.drawCircle(Offset(lastX, lastY), 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
