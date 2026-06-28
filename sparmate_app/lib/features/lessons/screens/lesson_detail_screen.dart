import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/lesson_chapters_data.dart';
import '../widgets/lesson_progress_header.dart';
import '../widgets/chapter_list_card.dart';
import '../widgets/lesson_content_card.dart';
import '../widgets/teaching_board.dart';

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
  int _currentStepIndex = 0;
  final Set<int> _completedChapters = {};
  Key _commentaryKey = UniqueKey();
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

    // Show intro popup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showLessonIntroDialog();
    });
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
      _currentStepIndex = 0;
      _commentaryKey = UniqueKey();
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

  /// Chapter content layout: interactive teaching experience
  List<Widget> _buildChapterContent() {
    final chapterIndex = _selectedChapterIndex;
    final isCompleted = _completedChapters.contains(chapterIndex);
    final chapterTitle = _getChapterTitle(chapterIndex);
    final steps = LessonChaptersData.getSteps(widget.title, chapterIndex);
    final totalSteps = steps.length;
    final currentStep = steps[_currentStepIndex.clamp(0, totalSteps - 1)];
    final previousStep = _currentStepIndex > 0 ? steps[_currentStepIndex - 1] : null;
    final isLastStep = _currentStepIndex >= totalSteps - 1;
    final isFirstStep = _currentStepIndex == 0;

    return [
      // ── Chapter header (compact) ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color,
              widget.color.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHAPTER ${chapterIndex + 1} OF $_totalChapters',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapterTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('DONE',
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
      ),
      const SizedBox(height: 14),

      // ── Step progress bar ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.school_rounded, size: 16, color: widget.color),
            const SizedBox(width: 8),
            Text(
              'Step ${_currentStepIndex + 1} of $totalSteps',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStepIndex + 1) / totalSteps,
                  backgroundColor: AppColors.progressTrack,
                  valueColor: AlwaysStoppedAnimation(widget.color),
                  minHeight: 5,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // ── Teaching Board ──
      TeachingBoard(
        key: ValueKey('board_${chapterIndex}_$_currentStepIndex'),
        step: currentStep,
        previousStep: previousStep,
        accentColor: widget.color,
      ),
      const SizedBox(height: 14),

      // ── Concept badge + Commentary ──
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Concept pill
            if (currentStep.concept != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 13, color: widget.color),
                    const SizedBox(width: 5),
                    Text(
                      currentStep.concept!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Instructor commentary with fade animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Text(
                currentStep.commentary,
                key: _commentaryKey,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // ── Step navigation ──
      Row(
        children: [
          // Previous step
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isFirstStep
                  ? null
                  : () {
                      setState(() {
                        _currentStepIndex--;
                        _commentaryKey = UniqueKey();
                      });
                    },
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMedium,
                side: BorderSide(
                  color: isFirstStep
                      ? AppColors.border.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Next step / Mark Complete
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (isLastStep) {
                  // Last step: mark complete or go to next chapter
                  if (!isCompleted) {
                    _onChapterComplete(chapterIndex);
                  } else if (chapterIndex + 1 < _totalChapters) {
                    _onChapterTap(chapterIndex + 1);
                  } else {
                    _onBackToOverview();
                  }
                } else {
                  setState(() {
                    _currentStepIndex++;
                    _commentaryKey = UniqueKey();
                  });
                }
              },
              icon: Icon(
                isLastStep
                    ? (isCompleted
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded)
                    : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(
                isLastStep
                    ? (isCompleted
                        ? (chapterIndex + 1 < _totalChapters
                            ? 'Next Chapter'
                            : 'Finish')
                        : 'Complete ✓')
                    : 'Next Step',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep
                    ? (isCompleted ? widget.color : AppColors.successGreen)
                    : widget.color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
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


  int _getNextChapterIndex() {
    for (var i = 0; i < _totalChapters; i++) {
      if (!_completedChapters.contains(i)) return i;
    }
    return _totalChapters - 1;
  }

  String _getChapterTitle(int index) {
    final titles = LessonChaptersData.getChapterTitles(widget.title);
    return index < titles.length ? titles[index] : 'Chapter ${index + 1}';
  }

  void _showLessonIntroDialog() {
    final nextChapter = _getNextChapterIndex();
    final nextChapterTitle = _getChapterTitle(nextChapter);
    final progressPct = (_currentProgress * 100).round();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, secondAnim) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondAnim, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: _LessonIntroDialogContent(
              title: widget.title,
              description: widget.description,
              color: widget.color,
              icon: widget.icon,
              totalChapters: _totalChapters,
              completedChapters: _completedChapters.length,
              progressPct: progressPct,
              rating: widget.rating,
              timeLeft: widget.timeLeft,
              nextChapterTitle: nextChapterTitle,
              nextChapterIndex: nextChapter,
              onStart: () {
                Navigator.of(ctx).pop();
              },
            ),
          ),
        );
      },
    );
  }
}

/// ── Lesson Intro Dialog ────────────────────────────────────────────────
class _LessonIntroDialogContent extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final int totalChapters;
  final int completedChapters;
  final int progressPct;
  final double rating;
  final String timeLeft;
  final String nextChapterTitle;
  final int nextChapterIndex;
  final VoidCallback onStart;

  const _LessonIntroDialogContent({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.totalChapters,
    required this.completedChapters,
    required this.progressPct,
    required this.rating,
    required this.timeLeft,
    required this.nextChapterTitle,
    required this.nextChapterIndex,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final isStarting = completedChapters == 0;
    final progressColor = progressPct < 30
        ? const Color(0xFFE53935)
        : progressPct < 60
            ? const Color(0xFFFFA000)
            : progressPct < 90
                ? const Color(0xFF1E88E5)
                : const Color(0xFF43A047);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lesson icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                        Icons.menu_book_rounded,
                        '$totalChapters',
                        'Chapters',
                        color,
                      ),
                      Container(
                        width: 1, height: 28,
                        color: AppColors.border,
                      ),
                      _statItem(
                        Icons.star_rounded,
                        '$rating',
                        'Rating',
                        const Color(0xFFFFA000),
                      ),
                      Container(
                        width: 1, height: 28,
                        color: AppColors.border,
                      ),
                      _statItem(
                        Icons.timer_rounded,
                        timeLeft.replaceAll('~', ''),
                        'Remaining',
                        const Color(0xFF43A047),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Progress / Next chapter info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: progressColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            isStarting
                                ? Icons.play_lesson_rounded
                                : Icons.trending_up_rounded,
                            size: 20,
                            color: progressColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isStarting
                                      ? 'Start: ${nextChapterTitle}'
                                      : 'Up Next: ${nextChapterTitle}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isStarting
                                      ? 'Chapter ${nextChapterIndex + 1} of $totalChapters'
                                      : '$completedChapters of $totalChapters completed · $progressPct%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isStarting)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: progressColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$progressPct%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: progressColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (!isStarting) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progressPct / 100,
                            backgroundColor:
                                progressColor.withValues(alpha: 0.12),
                            valueColor:
                                AlwaysStoppedAnimation(progressColor),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(isStarting
                            ? 'Start Learning'
                            : 'Continue Learning'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Interactive board-based teaching experience',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
