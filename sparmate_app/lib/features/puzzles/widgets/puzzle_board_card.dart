import 'dart:async';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

/// Puzzle data passed from parent.
class PuzzleData {
  final int id;
  final String fen;
  final List<String> solutionMoves;
  final String category;
  final String difficulty;
  final int rating;
  final String theme;

  const PuzzleData({
    required this.id,
    required this.fen,
    required this.solutionMoves,
    required this.category,
    required this.difficulty,
    required this.rating,
    required this.theme,
  });

  factory PuzzleData.fromJson(Map<String, dynamic> json) {
    return PuzzleData(
      id: json['id'] as int,
      fen: json['fen'] as String,
      solutionMoves: (json['solution_moves'] as List).cast<String>(),
      category: json['category'] as String? ?? 'Tactics',
      difficulty: json['difficulty'] as String? ?? 'intermediate',
      rating: json['rating'] as int? ?? 1500,
      theme: json['theme'] as String? ?? 'Tactics',
    );
  }
}

/// Interactive Lichess-style puzzle board with tap-to-move,
/// solution checking, hints, and animated feedback.
class PuzzleBoardCard extends StatefulWidget {
  final PuzzleData? puzzle;
  final VoidCallback? onSolved;
  final VoidCallback? onFailed;
  final VoidCallback? onNextPuzzle;

  const PuzzleBoardCard({
    super.key,
    this.puzzle,
    this.onSolved,
    this.onFailed,
    this.onNextPuzzle,
  });

  @override
  State<PuzzleBoardCard> createState() => _PuzzleBoardCardState();
}

