import 'dart:async';
import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../models/grandmaster.dart';

/// Interactive chess board card with tap-to-move piece movement,
/// legal move highlighting, and AI opponent responses.
class GameBoardCard extends StatefulWidget {
  final Grandmaster gm;
  final ValueChanged<double>? onPressureChanged;

  const GameBoardCard({
    super.key,
    required this.gm,
    this.onPressureChanged,
  });

  @override
  State<GameBoardCard> createState() => _GameBoardCardState();
}

class _GameBoardCardState extends State<GameBoardCard>
    with SingleTickerProviderStateMixin {
  late chess_lib.Chess _game;
  String? _selectedSquare;
  List<String> _legalMoveSquares = [];
  String? _lastMoveFrom;
  String? _lastMoveTo;
  bool _gameOver = false;
  String _statusText = 'Your turn — White to move';
  bool _isThinking = false;

  // Timers
  int _whiteTimeMs = 15 * 60 * 1000; // 15 minutes
  int _blackTimeMs = 15 * 60 * 1000;
  Timer? _clockTimer;

  // Animation for AI thinking
  late AnimationController _thinkingAnim;

  @override
  void initState() {
    super.initState();
    _game = chess_lib.Chess();
    _thinkingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _startClock();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _thinkingAnim.dispose();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_gameOver) return;
      setState(() {
        if (_game.turn == chess_lib.Color.WHITE) {
          _whiteTimeMs = max(0, _whiteTimeMs - 1000);
          if (_whiteTimeMs <= 0) _endGame('Time out — You lose');
        } else {
          _blackTimeMs = max(0, _blackTimeMs - 1000);
          if (_blackTimeMs <= 0) _endGame('Time out — You win!');
        }
      });
    });
  }

  String _formatTime(int ms) {
    final totalSecs = ms ~/ 1000;
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Piece SVG asset mapping (Lichess cburnett) ──

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
    if (_gameOver || _isThinking) return;
    if (_game.turn != chess_lib.Color.WHITE) return;

    final square = _squareName(row, col);
    final piece = _game.get(square);

    if (_selectedSquare == null) {
      // Select a white piece
      if (piece != null && piece.color == chess_lib.Color.WHITE) {
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

      // Re-select another own piece
      if (piece != null && piece.color == chess_lib.Color.WHITE) {
        setState(() {
          _selectedSquare = square;
          _legalMoveSquares = _getLegalMovesFrom(square);
        });
        return;
      }

      // Attempt the move
      _tryMove(_selectedSquare!, square);
    }
  }

  List<String> _getLegalMovesFrom(String from) {
    final moves = _game.generate_moves();
    return moves
        .where((m) => m.fromAlgebraic == from)
        .map((m) => m.toAlgebraic)
        .toList();
  }

  void _tryMove(String from, String to) {
    // Check for pawn promotion
    final piece = _game.get(from);
    final isPromotion = piece != null &&
        piece.type == chess_lib.PieceType.PAWN &&
        (to[1] == '8' || to[1] == '1');

    final success = _game.move({
      'from': from,
      'to': to,
      if (isPromotion) 'promotion': 'q',
    });

    if (success) {
      setState(() {
        _lastMoveFrom = from;
        _lastMoveTo = to;
        _selectedSquare = null;
        _legalMoveSquares = [];
      });

      _checkGameState();

      if (!_gameOver) {
        _makeAiMove();
      }
    } else {
      // Invalid move — deselect
      setState(() {
        _selectedSquare = null;
        _legalMoveSquares = [];
      });
    }
  }

  // ── AI Move ──

  Future<void> _makeAiMove() async {
    setState(() {
      _isThinking = true;
      _statusText = '${widget.gm.fullName} is thinking...';
    });

    // Simulate thinking time based on GM
    final thinkTime = 500 + Random().nextInt(1500);
    await Future.delayed(Duration(milliseconds: thinkTime));

    if (_gameOver || !mounted) return;

    final moves = _game.generate_moves();
    if (moves.isEmpty) {
      _checkGameState();
      return;
    }

    final selectedMove = _selectAiMove(moves);
    _game.move(selectedMove);

    if (mounted) {
      setState(() {
        _lastMoveFrom = selectedMove['from'];
        _lastMoveTo = selectedMove['to'];
        _isThinking = false;
      });
      _checkGameState();
    }
  }

  Map<String, String> _selectAiMove(List<chess_lib.Move> moves) {
    final rng = Random();

    // Categorize moves
    final captures = moves.where((m) => m.captured != null).toList();

    // Test which moves give check
    final checks = <chess_lib.Move>[];
    for (final m in moves) {
      final testGame = chess_lib.Chess.fromFEN(_game.fen);
      testGame.move({'from': m.fromAlgebraic, 'to': m.toAlgebraic, 'promotion': 'q'});
      if (testGame.in_check) {
        checks.add(m);
      }
    }

    chess_lib.Move chosen;
    final personality = widget.gm.name.toLowerCase();

    if (personality.contains('tal')) {
      // Aggressive: prefer checks > captures
      if (checks.isNotEmpty && rng.nextDouble() > 0.3) {
        chosen = checks[rng.nextInt(checks.length)];
      } else if (captures.isNotEmpty && rng.nextDouble() > 0.3) {
        chosen = captures[rng.nextInt(captures.length)];
      } else {
        chosen = moves[rng.nextInt(moves.length)];
      }
    } else if (personality.contains('petrosian')) {
      // Defensive: prefer quiet moves
      final quietMoves = moves.where((m) => m.captured == null).toList();
      if (quietMoves.isNotEmpty && rng.nextDouble() > 0.2) {
        chosen = quietMoves[rng.nextInt(quietMoves.length)];
      } else {
        chosen = moves[rng.nextInt(moves.length)];
      }
    } else {
      // Balanced (Torre, Carlsen)
      if (checks.isNotEmpty && rng.nextDouble() > 0.5) {
        chosen = checks[rng.nextInt(checks.length)];
      } else if (captures.isNotEmpty && rng.nextDouble() > 0.4) {
        chosen = captures[rng.nextInt(captures.length)];
      } else {
        chosen = moves[rng.nextInt(moves.length)];
      }
    }

    final result = <String, String>{
      'from': chosen.fromAlgebraic,
      'to': chosen.toAlgebraic,
    };
    if (chosen.promotion != null) {
      result['promotion'] = 'q';
    }
    return result;
  }

  void _checkGameState() {
    if (_game.in_checkmate) {
      final winner = _game.turn == chess_lib.Color.WHITE
          ? '${widget.gm.fullName} wins — Checkmate!'
          : 'Checkmate — You win! 🎉';
      _endGame(winner);
    } else if (_game.in_stalemate) {
      _endGame('Stalemate — Draw');
    } else if (_game.in_draw) {
      _endGame('Draw');
    } else if (_game.in_check) {
      setState(() {
        _statusText = _game.turn == chess_lib.Color.WHITE
            ? 'Check! Your move'
            : '${widget.gm.fullName} is in check';
      });
    } else {
      setState(() {
        _statusText = _game.turn == chess_lib.Color.WHITE
            ? 'Your turn — White to move'
            : '${widget.gm.fullName}\'s turn';
      });
    }

    // Update pressure gauge
    widget.onPressureChanged?.call(_calculatePressure());
  }

  double _calculatePressure() {
    final moves = _game.generate_moves();
    final captures = moves.where((m) => m.captured != null).length;
    final inCheck = _game.in_check ? 0.3 : 0.0;
    return (captures / 10.0 + inCheck).clamp(0.0, 1.0);
  }

  void _endGame(String message) {
    _clockTimer?.cancel();
    setState(() {
      _gameOver = true;
      _statusText = message;
      _selectedSquare = null;
      _legalMoveSquares = [];
    });
  }

  void _resignGame() {
    _endGame('You resigned — ${widget.gm.fullName} wins');
  }

  void _offerDraw() {
    if (Random().nextDouble() < 0.3) {
      _endGame('Draw agreed ✅');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.gm.fullName} declined your draw offer.'),
          backgroundColor: AppColors.primaryNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _resetGame() {
    _clockTimer?.cancel();
    setState(() {
      _game = chess_lib.Chess();
      _selectedSquare = null;
      _legalMoveSquares = [];
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _gameOver = false;
      _isThinking = false;
      _statusText = 'Your turn — White to move';
      _whiteTimeMs = 15 * 60 * 1000;
      _blackTimeMs = 15 * 60 * 1000;
    });
    _startClock();
  }

  void _undoMove() {
    if (_gameOver || _isThinking) return;
    // Undo both AI and player moves
    final undo1 = _game.undo();
    if (undo1 != null) {
      _game.undo(); // Undo AI move too
      setState(() {
        _selectedSquare = null;
        _legalMoveSquares = [];
        _lastMoveFrom = null;
        _lastMoveTo = null;
        _statusText = 'Your turn — White to move';
      });
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // ── Opponent label + clock ──
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.gm.color.withValues(alpha: 0.12),
                ),
                child: Icon(widget.gm.icon, size: 14, color: widget.gm.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.gm.title} ${widget.gm.fullName}',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isThinking)
                AnimatedBuilder(
                  animation: _thinkingAnim,
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🤔 Thinking...',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatTime(_blackTimeMs),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successGreen,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Interactive Chess Board ──
          LayoutBuilder(builder: (context, constraints) {
            final boardSize = constraints.maxWidth;
            final sqSize = boardSize / 8;

            return Container(
              width: boardSize,
              height: boardSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  for (var r = 0; r < 8; r++)
                    for (var c = 0; c < 8; c++)
                      _buildSquare(r, c, sqSize),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),

          // ── Status label ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _gameOver
                  ? AppColors.primaryBlue.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _gameOver ? AppColors.primaryBlue : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_gameOver) ...[
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _game.turn == chess_lib.Color.WHITE
                          ? Colors.white
                          : const Color(0xFF2D2D2D),
                      border: Border.all(color: AppColors.textMedium, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    _statusText,
                    style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _gameOver ? AppColors.primaryBlue : AppColors.textMedium,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Player label + clock ──
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryLight],
                  ),
                ),
                child: const Icon(Icons.person, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'You',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _whiteTimeMs < 60000
                      ? AppColors.liveRed.withValues(alpha: 0.1)
                      : AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatTime(_whiteTimeMs),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _whiteTimeMs < 60000 ? AppColors.liveRed : AppColors.textDark,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Game controls ──
          Row(
            children: [
              Expanded(
                child: _controlBtn(
                  _gameOver ? Icons.refresh_rounded : Icons.flag_rounded,
                  _gameOver ? 'New Game' : 'Resign',
                  _gameOver ? AppColors.primaryBlue : AppColors.liveRed,
                  _gameOver ? _resetGame : _resignGame,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _controlBtn(
                  Icons.handshake_rounded,
                  'Draw',
                  AppColors.textMedium,
                  _gameOver ? null : _offerDraw,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _controlBtn(
                  Icons.undo_rounded,
                  'Undo',
                  AppColors.successGreen,
                  _gameOver ? null : _undoMove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquare(int row, int col, double sqSize) {
    final square = _squareName(row, col);
    final piece = _game.get(square);
    final isLight = (row + col) % 2 == 0;
    final isSelected = square == _selectedSquare;
    final isLegalTarget = _legalMoveSquares.contains(square);
    final isLastMove = square == _lastMoveFrom || square == _lastMoveTo;

    // ── Lichess brown theme colors ──
    const lightSquare = Color(0xFFEDD6B0); // Lichess light
    const darkSquare = Color(0xFFB48764);  // Lichess dark
    const selectedLight = Color(0xFF829769); // Lichess green select (light)
    const selectedDark = Color(0xFF646D40);  // Lichess green select (dark)
    const lastMoveLight = Color(0xFFC8D88B); // Lichess last-move highlight (light)
    const lastMoveDark = Color(0xFF9AAD5B);  // Lichess last-move highlight (dark)

    // Square color
    Color bgColor;
    if (isSelected) {
      bgColor = isLight ? selectedLight : selectedDark;
    } else if (isLastMove) {
      bgColor = isLight ? lastMoveLight : lastMoveDark;
    } else {
      bgColor = isLight ? lightSquare : darkSquare;
    }

    // ── Piece asset ──
    bool isWhitePiece = false;
    String? pieceAssetPath;
    if (piece != null) {
      isWhitePiece = piece.color == chess_lib.Color.WHITE;
      pieceAssetPath = _pieceAsset(piece.type.toString(), isWhitePiece);
    }

    // Coordinate label colors (contrast with square, like Lichess)
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
              // ── Legal move indicator (Lichess-style) ──
              if (isLegalTarget)
                Center(
                  child: piece != null
                      // Capture: translucent ring
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
                      // Empty: small dot
                      : Container(
                          width: sqSize * 0.32,
                          height: sqSize * 0.32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.14),
                          ),
                        ),
                ),

              // ── Piece (Lichess cburnett SVG) ──
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

              // ── Rank labels (right edge, Lichess-style) ──
              if (col == 7)
                Positioned(
                  top: 2, right: 3,
                  child: Text(
                    '${8 - row}',
                    style: TextStyle(
                      fontSize: sqSize * 0.22,
                      fontWeight: FontWeight.w700,
                      color: coordColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),

              // ── File labels (bottom edge, Lichess-style) ──
              if (row == 7)
                Positioned(
                  bottom: 2, left: 3,
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

  Widget _controlBtn(IconData icon, String label, Color color, VoidCallback? onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: onPressed != null ? color : color.withValues(alpha: 0.4)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onPressed != null ? color : color.withValues(alpha: 0.4),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: BorderSide(
          color: (onPressed != null ? color : color.withValues(alpha: 0.2)).withValues(alpha: 0.3),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
