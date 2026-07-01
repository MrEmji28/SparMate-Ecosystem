import 'dart:async';
import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/engine/stockfish_engine.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../models/grandmaster.dart';

/// Interactive chess board card with tap-to-move piece movement,
/// legal move highlighting, AI opponent responses, and post-game
/// BKT pipeline integration (classify blunders → update mastery → refresh plan).
class GameBoardCard extends StatefulWidget {
  final Grandmaster gm;
  final ValueChanged<double>? onPressureChanged;

  /// The backend match ID for this session.
  /// Pass 0 (or omit) if the match hasn't been created on the backend yet;
  /// the BKT pipeline will be skipped gracefully in that case.
  final int matchId;

  /// AI difficulty level: 0 = Easy, 1 = Medium, 2 = Hard.
  ///
  /// - **Easy**  : AI picks randomly ~70% of the time, ignoring tactics.
  ///   Good for beginners who need time to learn.
  /// - **Medium** : AI follows the GM's personality (tactical/defensive/balanced).
  ///   The default and intended experience.
  /// - **Hard**  : AI always plays the strongest forcing move available
  ///   (check > capture > best quiet) with almost no randomness.
  final int difficulty;

  const GameBoardCard({
    super.key,
    required this.gm,
    this.onPressureChanged,
    this.matchId = 0,
    this.difficulty = 1,
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

  // Stockfish engine
  final StockfishEngine _engine = StockfishEngine();
  bool _engineReady = false;

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
    _initEngine();
  }

  /// Initialise Stockfish and apply this GM's persona settings.
  /// On Hard difficulty, always forces max skill regardless of GM persona.
  Future<void> _initEngine() async {
    try {
      await _engine.init();
      if (widget.difficulty == 2) {
        // Hard: full-strength Carlsen-level engine regardless of GM
        _engine.applyPersona('carlsen');
      } else {
        _engine.applyPersona(widget.gm.name);
      }
      if (mounted) setState(() => _engineReady = true);
    } catch (_) {
      // Engine failed to start — heuristic fallback will be used instead
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _thinkingAnim.dispose();
    // Do NOT dispose the engine singleton — it may be reused across games
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

    // Easy difficulty: always use the heuristic selector (fast, weak, forgiving)
    if (widget.difficulty == 0) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (_gameOver || !mounted) return;
      _runHeuristicMove();
      return;
    }

    // Medium / Hard: use Stockfish ─────────────────────────────────────

    // If the engine is still initialising (first move of the game),
    // wait up to 8 seconds before giving up and using the heuristic.
    if (!_engineReady) {
      const pollInterval = Duration(milliseconds: 200);
      int waited = 0;
      while (!_engineReady && waited < 8000) {
        await Future.delayed(pollInterval);
        waited += 200;
      }
    }

    if (_engineReady && mounted && !_gameOver) {
      // Hard difficulty: temporarily override to full-strength persona
      final gmNameForEngine = widget.difficulty == 2 ? 'carlsen' : widget.gm.name;

      final uciMove = await _engine.getBestMove(
        _game.fen,
        gmName: gmNameForEngine,
      );

      if (uciMove != null && uciMove.length >= 4 && mounted && !_gameOver) {
        final from = uciMove.substring(0, 2);
        final to   = uciMove.substring(2, 4);
        final promotion = uciMove.length == 5 ? uciMove[4] : null;

        _game.move(<String, String>{
          'from': from,
          'to': to,
          if (promotion != null) 'promotion': promotion,
        });

        if (mounted && !_gameOver) {
          setState(() {
            _lastMoveFrom = from;
            _lastMoveTo   = to;
            _isThinking   = false;
          });
          _checkGameState();
          return; // Stockfish handled it ✓
        }
      }
    }

    // Fallback: heuristic (engine unavailable or returned invalid move)
    if (mounted && !_gameOver) {
      _runHeuristicMove();
    }
  }

  /// Execute one move using the heuristic personality selector.
  /// Always adds a minimum delay so the AI never responds instantly.
  void _runHeuristicMove() {
    final moves = _game.generate_moves();
    if (moves.isEmpty) {
      _checkGameState();
      return;
    }
    final selectedMove = _selectAiMove(moves);
    _game.move(selectedMove);
    if (mounted) {
      setState(() {
        _lastMoveFrom = selectedMove['from'] as String?;
        _lastMoveTo   = selectedMove['to'] as String?;
        _isThinking   = false;
      });
      _checkGameState();
    }
  }

  Map<String, dynamic> _selectAiMove(List<chess_lib.Move> moves) {
    final rng = Random();

    // ── Pre-categorise moves ──────────────────────────────────────────────
    final captures = moves.where((m) => m.captured != null).toList();

    // Find moves that give check by simulating them
    final checks = <chess_lib.Move>[];
    for (final m in moves) {
      final testGame = chess_lib.Chess.fromFEN(_game.fen);
      testGame.move({'from': m.fromAlgebraic, 'to': m.toAlgebraic, 'promotion': 'q'});
      if (testGame.in_check) checks.add(m);
    }

    // Quiet moves = no capture, no check
    final quietMoves = moves
        .where((m) => m.captured == null && !checks.contains(m))
        .toList();

    // ── EASY: intentional mistakes ~70% of the time ───────────────────────
    if (widget.difficulty == 0) {
      if (rng.nextDouble() < 0.70) {
        return _moveToMap(moves[rng.nextInt(moves.length)]);
      }
      if (captures.isNotEmpty) {
        return _moveToMap(captures[rng.nextInt(captures.length)]);
      }
      return _moveToMap(moves[rng.nextInt(moves.length)]);
    }

    // ── HARD: strongest forcing move — universal across all GMs ───────────
    if (widget.difficulty == 2) {
      if (checks.isNotEmpty) {
        final checkCaptures = checks.where((m) => m.captured != null).toList();
        final pool = checkCaptures.isNotEmpty ? checkCaptures : checks;
        return _moveToMap(pool[rng.nextInt(pool.length)]);
      }
      if (captures.isNotEmpty) {
        return _moveToMap(_highestValueCapture(captures));
      }
      return _moveToMap(moves[rng.nextInt(moves.length)]);
    }

    // ── MEDIUM: historically accurate GM personalities ────────────────────
    final personality = widget.gm.name.toLowerCase();

    // ── MIKHAIL TAL — The Magician from Riga (peak ELO ~2705) ────────────
    // Famous for wild piece sacrifices, psychological chaos, and checks at
    // all costs. Prefers attacking moves even when objectively suboptimal.
    // Aggression rate: checks 90%, captures 80%, almost never plays quiet.
    if (personality.contains('tal')) {
      // 1. Almost always plays a checking move
      if (checks.isNotEmpty && rng.nextDouble() < 0.90) {
        // Prefer check-captures (sacrifice into attack)
        final checkCaptures = checks.where((m) => m.captured != null).toList();
        final pool = checkCaptures.isNotEmpty ? checkCaptures : checks;
        return _moveToMap(pool[rng.nextInt(pool.length)]);
      }
      // 2. Otherwise aggressively takes material
      if (captures.isNotEmpty && rng.nextDouble() < 0.80) {
        // Sometimes sacrifice by taking a lower-value piece (chaos)
        return _moveToMap(captures[rng.nextInt(captures.length)]);
      }
      // 3. If nothing forcing, play any move (even quiet — setting up attack)
      return _moveToMap(moves[rng.nextInt(moves.length)]);
    }

    // ── TIGRAN PETROSIAN — Iron Tigran (peak ELO ~2645) ──────────────────
    // World Champion 1963–1969. Prophylactic genius — prevents threats before
    // they arise. Prefers exchange sacrifices for positional compensation.
    // Rarely attacks directly; prefers consolidation and grinding.
    if (personality.contains('petrosian')) {
      // 1. Strongly prefer quiet, prophylactic moves (85% of the time)
      if (quietMoves.isNotEmpty && rng.nextDouble() < 0.85) {
        return _moveToMap(quietMoves[rng.nextInt(quietMoves.length)]);
      }
      // 2. Only capture high-value pieces (≥ Rook = 5) — the exchange sac
      if (captures.isNotEmpty) {
        final valuableCaptures = captures.where((m) {
          final piece = _game.get(m.toAlgebraic);
          if (piece == null) return false;
          final pieceValues = {
            chess_lib.PieceType.QUEEN: 9,
            chess_lib.PieceType.ROOK: 5,
            chess_lib.PieceType.BISHOP: 3,
            chess_lib.PieceType.KNIGHT: 3,
            chess_lib.PieceType.PAWN: 1,
          };
          return (pieceValues[piece.type] ?? 0) >= 5;
        }).toList();
        if (valuableCaptures.isNotEmpty && rng.nextDouble() < 0.70) {
          return _moveToMap(valuableCaptures[rng.nextInt(valuableCaptures.length)]);
        }
      }
      // 3. Avoid checks unless unavoidable — Petrosian doesn't attack recklessly
      if (checks.isNotEmpty && rng.nextDouble() < 0.20) {
        return _moveToMap(checks[rng.nextInt(checks.length)]);
      }
      // 4. Fallback: any quiet or random move (consolidation)
      return quietMoves.isNotEmpty
          ? _moveToMap(quietMoves[rng.nextInt(quietMoves.length)])
          : _moveToMap(moves[rng.nextInt(moves.length)]);
    }

    // ── MAGNUS CARLSEN — The Norwegian Magnus (peak ELO 2882) ────────────
    // World Champion 2013–2023. Universal style, deadly in all phases.
    // Particularly merciless in endgames — shifts to precise forcing mode
    // when few pieces remain. High accuracy, low randomness.
    if (personality.contains('carlsen')) {
      final pieceCount = _countPiecesOnBoard();

      // Endgame (≤ 14 pieces): switch to precise, forcing play
      if (pieceCount <= 14) {
        // In endgames Carlsen always plays the most forcing available move
        if (checks.isNotEmpty) {
          final checkCaptures = checks.where((m) => m.captured != null).toList();
          final pool = checkCaptures.isNotEmpty ? checkCaptures : checks;
          return _moveToMap(pool[rng.nextInt(pool.length)]);
        }
        if (captures.isNotEmpty) {
          return _moveToMap(_highestValueCapture(captures));
        }
        return _moveToMap(moves[rng.nextInt(moves.length)]);
      }

      // Middlegame: universal — intelligently balances attack and consolidation
      // 60% prefer forcing moves, 40% play quiet positional moves
      if (rng.nextDouble() < 0.60) {
        if (checks.isNotEmpty) {
          return _moveToMap(checks[rng.nextInt(checks.length)]);
        }
        if (captures.isNotEmpty) {
          return _moveToMap(_highestValueCapture(captures));
        }
      }
      // Positional / quiet move (Carlsen is happy to manoeuvre)
      if (quietMoves.isNotEmpty) {
        return _moveToMap(quietMoves[rng.nextInt(quietMoves.length)]);
      }
      return _moveToMap(moves[rng.nextInt(moves.length)]);
    }

    // ── EULALIO TORRE — Asia's first GM (peak ELO ~2600) ─────────────────
    // Philippines' first GM and inventor of the Torre Attack (1.d4, 2.Nf3,
    // 3.Bg5). Patient positional buildup with sharp tactical awareness.
    // Waits for mistakes, then strikes with precision. Not reckless.
    // Default personality — also covers any unknown GM name.
    {
      // 1. Checks: play them sometimes but not recklessly (~50%)
      if (checks.isNotEmpty && rng.nextDouble() < 0.50) {
        return _moveToMap(checks[rng.nextInt(checks.length)]);
      }
      // 2. Safe captures — Torre takes material when available (~65%)
      if (captures.isNotEmpty && rng.nextDouble() < 0.65) {
        return _moveToMap(_highestValueCapture(captures));
      }
      // 3. Quiet positional buildup (Torre's hallmark patience)
      if (quietMoves.isNotEmpty) {
        return _moveToMap(quietMoves[rng.nextInt(quietMoves.length)]);
      }
      return _moveToMap(moves[rng.nextInt(moves.length)]);
    }
  }

  /// Count total pieces currently on the board (used to detect endgame phase).
  int _countPiecesOnBoard() {
    int count = 0;
    for (var rank = 0; rank < 8; rank++) {
      for (var file = 0; file < 8; file++) {
        final sq = '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';
        if (_game.get(sq) != null) count++;
      }
    }
    return count;
  }

  /// Convert a Move object to the map format expected by chess_lib.
  Map<String, String> _moveToMap(chess_lib.Move m) {
    final map = <String, String>{
      'from': m.fromAlgebraic,
      'to': m.toAlgebraic,
    };
    if (m.promotion != null) map['promotion'] = 'q';
    return map;
  }

  /// Pick the highest-value capture (used in Hard mode).
  /// Piece values: Q=9, R=5, B=3, N=3, P=1.
  chess_lib.Move _highestValueCapture(List<chess_lib.Move> captures) {
    final pieceValues = {
      chess_lib.PieceType.QUEEN: 9,
      chess_lib.PieceType.ROOK: 5,
      chess_lib.PieceType.BISHOP: 3,
      chess_lib.PieceType.KNIGHT: 3,
      chess_lib.PieceType.PAWN: 1,
      chess_lib.PieceType.KING: 0,
    };

    chess_lib.Move? best;
    int bestValue = -1;
    for (final m in captures) {
      final piece = _game.get(m.toAlgebraic);
      final value = piece != null ? (pieceValues[piece.type] ?? 0) : 0;
      if (value > bestValue) {
        bestValue = value;
        best = m;
      }
    }
    return best ?? captures.first;
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

  // ── BKT Pipeline helpers ──────────────────────────────────────────

  /// Derive a standard result string from the game-over message.
  String _deriveResult(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('you win') || lower.contains('you win')) return 'win';
    if (lower.contains('you lose') || lower.contains('resigned')) return 'loss';
    if (lower.contains('draw') || lower.contains('stalemate')) return 'draw';
    // Default: AI wins
    return 'loss';
  }

  /// Trigger the full post-game BKT pipeline asynchronously:
  ///   1. Submit PGN + result to Laravel
  ///   2. Laravel calls FastAPI → classify blunders
  ///   3. BKT matrix updated in MySQL
  ///   4. Coaching plan refreshed in AppState
  Future<Map<String, dynamic>?> _runBktPipeline(String result) async {
    if (widget.matchId == 0) return null; // No backend match — skip
    if (!mounted) return null;

    final state = context.read<AppState>();
    final pgn = _game.pgn();
    final fen = _game.fen;
    final moveCount = _game.history.length;
    // Approximate duration: total time used from both clocks (ms → seconds)
    final elapsedSec =
        ((30 * 60 * 1000) - _whiteTimeMs - _blackTimeMs).clamp(0, 9999) ~/ 1000;

    return state.completeMatch(
      widget.matchId,
      pgn: pgn,
      finalFen: fen,
      result: result,
      moveCount: moveCount,
      duration: elapsedSec,
    );
  }

  void _endGame(String message) {
    _clockTimer?.cancel();
    setState(() {
      _gameOver = true;
      _statusText = message;
      _selectedSquare = null;
      _legalMoveSquares = [];
    });

    // Show the post-game sheet and fire the BKT pipeline
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showPostGameSheet(message);
    });
  }

  void _showPostGameSheet(String message) {
    final result = _deriveResult(message);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostGameSheet(
        message: message,
        result: result,
        gmName: widget.gm.fullName,
        gmColor: widget.gm.color,
        moveCount: _game.history.length,
        hasBackendMatch: widget.matchId != 0,
        bktFuture: _runBktPipeline(result),
        onPlayAgain: () {
          Navigator.of(context).pop(); // close sheet
          _resetGame();
        },
        onGoHome: () {
          Navigator.of(context).pop(); // close sheet
          Navigator.of(context).pop(); // leave sparring screen
        },
      ),
    );
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
                  border: Border.all(color: widget.gm.color.withValues(alpha: 0.2), width: 1),
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.gm.imagePath,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: widget.gm.color.withValues(alpha: 0.12),
                      child: Icon(widget.gm.icon, size: 14, color: widget.gm.color),
                    ),
                  ),
                ),
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
                  builder: (context, _) => Container(
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

// ── Post-Game Result Sheet ────────────────────────────────────────────────────

/// Animated bottom-sheet shown when the game ends.
///
/// Displays the result, move count, and a live status widget that shows the
/// BKT pipeline progress (submitting → analyzing → updating coaching plan).
class _PostGameSheet extends StatefulWidget {
  final String message;
  final String result; // 'win' | 'loss' | 'draw'
  final String gmName;
  final Color gmColor;
  final int moveCount;
  final bool hasBackendMatch;
  final Future<Map<String, dynamic>?>? bktFuture;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;

  const _PostGameSheet({
    required this.message,
    required this.result,
    required this.gmName,
    required this.gmColor,
    required this.moveCount,
    required this.hasBackendMatch,
    required this.bktFuture,
    required this.onPlayAgain,
    required this.onGoHome,
  });

  @override
  State<_PostGameSheet> createState() => _PostGameSheetState();
}

class _PostGameSheetState extends State<_PostGameSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // BKT pipeline status
  _BktStatus _bktStatus = _BktStatus.idle;
  String _bktStatusText = '';

  // Elo rating change from the completed match
  int? _ratingChange;
  int? _newRating;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();

    if (widget.hasBackendMatch && widget.bktFuture != null) {
      _runPipeline();
    }
  }

  Future<void> _runPipeline() async {
    setState(() {
      _bktStatus = _BktStatus.loading;
      _bktStatusText = 'Analyzing your game...';
    });

    try {
      final result = await widget.bktFuture;
      if (!mounted) return;
      if (result != null) {
        final change = result['rating_change'] as int?;
        final newRating = result['new_rating'] as int?;
        setState(() {
          _bktStatus = _BktStatus.success;
          _bktStatusText = 'Coaching plan updated!';
          _ratingChange = change;
          _newRating = newRating;
        });
      } else {
        setState(() {
          _bktStatus = _BktStatus.skipped;
          _bktStatusText = 'Practice game — no BKT update';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bktStatus = _BktStatus.error;
        _bktStatusText = 'Could not update coaching plan';
      });
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWin = widget.result == 'win';
    final isDraw = widget.result == 'draw';

    final resultColor = isWin
        ? const Color(0xFF2E7D32)
        : isDraw
            ? const Color(0xFFFF8F00)
            : AppColors.liveRed;

    final resultIcon = isWin
        ? Icons.emoji_events_rounded
        : isDraw
            ? Icons.handshake_rounded
            : Icons.flag_rounded;

    final resultLabel = isWin ? 'Victory!' : isDraw ? 'Draw' : 'Defeat';

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag handle ──
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Result icon ──
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: resultColor.withValues(alpha: 0.2), width: 2),
                    ),
                    child: Icon(resultIcon, size: 36, color: resultColor),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Result label ──
                Text(
                  resultLabel,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Stats row ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statChip(
                        Icons.swap_horiz_rounded,
                        '${widget.moveCount}',
                        'Moves',
                        AppColors.primaryBlue,
                      ),
                      Container(
                          width: 1, height: 28, color: AppColors.border),
                      _statChip(
                        Icons.person_rounded,
                        widget.gmName.split(' ').last,
                        'Opponent',
                        widget.gmColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Rating change badge (shown after pipeline completes) ──
                if (_ratingChange != null) _buildRatingBadge(_ratingChange!, _newRating),
                if (_ratingChange != null) const SizedBox(height: 12),

                // ── BKT Pipeline status ──
                if (widget.hasBackendMatch) _buildBktStatus(),
                if (!widget.hasBackendMatch)
                  _bktInfoChip(
                    Icons.info_outline_rounded,
                    'Practice game — coaching data not saved',
                    AppColors.textLight,
                    AppColors.progressTrack,
                  ),
                const SizedBox(height: 24),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onGoHome,
                        icon: const Icon(Icons.home_rounded, size: 18),
                        label: const Text('Home'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.8)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          foregroundColor: AppColors.textMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: widget.onPlayAgain,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Play Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBktStatus() {
    switch (_bktStatus) {
      case _BktStatus.idle:
        return const SizedBox.shrink();
      case _BktStatus.loading:
        return _bktInfoChip(
          null, // spinner instead
          _bktStatusText,
          AppColors.primaryBlue,
          AppColors.primaryBlue.withValues(alpha: 0.08),
          showSpinner: true,
        );
      case _BktStatus.success:
        return _bktInfoChip(
          Icons.check_circle_rounded,
          _bktStatusText,
          const Color(0xFF2E7D32),
          const Color(0xFF2E7D32).withValues(alpha: 0.08),
        );
      case _BktStatus.error:
        return _bktInfoChip(
          Icons.error_outline_rounded,
          _bktStatusText,
          AppColors.liveRed,
          AppColors.liveRed.withValues(alpha: 0.08),
        );
      case _BktStatus.skipped:
        return _bktInfoChip(
          Icons.info_outline_rounded,
          _bktStatusText,
          AppColors.textLight,
          AppColors.progressTrack,
        );
    }
  }

  /// Large animated rating-change badge.
  /// Shows +12 (green) / -8 (red) / ±0 (grey) with the new absolute rating.
  Widget _buildRatingBadge(int change, int? newRating) {
    final isPositive = change > 0;
    final isNeutral = change == 0;

    final color = isNeutral
        ? AppColors.textLight
        : isPositive
            ? const Color(0xFF2E7D32)
            : AppColors.liveRed;

    final sign = isPositive ? '+' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : isNeutral
                    ? Icons.trending_flat_rounded
                    : Icons.trending_down_rounded,
            color: color,
            size: 26,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$sign$change pts',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1,
                ),
              ),
              if (newRating != null)
                Text(
                  'New rating: $newRating',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ELO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bktInfoChip(
    IconData? icon,
    String text,
    Color color,
    Color bgColor, {
    bool showSpinner = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          // BKT badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'BKT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label, Color color) {
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
          style: TextStyle(fontSize: 10, color: AppColors.textLight),
        ),
      ],
    );
  }
}

enum _BktStatus { idle, loading, success, error, skipped }
