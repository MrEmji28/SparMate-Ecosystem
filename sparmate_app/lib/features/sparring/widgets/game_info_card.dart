import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/grandmaster.dart';

/// Card showing GM strengths, preferred openings, and difficulty selector.
class GameInfoCard extends StatefulWidget {
  final Grandmaster gm;
  const GameInfoCard({super.key, required this.gm});

  @override
  State<GameInfoCard> createState() => _GameInfoCardState();
}

class _GameInfoCardState extends State<GameInfoCard> {
  int _selectedDifficulty = 1; // 0=Easy, 1=Medium, 2=Hard

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final gm = widget.gm;

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
          // ── About this AI ──
          Row(
            children: [
              Icon(Icons.psychology_rounded, size: 20, color: gm.color),
              const SizedBox(width: 8),
              Text('AI Persona', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            gm.styleDescription,
            style: tt.bodyMedium?.copyWith(color: AppColors.textMedium, height: 1.5),
          ),
          const SizedBox(height: 18),

          // ── Strengths ──
          Text('STRENGTHS', style: tt.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textLight)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gm.strengths.map((s) => _chip(s, gm.color)).toList(),
          ),
          const SizedBox(height: 18),

          // ── Preferred Openings ──
          Text('PREFERRED OPENINGS', style: tt.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textLight)),
          const SizedBox(height: 10),
          ...gm.openings.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.chevron_right_rounded, size: 16, color: gm.color),
                const SizedBox(width: 6),
                Text(o, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.textDark)),
              ],
            ),
          )),
          const SizedBox(height: 18),

          // ── Difficulty ──
          Text('DIFFICULTY', style: tt.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.textLight)),
          const SizedBox(height: 10),
          Row(
            children: [
              _difficultyBtn(0, 'Easy', Colors.green),
              const SizedBox(width: 8),
              _difficultyBtn(1, 'Medium', Colors.orange),
              const SizedBox(width: 8),
              _difficultyBtn(2, 'Hard', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _difficultyBtn(int level, String label, Color color) {
    final isSelected = _selectedDifficulty == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDifficulty = level),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : AppColors.border, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
