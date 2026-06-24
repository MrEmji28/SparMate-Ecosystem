import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../screens/lesson_detail_screen.dart';

/// Full Lessons tab screen with search, category filtering, active lesson,
/// recommended carousel, and a complete tappable lesson catalog.
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCategory = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  static const _categories = [
    _Cat('All', Icons.grid_view_rounded),
    _Cat('Opening', Icons.door_front_door_rounded),
    _Cat('Middlegame', Icons.swap_horiz_rounded),
    _Cat('Endgame', Icons.flag_rounded),
    _Cat('Tactics', Icons.bolt_rounded),
    _Cat('Strategy', Icons.psychology_rounded),
  ];

  static const _allLessons = [
    _LessonData('Sicilian Defense', 'Opening', '12 Chapters', 0.0,
        Color(0xFF3949AB), Icons.shield_rounded,
        desc: 'Master the most popular chess opening. Learn key variations, traps, and positional ideas.',
        rating: 4.8, timeLeft: '~45 min left'),
    _LessonData('Italian Game', 'Opening', '8 Chapters', 0.0,
        Color(0xFF1565C0), Icons.door_front_door_rounded,
        desc: 'A classical opening leading to open, tactical positions. Perfect for aggressive players.',
        rating: 4.6, timeLeft: '~35 min'),
    _LessonData("Queen's Gambit", 'Opening', '10 Chapters', 0.0,
        Color(0xFF6A1B9A), Icons.door_front_door_rounded,
        desc: 'Learn the strategic depths of 1.d4 d5 2.c4 and how to gain a lasting advantage.',
        rating: 4.7, timeLeft: '~50 min'),
    _LessonData('Rook Endgames', 'Endgame', '12 Chapters', 0.0,
        Color(0xFF00838F), Icons.castle_rounded,
        desc: 'Rook endgames occur in over 50% of games. Master Lucena, Philidor, and key techniques.',
        rating: 4.9, timeLeft: '~55 min'),
    _LessonData('Pawn Structure Mastery', 'Strategy', '9 Chapters', 0.0,
        Color(0xFF2E7D32), Icons.psychology_rounded,
        desc: 'Understand pawn chains, isolated pawns, hanging pawns and how they shape your plans.',
        rating: 4.5, timeLeft: '~40 min'),
    _LessonData('Discovered Attacks', 'Tactics', '6 Chapters', 0.0,
        Color(0xFFE53935), Icons.bolt_rounded,
        desc: 'One of the most powerful tactical motifs. Learn to set up and execute discovered attacks.',
        rating: 4.7, timeLeft: '~25 min'),
    _LessonData('King & Pawn Endings', 'Endgame', '7 Chapters', 0.0,
        Color(0xFF00695C), Icons.flag_rounded,
        desc: 'The foundation of all endgames. Master opposition, key squares, and pawn races.',
        rating: 4.8, timeLeft: '~30 min'),
    _LessonData('Middlegame Planning', 'Middlegame', '11 Chapters', 0.0,
        Color(0xFFEF6C00), Icons.swap_horiz_rounded,
        desc: 'Learn to create plans, identify weaknesses, and coordinate your pieces in the middlegame.',
        rating: 4.6, timeLeft: '~48 min'),
    _LessonData('Pin & Fork Tactics', 'Tactics', '8 Chapters', 0.0,
        Color(0xFFC62828), Icons.bolt_rounded,
        desc: 'Master the two most common tactical motifs that win material in every game.',
        rating: 4.8, timeLeft: '~32 min'),
    _LessonData('Exchange Sacrifice', 'Strategy', '5 Chapters', 0.0,
        Color(0xFF4527A0), Icons.psychology_rounded,
        desc: 'Petrosian\u2019s trademark. Learn when giving up the exchange leads to a winning advantage.',
        rating: 4.4, timeLeft: '~22 min'),
  ];

  List<_LessonData> get _filteredLessons {
    var lessons = _allLessons.toList();

    // Filter by category
    if (_selectedCategory > 0) {
      final catLabel = _categories[_selectedCategory].label;
      lessons = lessons.where((l) => l.category == catLabel).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      lessons = lessons
          .where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.category.toLowerCase().contains(q))
          .toList();
    }

    return lessons;
  }

  _LessonData? get _activeLesson {
    try {
      return _allLessons.firstWhere((l) => l.progress > 0);
    } catch (_) {
      return null;
    }
  }

  void _openLesson(BuildContext context, _LessonData lesson) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(
          title: lesson.title,
          category: lesson.category,
          chapters: lesson.chapters,
          progress: lesson.progress,
          color: lesson.color,
          icon: lesson.icon,
          description: lesson.desc,
          rating: lesson.rating,
          timeLeft: lesson.timeLeft,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final active = _activeLesson;
    final filtered = _filteredLessons;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.primaryNavy),
                      splashRadius: 22,
                    ),
                    const SizedBox(width: 4),
                    Text('Lessons',
                        style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                            fontSize: 22)),
                    const Spacer(),
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          AppColors.primaryBlue,
                          AppColors.primaryLight
                        ]),
                        border:
                            Border.all(color: AppColors.border, width: 2),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar (functional) ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textLight),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search lessons...',
                            hintStyle: TextStyle(
                                color: AppColors.textLight, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textDark),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _searchFocus.unfocus();
                          },
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textLight),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Categories (functional filter) ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 0, 0),
              sliver: SliverToBoxAdapter(child: _buildCategoriesRow()),
            ),

            // ── Continue Learning (only if active lesson) ──
            if (active != null && _searchQuery.isEmpty && _selectedCategory == 0) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Text('Continue Learning',
                      style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _ActiveLessonTile(
                    lesson: active,
                    onTap: () => _openLesson(context, active),
                  ),
                ),
              ),
            ],

            // ── Recommended (only when not searching or filtering) ──
            if (_searchQuery.isEmpty && _selectedCategory == 0) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Text('Recommended for You',
                          style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          // Scroll to all lessons section
                        },
                        child: Text('See All',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildRecommendedRow(context),
                ),
              ),
            ],

            // ── Results Header ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Search Results'
                          : _selectedCategory > 0
                              ? _categories[_selectedCategory].label
                              : 'All Lessons',
                      style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${filtered.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Lessons List ──
            if (filtered.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: _buildEmptyState(tt),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LessonListTile(
                        lesson: filtered[i],
                        onTap: () => _openLesson(context, filtered[i]),
                      ),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesRow() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final isActive = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryNavy : AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        isActive ? AppColors.primaryNavy : AppColors.border,
                    width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(cat.icon,
                      size: 16,
                      color:
                          isActive ? Colors.white : AppColors.textLight),
                  const SizedBox(width: 6),
                  Text(cat.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : AppColors.textMedium)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendedRow(BuildContext context) {
    // Pick lessons with no progress as recommendations
    final recommended = _allLessons
        .where((l) => l.progress == 0)
        .take(4)
        .toList();

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recommended.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        padding: const EdgeInsets.only(right: 16),
        itemBuilder: (_, i) {
          final item = recommended[i];
          return GestureDetector(
            onTap: () => _openLesson(context, item),
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withValues(alpha: 0.85),
                    item.color.withValues(alpha: 0.6)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: item.color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item.category,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.6)),
                  ),
                  const SizedBox(height: 6),
                  Text(item.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(item.chapters,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('No lessons found',
              style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term.'
                : 'No lessons available in this category yet.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium
                ?.copyWith(color: AppColors.textLight, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategory = 0;
              });
            },
            child: Text('Clear Filters',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class _Cat {
  final String label;
  final IconData icon;
  const _Cat(this.label, this.icon);
}

class _LessonData {
  final String title;
  final String category;
  final String chapters;
  final double progress;
  final Color color;
  final IconData icon;
  final String desc;
  final double rating;
  final String timeLeft;
  const _LessonData(
    this.title,
    this.category,
    this.chapters,
    this.progress,
    this.color,
    this.icon, {
    this.desc = '',
    this.rating = 4.5,
    this.timeLeft = '~30 min',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Active lesson tile (with progress and play button)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveLessonTile extends StatelessWidget {
  final _LessonData lesson;
  final VoidCallback onTap;

  const _ActiveLessonTile({required this.lesson, required this.onTap});

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
          border: Border.all(
              color: lesson.color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: lesson.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(lesson.icon, size: 24, color: lesson.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title,
                      style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                      'Chapter ${((lesson.progress * 12).toInt())}: In Progress',
                      style: tt.bodySmall?.copyWith(
                          color: AppColors.textLight, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: lesson.progress,
                            minHeight: 5,
                            backgroundColor: AppColors.progressTrack,
                            valueColor:
                                AlwaysStoppedAnimation(lesson.color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${(lesson.progress * 100).toInt()}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: lesson.color)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.play_circle_filled_rounded,
                size: 32, color: lesson.color),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lesson list tile (tappable)
// ─────────────────────────────────────────────────────────────────────────────

class _LessonListTile extends StatelessWidget {
  final _LessonData lesson;
  final VoidCallback onTap;

  const _LessonListTile({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasProgress = lesson.progress > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Text(lesson.title,
                      style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          fontSize: 13.5)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: lesson.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(lesson.category,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: lesson.color)),
                      ),
                      const SizedBox(width: 8),
                      Text(lesson.chapters,
                          style: tt.bodySmall?.copyWith(
                              color: AppColors.textLight, fontSize: 11)),
                      const SizedBox(width: 8),
                      Icon(Icons.star_rounded,
                          size: 12, color: AppColors.starFilled),
                      const SizedBox(width: 2),
                      Text(lesson.rating.toString(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight)),
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
                        valueColor:
                            AlwaysStoppedAnimation(lesson.color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            hasProgress
                ? Text('${(lesson.progress * 100).toInt()}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: lesson.color))
                : Icon(Icons.chevron_right_rounded,
                    size: 22, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
