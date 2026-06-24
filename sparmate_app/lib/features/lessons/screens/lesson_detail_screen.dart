import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/lesson_progress_header.dart';
import '../widgets/chapter_list_card.dart';
import '../widgets/lesson_content_card.dart';

/// Lesson detail screen — accepts dynamic lesson data and provides
/// interactive chapter navigation and content viewing.
class LessonDetailScreen extends StatefulWidget {
  final String title;
  final String category;
  final String chapters;
  final double progress;
  final Color color;
  final IconData icon;
  final String description;
  final double rating;
  final String timeLeft;

  const LessonDetailScreen({
    super.key,
    this.title = 'Sicilian Defense',
    this.category = 'Opening',
    this.chapters = '12 Chapters',
    this.progress = 0.65,
    this.color = const Color(0xFF3949AB),
    this.icon = Icons.shield_rounded,
    this.description = 'Master the most popular chess opening. Learn key variations, traps, and positional ideas.',
    this.rating = 4.8,
    this.timeLeft = '~45 min left',
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedChapterIndex = -1; // -1 means show overview
  final Set<int> _completedChapters = {};
  late int _totalChapters;
  late int _initialCompleted;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    // Parse chapter count from string like "12 Chapters"
    _totalChapters = int.tryParse(
            widget.chapters.replaceAll(RegExp(r'[^0-9]'), '')) ??
        12;

    // Calculate how many chapters are "completed" based on progress
    _initialCompleted = (widget.progress * _totalChapters).floor();
    for (var i = 0; i < _initialCompleted; i++) {
      _completedChapters.add(i);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get _currentProgress =>
      _completedChapters.length / _totalChapters;

  void _onChapterTap(int index) {
    setState(() {
      _selectedChapterIndex = index;
    });
  }

  void _onChapterComplete(int index) {
    setState(() {
      _completedChapters.add(index);
      // Auto-advance to next chapter
      if (index + 1 < _totalChapters) {
        _selectedChapterIndex = index + 1;
      } else {
        _selectedChapterIndex = -1; // Back to overview
      }
    });

    // Show completion snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chapter ${index + 1} completed! 🎉'),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onBackToOverview() {
    setState(() => _selectedChapterIndex = -1);
  }

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
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_selectedChapterIndex >= 0) {
                          _onBackToOverview();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.primaryNavy),
                      splashRadius: 22,
                    ),
                    Expanded(
                      child: Text(
                        _selectedChapterIndex >= 0
                            ? 'Chapter ${_selectedChapterIndex + 1}'
                            : widget.title,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                          fontSize: 22,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Progress badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(_currentProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _selectedChapterIndex >= 0
                      ? _buildChapterContent()
                      : _buildOverview(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Overview layout: header + current chapter preview + chapter list
  List<Widget> _buildOverview() {
    return [
      FadeTransition(
        opacity: _animController,
        child: LessonProgressHeader(
          title: widget.title,
          description: widget.description,
          progress: _currentProgress,
          chapters: widget.chapters,
          rating: widget.rating,
          timeLeft: widget.timeLeft,
          color: widget.color,
          icon: widget.icon,
        ),
      ),
      const SizedBox(height: 16),
      LessonContentCard(
        title: widget.title,
        chapterIndex: _getNextChapterIndex(),
        totalChapters: _totalChapters,
        color: widget.color,
        onContinue: () => _onChapterTap(_getNextChapterIndex()),
      ),
      const SizedBox(height: 16),
      ChapterListCard(
        totalChapters: _totalChapters,
        completedChapters: _completedChapters,
        color: widget.color,
        onChapterTap: _onChapterTap,
      ),
    ];
  }

  /// Chapter content layout: full chapter reading experience
  List<Widget> _buildChapterContent() {
    final chapterIndex = _selectedChapterIndex;
    final isCompleted = _completedChapters.contains(chapterIndex);
    final chapterTitle = _getChapterTitle(chapterIndex);

    return [
      // Chapter header
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color,
              widget.color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CHAPTER ${chapterIndex + 1} OF $_totalChapters',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const Spacer(),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('COMPLETED',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              chapterTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            // Reading time
            Row(
              children: [
                Icon(Icons.timer_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7)),
                const SizedBox(width: 5),
                Text(
                  '${5 + (chapterIndex % 8)} min read',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Chapter content body
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lesson Content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ..._getChapterContent(chapterIndex),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Key takeaways card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: widget.color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded,
                    size: 18, color: widget.color),
                const SizedBox(width: 8),
                Text('Key Takeaways',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 14),
            _takeaway('Remember to control the center squares'),
            const SizedBox(height: 8),
            _takeaway('Develop pieces before launching an attack'),
            const SizedBox(height: 8),
            _takeaway('King safety is paramount in sharp positions'),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Navigation buttons
      Row(
        children: [
          // Previous chapter
          if (chapterIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _onChapterTap(chapterIndex - 1),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMedium,
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (chapterIndex > 0) const SizedBox(width: 12),

          // Complete / Next chapter
          Expanded(
            flex: chapterIndex > 0 ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: isCompleted
                  ? (chapterIndex + 1 < _totalChapters
                      ? () => _onChapterTap(chapterIndex + 1)
                      : _onBackToOverview)
                  : () => _onChapterComplete(chapterIndex),
              icon: Icon(
                isCompleted
                    ? (chapterIndex + 1 < _totalChapters
                        ? Icons.arrow_forward_rounded
                        : Icons.done_all_rounded)
                    : Icons.check_rounded,
                size: 18,
              ),
              label: Text(isCompleted
                  ? (chapterIndex + 1 < _totalChapters
                      ? 'Next Chapter'
                      : 'Back to Overview')
                  : 'Mark Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCompleted ? widget.color : AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _takeaway(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 16, color: widget.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  int _getNextChapterIndex() {
    for (var i = 0; i < _totalChapters; i++) {
      if (!_completedChapters.contains(i)) return i;
    }
    return _totalChapters - 1;
  }

  String _getChapterTitle(int index) {
    const titles = [
      'Introduction & Overview',
      'Core Principles',
      'Key Variations',
      'Tactical Patterns',
      'Positional Ideas',
      'Strategic Plans',
      'Common Mistakes',
      'Pawn Structures & Plans',
      'Typical Middlegame Ideas',
      'Endgame Transitions',
      'Common Traps & Pitfalls',
      'Putting It All Together',
    ];
    return index < titles.length ? titles[index] : 'Chapter ${index + 1}';
  }

  List<Widget> _getChapterContent(int index) {
    // Generate realistic lesson content paragraphs
    final paragraphs = [
      'This chapter covers the essential concepts you need to master. Understanding these fundamentals will form the foundation for everything that follows in your chess study.',
      'Pay close attention to the pawn structures that arise from these positions. The pawn structure determines the character of the position and guides your strategic decisions.',
      'Notice how piece placement is closely tied to the pawn structure. Knights are typically strongest when placed on outposts supported by pawns, while bishops need open diagonals to exert their influence.',
      'In practice, you\'ll encounter these patterns frequently. The key is to recognize the underlying themes and apply the correct strategic plan. Don\'t try to memorize specific moves — understand the ideas behind them.',
    ];

    return [
      for (var i = 0; i < paragraphs.length; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        Text(
          paragraphs[i],
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
            height: 1.7,
          ),
        ),
      ],
    ];
  }
}
