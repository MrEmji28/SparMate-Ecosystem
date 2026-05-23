import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/grandmaster.dart';

/// GM profile header showing avatar, name, style, quote, and strengths.
class GmProfileCard extends StatelessWidget {
  final Grandmaster gm;
  const GmProfileCard({super.key, required this.gm});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gm.color.withValues(alpha: 0.9),
            gm.color.withValues(alpha: 0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: gm.color.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + Info ──
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.5),
                  ),
                  child: Icon(gm.icon, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(gm.title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.8)),
                          ),
                          const SizedBox(width: 8),
                          Text(gm.nationality, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gm.fullName,
                        style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 22),
                      ),
                      Text(gm.style, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.75))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Quote ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                gm.quote,
                style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: Colors.white.withValues(alpha: 0.85), height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // ── Era + Rating ──
            Row(
              children: [
                _infoPill(Icons.calendar_today_rounded, gm.era),
                const SizedBox(width: 10),
                _infoPill(Icons.bar_chart_rounded, 'ELO ${gm.eloRating}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}
