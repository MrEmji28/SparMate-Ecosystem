import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/bkt_recommendation_banner.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/puzzle_board_card.dart';
import '../widgets/recent_puzzles_card.dart';

/// Full Daily Puzzles screen with live backend integration.
/// Fetches puzzles from `/api/v1/puzzles/daily`, tracks attempts,
/// and manages the interactive puzzle-solving flow.
class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  List<PuzzleData> _puzzles = [];
  int _currentPuzzleIndex = 0;
  int _solvedToday = 0;
  int _dailyGoal = 5;
  int _streakDays = 0;
  List<RecentPuzzleData> _recentAttempts = [];
  bool _isLoading = true;
  String? _errorMsg;

  // Track elapsed time per puzzle for attempt recording
  int _puzzleStartTime = 0;

  @override
  void initState() {
    super.initState();
    _loadPuzzles();
  }

  Future<void> _loadPuzzles() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final api = context.read<AppState>().api;

    try {
      // Fetch daily puzzles
      final dailyData = await api.getDailyPuzzles();
      final puzzlesJson = dailyData['puzzles'] as List? ?? [];
      final stats = dailyData['stats'] as Map<String, dynamic>? ?? {};

      _puzzles = puzzlesJson
          .map((p) => PuzzleData.fromJson(p as Map<String, dynamic>))
          .toList();
      _solvedToday = stats['solved'] as int? ?? 0;
      _dailyGoal = stats['daily_goal'] as int? ?? 5;

      // Fetch recent attempts
      try {
        final recentList = await api.getRecentPuzzles();
        _recentAttempts = recentList.map((a) {
          final puzzle = (a as Map<String, dynamic>)['puzzle'] as Map<String, dynamic>? ?? {};
          return RecentPuzzleData(
            puzzleId: puzzle['id'] as int? ?? 0,
            theme: puzzle['theme'] as String? ?? 'Tactics',
            difficulty: puzzle['difficulty'] as String? ?? 'intermediate',
            rating: puzzle['rating'] as int? ?? 1500,
            solved: a['solved'] as bool? ?? false,
            timeSeconds: a['time_seconds'] as int?,
          );
        }).toList();
      } catch (_) {
        // Recent puzzles are non-critical
      }

      // Get streak from user data
      final state = context.read<AppState>();
      _streakDays = state.user?['streak_days'] as int? ?? 0;

      setState(() {
        _isLoading = false;
        _currentPuzzleIndex = 0;
      });

      // Show the intro popup
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showPuzzleIntroDialog();
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Using offline puzzles (API unavailable).';
      });
      _loadFallbackPuzzles();
    }
  }

  void _loadFallbackPuzzles() {
    _puzzles = [
      PuzzleData(
        id: 1,
        fen: '6k1/5ppp/8/8/8/8/1Q3PPP/6K1 w - - 0 1',
        solutionMoves: ['Qb8#'],
        category: 'Tactics',
        difficulty: 'beginner',
        rating: 800,
        theme: 'Mate in 1',
      ),
      PuzzleData(
        id: 2,
        fen: 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
        solutionMoves: ['Qxf7#'],
        category: 'Tactics',
        difficulty: 'beginner',
        rating: 900,
        theme: "Scholar's Mate",
      ),
      PuzzleData(
        id: 3,
        fen: 'r4rk1/ppp2ppp/2n5/3q4/8/2N2N2/PPP2PPP/R2QR1K1 w - - 0 12',
        solutionMoves: ['Nxd5'],
        category: 'Tactics',
        difficulty: 'beginner',
        rating: 1000,
        theme: 'Capture the Queen',
      ),
      PuzzleData(
        id: 4,
        fen: '2r3k1/5ppp/p7/1p6/1Pb5/P1B5/5PPP/4R1K1 w - - 0 1',
        solutionMoves: ['Re8+'],
        category: 'Tactics',
        difficulty: 'intermediate',
        rating: 1400,
        theme: 'Back Rank',
      ),
      PuzzleData(
        id: 5,
        fen: 'r1b1k2r/ppppqppp/2n2n2/1Bb1p3/4P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 6 5',
        solutionMoves: ['Bxc6'],
        category: 'Tactics',
        difficulty: 'intermediate',
        rating: 1500,
        theme: 'Pin & Win',
      ),
    ];
    setState(() {
      _isLoading = false;
    });

    // Show the intro popup for fallback too
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPuzzleIntroDialog();
      });
    }
  }

  void _onPuzzleSolved() {
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) - _puzzleStartTime;

    setState(() {
      _solvedToday++;
      final puzzle = _currentPuzzle;
      if (puzzle != null) {
        _recentAttempts.insert(
          0,
          RecentPuzzleData(
            puzzleId: puzzle.id,
            theme: puzzle.theme,
            difficulty: puzzle.difficulty,
            rating: puzzle.rating,
            solved: true,
            timeSeconds: elapsed,
          ),
        );
      }
    });

    _recordAttempt(true, elapsed);

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Puzzle solved in ${elapsed}s! 🎉',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onPuzzleFailed() {
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) - _puzzleStartTime;

    setState(() {
      final puzzle = _currentPuzzle;
      if (puzzle != null) {
        _recentAttempts.insert(
          0,
          RecentPuzzleData(
            puzzleId: puzzle.id,
            theme: puzzle.theme,
            difficulty: puzzle.difficulty,
            rating: puzzle.rating,
            solved: false,
            timeSeconds: elapsed,
          ),
        );
      }
    });

    _recordAttempt(false, elapsed);
  }

  Future<void> _recordAttempt(bool solved, int elapsed) async {
    final puzzle = _currentPuzzle;
    if (puzzle == null) return;

    try {
      final api = context.read<AppState>().api;
      await api.submitPuzzleAttempt(
        puzzle.id,
        solved: solved,
        timeTakenSeconds: elapsed,
      );
    } catch (_) {
      // Non-critical — attempt is already tracked locally
    }
  }

  void _nextPuzzle() {
    setState(() {
      if (_currentPuzzleIndex < _puzzles.length - 1) {
        _currentPuzzleIndex++;
      } else {
        _currentPuzzleIndex = 0;
      }
      _puzzleStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    });
  }

  PuzzleData? get _currentPuzzle =>
      _puzzles.isNotEmpty && _currentPuzzleIndex < _puzzles.length
          ? _puzzles[_currentPuzzleIndex]
          : null;

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
                    if (Navigator.canPop(context))
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.primaryNavy),
                        splashRadius: 22,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      'Daily Puzzles',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    if (_puzzles.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_currentPuzzleIndex + 1}/${_puzzles.length}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryBlue),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Daily goal card with live data
                    DailyGoalCard(
                      solved: _solvedToday,
                      dailyGoal: _dailyGoal,
                      streakDays: _streakDays,
                    ),
                    const SizedBox(height: 16),

                    // ── BKT Recommendation Banner (Focus Area) ──
                    BktRecommendationBanner(
                      context: RecommendationContext.puzzles,
                    ),
                    const SizedBox(height: 16),

                    // Error/offline banner
                    if (_errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                size: 18, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMsg!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade800)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Interactive puzzle board
                    PuzzleBoardCard(
                      puzzle: _currentPuzzle,
                      onSolved: _onPuzzleSolved,
                      onFailed: _onPuzzleFailed,
                      onNextPuzzle: _nextPuzzle,
                    ),
                    const SizedBox(height: 16),

                    // Recent attempts
                    RecentPuzzlesCard(puzzles: _recentAttempts),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPuzzleIntroDialog() {
    final puzzle = _currentPuzzle;
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
            child: _PuzzleIntroDialogContent(
              puzzleCount: _puzzles.length,
              dailyGoal: _dailyGoal,
              solvedToday: _solvedToday,
              streakDays: _streakDays,
              currentTheme: puzzle?.theme ?? 'Tactics',
              currentDifficulty: puzzle?.difficulty ?? 'beginner',
              currentRating: puzzle?.rating ?? 1200,
              onStart: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _puzzleStartTime =
                      DateTime.now().millisecondsSinceEpoch ~/ 1000;
                });
              },
            ),
          ),
        );
      },
    );
  }
}

