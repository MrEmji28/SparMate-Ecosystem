import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../puzzles/screens/puzzles_screen.dart';

/// Tactics card — shows a contextual tactic challenge based on the user's
/// skill level and weakest BKT area. All data driven by backend state.
class TacticsCard extends StatelessWidget {
  const TacticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final state = context.watch<AppState>();

    // Determine skill level and weakest area for tactic difficulty
    final user = state.user;
    final skillLevel = user?['skill_level'] as String? ?? 'beginner';
    final eloRating = (user?['elo_rating'] as num?)?.toInt() ?? 500;

    // Get weakest skill from BKT
    final bktSkills = state.bktMatrix?['skills'] as Map<String, dynamic>?;
    final weakestSkill = _getWeakestSkill(bktSkills);

    // Determine difficulty label and star rating
    final (diffLabel, stars) = _getDifficulty(skillLevel);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          // Mini chess board
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(painter: _MiniBoardPainter()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TACTICS',
                  style: tt.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  weakestSkill ?? 'Practice',
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$diffLabel • ELO $eloRating',
                  style: tt.bodySmall?.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(3, (i) => Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: i < stars ? AppColors.starFilled : AppColors.starEmpty,
                  )),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38, width: 80,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PuzzlesScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('SOLVE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  String? _getWeakestSkill(Map<String, dynamic>? bktSkills) {
    if (bktSkills == null || bktSkills.isEmpty) return null;

    String? weakest;
    double lowest = double.infinity;
    for (final entry in bktSkills.entries) {
      final val = (entry.value is num) ? (entry.value as num).toDouble() : 1.0;
      if (val < lowest) {
        lowest = val;
        weakest = entry.key;
      }
    }

    if (weakest == null) return null;
    // Format: "tactical_oversight" → "Tactical Oversight"
    return weakest
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  (String, int) _getDifficulty(String skillLevel) {
    return switch (skillLevel) {
      'advanced' => ('Advanced Challenge', 3),
      'intermediate' => ('Intermediate Challenge', 2),
      _ => ('Beginner Friendly', 1),
    };
  }
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sq = size.width / 4;
    final light = Paint()..color = const Color(0xFFE8E0D4);
    final dark = Paint()..color = const Color(0xFF8B7D6B);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        canvas.drawRect(Rect.fromLTWH(c * sq, r * sq, sq, sq), (r + c) % 2 == 0 ? light : dark);
      }
    }
    final knightPaint = Paint()..color = const Color(0xFF3D3D3D).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(sq * 2.5, sq * 1.5), sq * 0.35, knightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
