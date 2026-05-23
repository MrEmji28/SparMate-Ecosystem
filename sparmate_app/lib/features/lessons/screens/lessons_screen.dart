import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../screens/lesson_detail_screen.dart';

/// Full Lessons tab screen with categories, active lessons, and lesson catalog.
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'SparMate',
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryNavy, fontSize: 22),
                    ),
                    const Spacer(),
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryLight]),
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),

            // ── Page title ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Text('Lessons', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 26, color: AppColors.textDark)),
              ),
            ),

            // ── Search bar ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 20, color: AppColors.textLight),
                      const SizedBox(width: 10),
                      Text('Search lessons...', style: tt.bodyMedium?.copyWith(color: AppColors.textLight)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Categories ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 0, 0),
              sliver: SliverToBoxAdapter(child: _CategoriesRow()),
            ),

            // ── Continue Learning ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text('Continue Learning', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _ActiveLessonTile(
                  title: 'Sicilian Defense',
                  chapter: 'Chapter 8: Pawn Structures',
                  progress: 0.65,
                  icon: Icons.shield_rounded,
                  color: const Color(0xFF3949AB),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LessonDetailScreen()),
                  ),
                ),
              ),
            ),

            // ── Recommended ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text('Recommended for You', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Spacer(),
                    Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
              sliver: SliverToBoxAdapter(child: _RecommendedRow()),
            ),

            // ── All Lessons ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text('All Lessons', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _allLessons.map((l) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LessonListTile(lesson: l),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Categories horizontal scroll
// ────────────────────────────────────────────────────────────────────────────

class _CategoriesRow extends StatefulWidget {
  @override
  State<_CategoriesRow> createState() => _CategoriesRowState();
}

class _CategoriesRowState extends State<_CategoriesRow> {
  int _selected = 0;

  static const _cats = [
    _Cat('All', Icons.grid_view_rounded),
    _Cat('Opening', Icons.door_front_door_rounded),
    _Cat('Middlegame', Icons.swap_horiz_rounded),
    _Cat('Endgame', Icons.flag_rounded),
    _Cat('Tactics', Icons.bolt_rounded),
    _Cat('Strategy', Icons.psychology_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (_, i) {
          final cat = _cats[i];
          final isActive = _selected == i;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryNavy : AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? AppColors.primaryNavy : AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(cat.icon, size: 16, color: isActive ? Colors.white : AppColors.textLight),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.textMedium),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Cat {
  final String label;
  final IconData icon;
  const _Cat(this.label, this.icon);
}

// ────────────────────────────────────────────────────────────────────────────
// Active lesson tile (with progress)
// ────────────────────────────────────────────────────────────────────────────

class _ActiveLessonTile extends StatelessWidget {
  final String title;
  final String chapter;
  final double progress;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActiveLessonTile({
    required this.title,
    required this.chapter,
    required this.progress,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(chapter, style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: AppColors.progressTrack,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.play_circle_filled_rounded, size: 32, color: color),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Recommended horizontal cards
// ────────────────────────────────────────────────────────────────────────────

class _RecommendedRow extends StatelessWidget {
  static const _items = [
    _RecLesson('Rook Endgames', 'Endgame', '12 Chapters', Color(0xFF00838F), Icons.castle_rounded),
    _RecLesson('King\'s Indian', 'Opening', '10 Chapters', Color(0xFF6A1B9A), Icons.door_front_door_rounded),
    _RecLesson('Pin & Fork Tactics', 'Tactics', '8 Chapters', Color(0xFFE53935), Icons.bolt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (_, i) {
          final item = _items[i];
          return Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [item.color.withValues(alpha: 0.85), item.color.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: item.color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, size: 18, color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(item.category, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6)),
                ),
                const SizedBox(height: 6),
                Text(item.title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 3),
                Text(item.chapters, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecLesson {
  final String title;
  final String category;
  final String chapters;
  final Color color;
  final IconData icon;
  const _RecLesson(this.title, this.category, this.chapters, this.color, this.icon);
}

// ────────────────────────────────────────────────────────────────────────────
// All Lessons list
// ────────────────────────────────────────────────────────────────────────────

const _allLessons = [
  _LessonData('Sicilian Defense', 'Opening', '12 Chapters', 0.65, Color(0xFF3949AB), Icons.shield_rounded),
  _LessonData('Italian Game', 'Opening', '8 Chapters', 0.0, Color(0xFF1565C0), Icons.door_front_door_rounded),
  _LessonData('Queen\'s Gambit', 'Opening', '10 Chapters', 0.0, Color(0xFF6A1B9A), Icons.door_front_door_rounded),
  _LessonData('Rook Endgames', 'Endgame', '12 Chapters', 0.0, Color(0xFF00838F), Icons.castle_rounded),
  _LessonData('Pawn Structure Mastery', 'Strategy', '9 Chapters', 0.0, Color(0xFF2E7D32), Icons.psychology_rounded),
  _LessonData('Discovered Attacks', 'Tactics', '6 Chapters', 0.0, Color(0xFFE53935), Icons.bolt_rounded),
  _LessonData('King & Pawn Endings', 'Endgame', '7 Chapters', 0.0, Color(0xFF00695C), Icons.flag_rounded),
  _LessonData('Middlegame Planning', 'Middlegame', '11 Chapters', 0.0, Color(0xFFEF6C00), Icons.swap_horiz_rounded),
];

class _LessonData {
  final String title;
  final String category;
  final String chapters;
  final double progress;
  final Color color;
  final IconData icon;
  const _LessonData(this.title, this.category, this.chapters, this.progress, this.color, this.icon);
}

class _LessonListTile extends StatelessWidget {
  final _LessonData lesson;
  const _LessonListTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasProgress = lesson.progress > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: lesson.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(lesson.icon, size: 20, color: lesson.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 13.5)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: lesson.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(lesson.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lesson.color)),
                    ),
                    const SizedBox(width: 8),
                    Text(lesson.chapters, style: tt.bodySmall?.copyWith(color: AppColors.textLight, fontSize: 11)),
                  ],
                ),
                if (hasProgress) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: lesson.progress,
                      minHeight: 4,
                      backgroundColor: AppColors.progressTrack,
                      valueColor: AlwaysStoppedAnimation(lesson.color),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          hasProgress
              ? Text('${(lesson.progress * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: lesson.color))
              : Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textLight),
        ],
      ),
    );
  }
}