/// ── Puzzle Intro Dialog ──────────────────────────────────────────────
class _PuzzleIntroDialogContent extends StatelessWidget {
  final int puzzleCount;
  final int dailyGoal;
  final int solvedToday;
  final int streakDays;
  final String currentTheme;
  final String currentDifficulty;
  final int currentRating;
  final VoidCallback onStart;

  const _PuzzleIntroDialogContent({
    required this.puzzleCount,
    required this.dailyGoal,
    required this.solvedToday,
    required this.streakDays,
    required this.currentTheme,
    required this.currentDifficulty,
    required this.currentRating,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (dailyGoal - solvedToday).clamp(0, dailyGoal);
    final difficultyColor = switch (currentDifficulty) {
      'beginner' => const Color(0xFF43A047),
      'intermediate' => const Color(0xFFFFA000),
      'advanced' => const Color(0xFFE53935),
      _ => AppColors.primaryBlue,
    };
    final difficultyLabel =
        currentDifficulty[0].toUpperCase() + currentDifficulty.substring(1);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
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
                // Puzzle icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3949AB),
                        Color(0xFF1E88E5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3949AB).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.extension_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Daily Puzzles',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sharpen your tactical vision',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
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
                        Icons.extension_rounded,
                        '$puzzleCount',
                        'Puzzles',
                        AppColors.primaryBlue,
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.border,
                      ),
                      _statItem(
                        Icons.track_changes_rounded,
                        '$remaining',
                        'Remaining',
                        const Color(0xFFFFA000),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.border,
                      ),
                      _statItem(
                        Icons.local_fire_department_rounded,
                        '$streakDays',
                        'Day Streak',
                        const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Current puzzle info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: difficultyColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 20, color: difficultyColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'First Puzzle: $currentTheme',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$difficultyLabel · Rating $currentRating',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: difficultyColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          difficultyLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: difficultyColor,
                          ),
                        ),
                      ),
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
                      backgroundColor: const Color(0xFF3949AB),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 22),
                        SizedBox(width: 8),
                        Text('Start Solving'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Tip text
                Text(
                  'Find the best move to solve each puzzle',
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