class _PuzzleBoardCardState extends State<PuzzleBoardCard>
    with TickerProviderStateMixin {
  chess_lib.Chess? _game;
  String? _selectedSquare;
  List<String> _legalMoveSquares = [];
  String? _lastMoveFrom;
  String? _lastMoveTo;

  int _currentMoveIndex = 0;
  bool _solved = false;
  bool _failed = false;
  bool _showingHint = false;
  String? _hintSquare;
  String _statusText = '';
  Color _statusColor = AppColors.textMedium;
  IconData _statusIcon = Icons.info_outline_rounded;

  // Timer
  int _elapsedSeconds = 0;
  Timer? _timer;

  // Animations
  late AnimationController _feedbackAnim;
  late AnimationController _pulseAnim;
  Color _feedbackColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _feedbackAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initPuzzle();
  }

  @override
  void didUpdateWidget(PuzzleBoardCard old) {
    super.didUpdateWidget(old);
    if (old.puzzle?.id != widget.puzzle?.id) {
      _initPuzzle();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  void _initPuzzle() {
    _timer?.cancel();
    final puzzle = widget.puzzle;
    if (puzzle == null) {
      setState(() {
        _game = null;
        _statusText = 'Loading puzzle...';
      });
      return;
    }

    setState(() {
      _game = chess_lib.Chess.fromFEN(puzzle.fen);
      _selectedSquare = null;
      _legalMoveSquares = [];
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _currentMoveIndex = 0;
      _solved = false;
      _failed = false;
      _showingHint = false;
      _hintSquare = null;
      _elapsedSeconds = 0;

      final isWhiteTurn = _game!.turn == chess_lib.Color.WHITE;
      _statusText = isWhiteTurn ? 'White to move' : 'Black to move';
      _statusColor = AppColors.textMedium;
      _statusIcon = Icons.info_outline_rounded;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_solved && !_failed && mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  // ── Piece asset mapping (Lichess cburnett) ──

  static String _pieceAsset(String type, bool isWhite) {
    final color = isWhite ? 'w' : 'b';
    final t = type.toUpperCase();
    return 'assets/pieces/$color$t.svg';
  }

  String _squareName(int row, int col) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = (8 - row).toString();
    return '$file$rank';
  }

  // ── Tap handling ──

  void _onSquareTap(int row, int col) {
    if (_game == null || _solved || _failed) return;

    final square = _squareName(row, col);
    final piece = _game!.get(square);
    final playerColor = _game!.turn;

    if (_selectedSquare == null) {
      // Select piece of current color
      if (piece != null && piece.color == playerColor) {
        setState(() {
          _selectedSquare = square;
          _legalMoveSquares = _getLegalMovesFrom(square);
        });
      }
    } else {
      if (square == _selectedSquare) {
        // Deselect
        setState(() {
          _selectedSquare = null;
          _legalMoveSquares = [];
        });
        return;
      }

      // Re-select own piece
      if (piece != null && piece.color == playerColor) {
        setState(() {
          _selectedSquare = square;
          _legalMoveSquares = _getLegalMovesFrom(square);
        });
        return;
      }

      // Attempt move
      _tryMove(_selectedSquare!, square);
    }
  }

  List<String> _getLegalMovesFrom(String from) {
    final moves = _game!.generate_moves();
    return moves
        .where((m) => m.fromAlgebraic == from)
        .map((m) => m.toAlgebraic)
        .toList();
  }

  void _tryMove(String from, String to) {
    final piece = _game!.get(from);
    final isPromotion = piece != null &&
        piece.type == chess_lib.PieceType.PAWN &&
        (to[1] == '8' || to[1] == '1');

    final success = _game!.move({
      'from': from,
      'to': to,
      if (isPromotion) 'promotion': 'q',
    });

    if (!success) {
      setState(() {
        _selectedSquare = null;
        _legalMoveSquares = [];
      });
      return;
    }

    setState(() {
      _lastMoveFrom = from;
      _lastMoveTo = to;
      _selectedSquare = null;
      _legalMoveSquares = [];
      _showingHint = false;
      _hintSquare = null;
    });

    _checkMove(from, to);
  }

  void _checkMove(String from, String to) {
    final puzzle = widget.puzzle!;
    if (_currentMoveIndex >= puzzle.solutionMoves.length) {
      _markSolved();
      return;
    }

    // Parse expected move from solution
    final expectedSAN = puzzle.solutionMoves[_currentMoveIndex];

    // Undo our move, make the expected move, compare
    _game!.undo();
    final expectedMove = _game!.move(expectedSAN);

    if (expectedMove == false) {
      // Solution move is invalid in this position — just accept
      _game!.move({'from': from, 'to': to});
      _currentMoveIndex++;
      _checkPuzzleComplete();
      return;
    }

    // Get the from/to of the expected move
    final lastMove = _game!.history.last;
    final expFrom = lastMove.move.fromAlgebraic;
    final expTo = lastMove.move.toAlgebraic;

    // Undo expected, redo player's move
    _game!.undo();
    _game!.move({'from': from, 'to': to});

    if (from == expFrom && to == expTo) {
      // Correct move!
      _currentMoveIndex++;
      _showCorrectFeedback();
      _checkPuzzleComplete();
    } else {
      // Wrong move!
      _game!.undo();
      // Replay from/to highlights
      setState(() {
        _lastMoveFrom = null;
        _lastMoveTo = null;
      });
      _markFailed();
    }
  }

  void _checkPuzzleComplete() {
    final puzzle = widget.puzzle!;
    if (_currentMoveIndex >= puzzle.solutionMoves.length) {
      _markSolved();
    } else {
      // Computer's response move (if exists)
      _makeComputerMove();
    }
  }

  Future<void> _makeComputerMove() async {
    if (_currentMoveIndex >= widget.puzzle!.solutionMoves.length) return;

    setState(() {
      _statusText = 'Opponent responds...';
      _statusIcon = Icons.hourglass_top_rounded;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || _solved || _failed) return;

    final moveSAN = widget.puzzle!.solutionMoves[_currentMoveIndex];
    final moved = _game!.move(moveSAN);

    if (moved != false) {
      final lastMove = _game!.history.last;
      setState(() {
        _lastMoveFrom = lastMove.move.fromAlgebraic;
        _lastMoveTo = lastMove.move.toAlgebraic;
        _currentMoveIndex++;

        _statusText = 'Your turn — find the best move!';
        _statusIcon = Icons.psychology_rounded;
        _statusColor = AppColors.primaryBlue;
      });
    }

    // Check if puzzle is now complete
    if (_currentMoveIndex >= widget.puzzle!.solutionMoves.length) {
      _markSolved();
    }
  }

  void _showCorrectFeedback() {
    setState(() {
      _feedbackColor = AppColors.successGreen;
    });
    _feedbackAnim.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _feedbackColor = Colors.transparent);
      }
    });
  }

  void _markSolved() {
    _timer?.cancel();
    setState(() {
      _solved = true;
      _statusText = 'Puzzle solved! 🎉';
      _statusColor = AppColors.successGreen;
      _statusIcon = Icons.check_circle_rounded;
    });
    widget.onSolved?.call();
  }

  void _markFailed() {
    _timer?.cancel();
    setState(() {
      _failed = true;
      _statusText = 'Incorrect — try again next time!';
      _statusColor = AppColors.liveRed;
      _statusIcon = Icons.cancel_rounded;
      _feedbackColor = AppColors.liveRed;
    });
    _feedbackAnim.forward(from: 0).then((_) {
      if (mounted) setState(() => _feedbackColor = Colors.transparent);
    });
    widget.onFailed?.call();
  }

  void _showHint() {
    final puzzle = widget.puzzle;
    if (puzzle == null || _currentMoveIndex >= puzzle.solutionMoves.length) {
      return;
    }

    // Parse the expected move to highlight the source square
    final moveSAN = puzzle.solutionMoves[_currentMoveIndex];

    // Try making the move to get its from square
    final testGame = chess_lib.Chess.fromFEN(_game!.fen);
    final moved = testGame.move(moveSAN);
    if (moved != false) {
      final lastMove = testGame.history.last;
      setState(() {
        _showingHint = true;
        _hintSquare = lastMove.move.fromAlgebraic;
        _statusText = 'Hint: Move the highlighted piece';
        _statusIcon = Icons.lightbulb_rounded;
        _statusColor = Colors.amber.shade700;
      });
    }
  }

  void _viewSolution() {
    final puzzle = widget.puzzle;
    if (puzzle == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.school_rounded, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: 8),
            const Text('Solution', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme: ${puzzle.theme}',
                style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
            const SizedBox(height: 12),
            for (var i = 0; i < puzzle.solutionMoves.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i % 2 == 0
                            ? AppColors.primaryBlue.withValues(alpha: 0.1)
                            : AppColors.textLight.withValues(alpha: 0.1),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: i % 2 == 0
                                  ? AppColors.primaryBlue
                                  : AppColors.textMedium,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      puzzle.solutionMoves[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: i % 2 == 0 ? AppColors.textDark : AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      i % 2 == 0 ? '(your move)' : '(response)',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final puzzle = widget.puzzle;

    if (puzzle == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 12),
              Text('Loading puzzle...',
                  style: tt.bodyMedium?.copyWith(color: AppColors.textLight)),
            ],
          ),
        ),
      );
    }

    final difficultyColor = switch (puzzle.difficulty.toLowerCase()) {
      'beginner' => AppColors.successGreen,
      'intermediate' => Colors.amber.shade700,
      'advanced' => AppColors.liveRed,
      _ => AppColors.textMedium,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // ── Status bar ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon, size: 18, color: _statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusText,
                    style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _formatTime(_elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Interactive Chess Board (full 8×8, Lichess style) ──
          LayoutBuilder(builder: (context, constraints) {
            final boardSize = constraints.maxWidth;
            final sqSize = boardSize / 8;

            return AnimatedBuilder(
              animation: _feedbackAnim,
              builder: (context, child) {
                final flashOpacity = (1.0 - _feedbackAnim.value) * 0.15;
                return Container(
                  width: boardSize,
                  height: boardSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: _feedbackColor != Colors.transparent
                        ? Border.all(
                            color: _feedbackColor.withValues(alpha: flashOpacity * 4),
                            width: 3,
                          )
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      for (var r = 0; r < 8; r++)
                        for (var c = 0; c < 8; c++)
                          _buildSquare(r, c, sqSize),
                      // Flash overlay
                      if (_feedbackColor != Colors.transparent)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: _feedbackColor.withValues(alpha: flashOpacity),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          }),
          const SizedBox(height: 14),

          // ── Puzzle info ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.bolt_rounded, puzzle.theme, AppColors.primaryBlue),
              const SizedBox(width: 10),
              _infoChip(Icons.signal_cellular_alt_rounded,
                  puzzle.difficulty[0].toUpperCase() + puzzle.difficulty.substring(1),
                  difficultyColor),
              const SizedBox(width: 10),
              _infoChip(Icons.star_rounded, '${puzzle.rating}', Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 16),

          // ── Action buttons ──
          if (!_solved && !_failed) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _showHint,
                      icon: const Icon(Icons.lightbulb_rounded, size: 18),
                      label: const Text('Hint'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _viewSolution,
                      icon: Icon(Icons.visibility_rounded,
                          size: 18, color: AppColors.primaryNavy),
                      label: Text('Solution',
                          style: TextStyle(color: AppColors.primaryNavy)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // ── Result + Next Puzzle ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.onNextPuzzle,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Next Puzzle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle:
                      const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (_failed) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _viewSolution,
                  icon: Icon(Icons.school_rounded,
                      size: 16, color: AppColors.primaryBlue),
                  label: Text('View Solution',
                      style: TextStyle(color: AppColors.primaryBlue)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSquare(int row, int col, double sqSize) {
    final square = _squareName(row, col);
    final piece = _game?.get(square);
    final isLight = (row + col) % 2 == 0;
    final isSelected = square == _selectedSquare;
    final isLegalTarget = _legalMoveSquares.contains(square);
    final isLastMove = square == _lastMoveFrom || square == _lastMoveTo;
    final isHint = _showingHint && square == _hintSquare;

    // Lichess brown theme
    const lightSquare = Color(0xFFEDD6B0);
    const darkSquare = Color(0xFFB48764);
    const selectedLight = Color(0xFF829769);
    const selectedDark = Color(0xFF646D40);
    const lastMoveLight = Color(0xFFC8D88B);
    const lastMoveDark = Color(0xFF9AAD5B);
    const hintLight = Color(0xFFCDD26A);
    const hintDark = Color(0xFFAAB238);

    Color bgColor;
    if (isSelected) {
      bgColor = isLight ? selectedLight : selectedDark;
    } else if (isHint) {
      bgColor = isLight ? hintLight : hintDark;
    } else if (isLastMove) {
      bgColor = isLight ? lastMoveLight : lastMoveDark;
    } else {
      bgColor = isLight ? lightSquare : darkSquare;
    }

    String? pieceAssetPath;
    if (piece != null) {
      final isWhite = piece.color == chess_lib.Color.WHITE;
      pieceAssetPath = _pieceAsset(piece.type.toString(), isWhite);
    }

    final coordColor = isLight ? darkSquare : lightSquare;

    return Positioned(
      left: col * sqSize,
      top: row * sqSize,
      width: sqSize,
      height: sqSize,
      child: GestureDetector(
        onTap: () => _onSquareTap(row, col),
        child: Container(
          color: bgColor,
          child: Stack(
            children: [
              // Legal move indicators (Lichess style)
              if (isLegalTarget)
                Center(
                  child: piece != null
                      ? Container(
                          width: sqSize * 0.85,
                          height: sqSize * 0.85,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.15),
                              width: sqSize * 0.1,
                            ),
                          ),
                        )
                      : Container(
                          width: sqSize * 0.32,
                          height: sqSize * 0.32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.14),
                          ),
                        ),
                ),

              // Hint pulse
              if (isHint)
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.amber.withValues(
                            alpha: 0.3 + _pulseAnim.value * 0.3),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),

              // Piece (Lichess cburnett SVG)
              if (pieceAssetPath != null)
                Center(
                  child: SizedBox(
                    width: sqSize * 0.85,
                    height: sqSize * 0.85,
                    child: SvgPicture.asset(
                      pieceAssetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              // Rank labels
              if (col == 7)
                Positioned(
                  top: 2,
                  right: 3,
                  child: Text(
                    '${8 - row}',
                    style: TextStyle(
                      fontSize: sqSize * 0.22,
                      fontWeight: FontWeight.w700,
                      color: coordColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),

              // File labels
              if (row == 7)
                Positioned(
                  bottom: 2,
                  left: 3,
                  child: Text(
                    String.fromCharCode('a'.codeUnitAt(0) + col),
                    style: TextStyle(
                      fontSize: sqSize * 0.22,
                      fontWeight: FontWeight.w700,
                      color: coordColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

/// AnimatedBuilder widget.
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimWidget(animation: animation, builder: builder, child: child);
  }
}

class _AnimWidget extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const _AnimWidget({
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
}
