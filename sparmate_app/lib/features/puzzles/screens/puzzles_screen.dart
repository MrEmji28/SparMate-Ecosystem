import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
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
        _puzzleStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      });
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
      _puzzleStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    });
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
}
