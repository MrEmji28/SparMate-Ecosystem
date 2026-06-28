/// Data model for a single step in a lesson chapter.
///
/// Each step represents one teaching moment: a board position,
/// an optional animated move, highlighted squares, and instructor commentary.
class LessonStep {
  /// FEN string for the board position at this step.
  final String fen;

  /// Optional move to animate (e.g. 'e2e4'). Null means just show the position.
  final String? move;

  /// Squares to highlight (e.g. ['e4', 'd5']). Shows colored overlays.
  final List<String> highlights;

  /// Optional arrow annotations: list of [from, to] pairs (e.g. [['e2','e4']]).
  final List<List<String>> arrows;

  /// Instructor commentary — the teaching text for this step.
  final String commentary;

  /// Optional concept label (e.g. 'Center Control', 'Pin', 'Fork').
  final String? concept;

  const LessonStep({
    required this.fen,
    this.move,
    this.highlights = const [],
    this.arrows = const [],
    required this.commentary,
    this.concept,
  });
}
