# Stockfish Engine Integration (Dart FFI)

This module handles the integration of the Stockfish C++ binary directly into the SparMate Flutter app.

By utilizing Dart's Foreign Function Interface (FFI) via the `stockfish` package, we eliminate the need for cloud-based chess calculations during gameplay. This satisfies the Milestone 2 architectural requirement for zero-latency, offline heuristic sparring.

## Files

- `stockfish_engine.dart`: A singleton wrapper that manages the lifecycle of the Stockfish isolate and provides a clean API for communicating via the Universal Chess Interface (UCI) protocol.

## Usage

### 1. Initialization

Before querying the engine, it must be initialized to spawn the isolate and set up the `stdout` stream listener.

```dart
final engine = StockfishEngine();
engine.init();
```

### 2. Heuristic Engineering (Personas)

You can manipulate Stockfish's constraints by setting the skill level. This allows the engine to mimic different Grandmaster personas (e.g., a low skill level for a beginner persona, or a high skill level for an advanced persona).

```dart
// Skill level ranges from 0 (weak) to 20 (strong)
engine.setPersona(10); 
```

### 3. Calculating the Best Move

To ask the engine to evaluate a board position, provide the FEN (Forsyth-Edwards Notation) string and a target depth.

```dart
String fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
String bestMove = await engine.getBestMove(fen, depth: 15);
print("The engine recommends: $bestMove"); // e.g., "e2e4"
```

*Note: Deep calculations (e.g., depth > 15) may take longer depending on the mobile device's CPU. Adjust the depth based on the desired response time and difficulty.*

### 4. Cleanup

When the user leaves the sparring session or closes the app, dispose of the engine to free up memory and terminate the isolate.

```dart
engine.dispose();
```

## How It Works

1. The `stockfish` pub.dev package includes pre-compiled C++ binaries for iOS and Android.
2. The `StockfishEngine` class writes commands (like `position fen ...` and `go depth ...`) to the engine's `stdin`.
3. The engine calculates the moves asynchronously in a separate isolate (so the Flutter UI does not freeze).
4. A stream listener captures the engine's `stdout`, parses the `bestmove` response, and resolves the Dart Future.
