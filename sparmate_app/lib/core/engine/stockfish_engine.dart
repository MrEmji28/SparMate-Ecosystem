import 'dart:async';
import 'package:stockfish/stockfish.dart';

class StockfishEngine {
  static final StockfishEngine _instance = StockfishEngine._internal();
  factory StockfishEngine() => _instance;
  StockfishEngine._internal();

  Stockfish? _stockfish;
  StreamSubscription<String>? _stdoutSubscription;
  bool _isReady = false;

  /// Start the Stockfish engine and listen to its output
  Future<void> init() async {
    if (_stockfish != null) return;
    
    // Wait for the isolate to start and reach the 'ready' state
    _stockfish = await stockfishAsync();
    _isReady = true;
    
    _stdoutSubscription = _stockfish!.stdout.listen((line) {
      // Print engine output to console for debugging
      // print('[Stockfish] $line');
    });

    // Send UCI initialization commands
    _sendCommand('uci');
    _sendCommand('isready');
  }

  /// Send a raw command to the Stockfish stdin
  void _sendCommand(String command) {
    if (_stockfish == null) {
      print('[Stockfish Error] Engine not initialized.');
      return;
    }
    _stockfish!.stdin = command;
  }

  /// Update Stockfish's heuristics based on persona skill level
  void setPersona(int skillLevel) {
    // Skill Level ranges from 0 (weak) to 20 (strong)
    _sendCommand('setoption name Skill Level value $skillLevel');
  }

  /// Request the engine to evaluate a FEN position
  /// Returns a Future that completes with the bestmove string (e.g. "e2e4")
  Future<String> getBestMove(String fen, {int depth = 15}) {
    if (!_isReady) {
      return Future.error('Engine not ready');
    }

    final completer = Completer<String>();
    StreamSubscription<String>? tempSub;

    // Listen temporarily for the 'bestmove' output
    tempSub = _stockfish!.stdout.listen((line) {
      if (line.startsWith('bestmove')) {
        final parts = line.split(' ');
        if (parts.length >= 2) {
          completer.complete(parts[1]); // The move itself
        } else {
          completer.completeError('Failed to parse bestmove: $line');
        }
        tempSub?.cancel();
      }
    });

    _sendCommand('position fen $fen');
    _sendCommand('go depth $depth');

    return completer.future;
  }

  /// Safely dispose of the engine resources
  void dispose() {
    _stdoutSubscription?.cancel();
    _sendCommand('quit');
    _stockfish = null;
    _isReady = false;
  }
}
