import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Chapter list card showing all lesson chapters with completion status.
class ChapterListCard extends StatelessWidget {
  const ChapterListCard({super.key});

  static const _chapters = [
    _Chapter('Introduction to the Sicilian', true, '5 min'),
    _Chapter('Open Sicilian: 1.e4 c5 2.Nf3', true, '8 min'),
    _Chapter('The Najdorf Variation', true, '10 min'),
    _Chapter('Dragon Variation', true, '8 min'),
    _Chapter('Scheveningen System', true, '7 min'),
    _Chapter('Sveshnikov Variation', true, '9 min'),
    _Chapter('Accelerated Dragon', true, '6 min'),
    _Chapter('Pawn Structures & Plans', false, '10 min'),
    _Chapter('Typical Middlegame Ideas', false, '12 min'),
    _Chapter('Endgame Transitions', false, '8 min'),
    _Chapter('Common Traps & Pitfalls', false, '7 min'),
    _Chapter('Putting It All Together', false, '15 min'),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    // Count completed
    final completed = _chapters.where((c) => c.done).length;

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
              Icon(Icons.list_rounded, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text('Chapters', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completed/${_chapters.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Chapter rows ──
          ..._chapters.asMap().entries.map((entry) {
            final idx = entry.key;
            final ch = entry.value;
            final isCurrent = !ch.done && (idx == 0 || _chapters[idx - 1].done);
            return _buildChapterRow(context, idx + 1, ch, isCurrent);
          }),
        ],
      ),
    );
  }

  Widget _buildChapterRow(BuildContext context, int num, _Chapter ch, bool isCurrent) {
    final tt = Theme.of(context).textTheme;

    final bgColor = isCurrent
        ? AppColors.primaryBlue.withValues(alpha: 0.06)
        : Colors.transparent;
    final borderColor = isCurrent
        ? AppColors.primaryBlue.withValues(alpha: 0.2)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isCurrent ? 1 : 0),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ch.done
                  ? AppColors.successGreen
                  : isCurrent
                      ? AppColors.primaryBlue
                      : AppColors.progressTrack,
            ),
            child: Center(
              child: ch.done
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : isCurrent
                      ? const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white)
                      : Text(
                          '$num',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ch.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: ch.done || isCurrent ? AppColors.textDark : AppColors.textLight,
                    fontSize: 13,
                  ),
                ),
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Continue this chapter',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          // Duration
          Text(
            ch.duration,
            style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 11),
          ),
          if (isCurrent || !ch.done) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isCurrent ? AppColors.primaryBlue : AppColors.textLight,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chapter {
  final String title;
  final bool done;
  final String duration;
  const _Chapter(this.title, this.done, this.duration);
}
