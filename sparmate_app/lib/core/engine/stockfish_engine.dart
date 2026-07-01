import 'dart:async';
import 'package:stockfish/stockfish.dart';

/// Stockfish engine wrapper with per-GM persona configuration.
///
/// Each Grandmaster maps to a unique set of UCI options that shape
/// Stockfish's playing style to match their historical tendencies:
///
/// | GM         | Skill | Contempt | Move Time | Approx Strength |
/// |------------|-------|----------|-----------|-----------------|
/// | Torre      |  14   |    0     |  1200ms   | ~2540           |
/// | Tal        |  17   |   50     |  1500ms   | ~2700 (aggressive)|
/// | Petrosian  |  16   |  -50     |  1800ms   | ~2650 (defensive) |
/// | Carlsen    |  20   |   24     |  2000ms   | 2882 (full power) |
class StockfishEngine {
  static final StockfishEngine _instance = StockfishEngine._internal();
  factory StockfishEngine() => _instance;
  StockfishEngine._internal();

  Stockfish? _stockfish;
  bool _isReady = false;
  bool _initialising = false;

  // ── GM Persona profiles ──────────────────────────────────────────────────

  static Map<String, int> personaOptions(String gmName) {
    final name = gmName.toLowerCase();
    if (name.contains('tal')) {
      return {'skillLevel': 17, 'contempt': 50, 'moveTime': 1500};
    }
    if (name.contains('petrosian')) {
      return {'skillLevel': 16, 'contempt': -50, 'moveTime': 1800};
    }
    if (name.contains('carlsen')) {
      return {'skillLevel': 20, 'contempt': 24, 'moveTime': 2000};
    }
    // Default: Eugene Torre — solid positional, ~2540 strength
    return {'skillLevel': 14, 'contempt': 0, 'moveTime': 1200};
  }

  // ── Engine lifecycle ─────────────────────────────────────────────────────

  /// Initialise Stockfish and wait for [readyok] before returning.
  /// Safe to call multiple times.
  Future<void> init() async {
    if (_isReady) return;
    if (_initialising) {
      // Already starting up — wait until ready
      while (_initialising && !_isReady) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _initialising = true;
    try {
      _stockfish = await stockfishAsync();

      // Wait for 'readyok' — confirms Stockfish is fully initialised.
      // We must NOT keep a permanent listener; only listen during init.
      final readyCompleter = Completer<void>();
      StreamSubscription<String>? initSub;

      initSub = _stockfish!.stdout.listen((line) {
        if (!readyCompleter.isCompleted &&
            (line.trim() == 'readyok' || line.trim() == 'uciok')) {
          readyCompleter.complete();
          initSub?.cancel();
        }
      });

      _sendCommand('uci');
      _sendCommand('isready');

      await readyCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          initSub?.cancel();
        },
      );

      _isReady = true;
    } catch (_) {
      _isReady = false;
    } finally {
      _initialising = false;
    }
  }

  bool get isReady => _isReady;

  // ── Per-GM configuration ─────────────────────────────────────────────────

  /// Apply the GM's UCI options. Call once per game session.
  void applyPersona(String gmName) {
    if (!_isReady) return;
    final opts = personaOptions(gmName);
    _sendCommand('setoption name Skill Level value ${opts['skillLevel']}');
    _sendCommand('setoption name Contempt value ${opts['contempt']}');
    _sendCommand('setoption name UCI_LimitStrength value false');
    _sendCommand('ucinewgame');
  }

  // ── Move generation ──────────────────────────────────────────────────────

  /// Ask Stockfish for the best move for the given FEN.
  ///
  /// IMPORTANT: does NOT maintain a permanent stdout listener.
  /// Opens a dedicated listener per call so no messages are swallowed.
  Future<String?> getBestMove(
    String fen, {
    required String gmName,
  }) async {
    if (!_isReady || _stockfish == null) return null;

    final opts = personaOptions(gmName);
    final moveTime = opts['moveTime']!;

    final completer = Completer<String?>();
    bool completed = false;
    StreamSubscription<String>? sub;

    sub = _stockfish!.stdout.listen((line) {
      if (completed) return;
      if (line.startsWith('bestmove')) {
        completed = true;
        sub?.cancel();
        final parts = line.split(' ');
        if (parts.length >= 2 && parts[1] != '(none)') {
          completer.complete(parts[1]);
        } else {
          completer.complete(null);
        }
      }
    });

    // Fresh position then go
    _sendCommand('position fen $fen');
    _sendCommand('go movetime $moveTime');

    // Timeout = movetime + generous buffer
    return completer.future.timeout(
      Duration(milliseconds: moveTime + 3000),
      onTimeout: () {
        completed = true;
        sub?.cancel();
        _sendCommand('stop');
        return null;
      },
    );
  }

  // ── Internals ────────────────────────────────────────────────────────────

  void _sendCommand(String command) {
    _stockfish?.stdin = command;
  }

  void dispose() {
    _sendCommand('quit');
    _stockfish = null;
    _isReady = false;
    _initialising = false;
  }
}
