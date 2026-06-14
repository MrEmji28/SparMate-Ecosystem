import 'package:flutter/material.dart';
import 'package:sparmate/core/engine/stockfish_engine.dart';

class EngineTestScreen extends StatefulWidget {
  const EngineTestScreen({super.key});

  @override
  State<EngineTestScreen> createState() => _EngineTestScreenState();
}

class _EngineTestScreenState extends State<EngineTestScreen> {
  final StockfishEngine _engine = StockfishEngine();
  final TextEditingController _fenController = TextEditingController(
    text: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1', // Starting position
  );
  
  String _bestMove = '';
  bool _isCalculating = false;

  bool _isEngineReady = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    await _engine.init();
    if (mounted) {
      setState(() {
        _isEngineReady = true;
      });
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    _fenController.dispose();
    super.dispose();
  }

  void _calculateBestMove() async {
    setState(() {
      _isCalculating = true;
      _bestMove = '';
    });

    try {
      final move = await _engine.getBestMove(_fenController.text, depth: 10);
      setState(() {
        _bestMove = move;
      });
    } catch (e) {
      setState(() {
        _bestMove = 'Error: $e';
      });
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stockfish FFI Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter FEN:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'FEN string',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (!_isEngineReady || _isCalculating) ? null : _calculateBestMove,
              child: _isCalculating 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : Text(_isEngineReady ? 'Calculate Best Move (Depth 10)' : 'Starting Engine...'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Result (Best Move):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Text(
                _bestMove.isEmpty ? 'Waiting...' : _bestMove,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
