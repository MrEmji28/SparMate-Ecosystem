"""
Feature Engineering for SparMate Blunder Classification.

Extracts chess-specific features from pre-blunder and post-blunder positions
to feed the Random Forest / SVM classifier. This module implements the
"pre-blunder and post-blunder evaluation metrics" described in
Milestone 2, Section 4.4.

Features are designed to distinguish:
  - Tactical oversights (e.g., hanging a piece, missing a fork)
  - Positional errors (e.g., ruining pawn structure, weakening king position)
  - Endgame fundamentals (e.g., incorrect king activation, drawn endgames)
  - Opening theory violations (e.g., premature attacks, bad development)
  - King safety blunders (e.g., weakening king shelter under pressure)
  - Pawn structure damage (e.g., creating doubled/isolated pawns)
  - Piece coordination failures (e.g., uncoordinated pieces, passive placement)
  - Time management issues (e.g., blunders under time pressure)

Each feature vector is a dict that can be converted to a flat numpy array
for model training.
"""

import math

# ── Constants ────────────────────────────────────────────────────────────

# Piece values (standard centipawn-equivalent)
PIECE_VALUES = {
    "P": 100, "N": 320, "B": 330, "R": 500, "Q": 900, "K": 0,
    "p": 100, "n": 320, "b": 330, "r": 500, "q": 900, "k": 0,
}

# Center squares for development assessment
CENTER_SQUARES = {"d4", "d5", "e4", "e5"}
EXTENDED_CENTER = {"c3", "c4", "c5", "c6", "d3", "d6", "e3", "e6", "f3", "f4", "f5", "f6"}

# King safety pawn shelter squares (relative to king file)
KING_SHELTER_FILES_KINGSIDE = {"f", "g", "h"}
KING_SHELTER_FILES_QUEENSIDE = {"a", "b", "c"}

# Feature names in the order the model expects
FEATURE_NAMES = [
    # Evaluation delta features
    "cp_loss",                     # Centipawn loss (eval_before - eval_after)
    "cp_loss_normalized",          # CP loss normalized to [0, 1]
    "eval_before",                 # Engine evaluation before the move
    "eval_after",                  # Engine evaluation after the move
    "eval_was_winning",            # 1 if position was clearly winning before
    "eval_was_equal",              # 1 if position was roughly equal before
    "eval_was_losing",             # 1 if position was losing before

    # Game phase features
    "game_phase",                  # 0=opening, 0.5=middlegame, 1=endgame
    "move_number",                 # Move number in the game
    "total_pieces",                # Total pieces on the board
    "is_opening",                  # 1 if opening phase (move < 15)
    "is_middlegame",               # 1 if middlegame
    "is_endgame",                  # 1 if endgame (few pieces)

    # Material features
    "material_balance",            # Material advantage (positive = white advantage)
    "material_total",              # Total material on board
    "has_queens",                  # 1 if both queens are on the board
    "minor_piece_imbalance",       # Difference in minor pieces

    # Tactical tension features
    "pieces_en_prise",             # Number of undefended pieces
    "hanging_material_value",      # Value of hanging pieces
    "capture_available",           # 1 if a capture was available
    "check_available",             # 1 if a check was available
    "fork_potential",              # Heuristic fork potential score

    # King safety features
    "own_king_exposure",           # King exposure score (0=safe, 1=exposed)
    "opp_king_exposure",           # Opponent king exposure
    "own_king_pawn_shield",        # Quality of pawn shield (0-3 pawns present)
    "king_has_castled",            # 1 if the player has castled

    # Pawn structure features
    "doubled_pawns",               # Number of doubled pawns
    "isolated_pawns",              # Number of isolated pawns
    "passed_pawns",                # Number of passed pawns
    "pawn_islands",                # Number of pawn islands
    "pawn_structure_change",       # 1 if pawn structure changed with this move

    # Piece coordination features
    "piece_mobility",              # Estimated piece mobility score
    "pieces_developed",            # Number of pieces off starting squares
    "rooks_connected",             # 1 if rooks are connected
    "bishop_pair",                 # 1 if player has bishop pair

    # Time features
    "time_remaining_pct",          # Percentage of clock remaining (0-1)
    "time_pressure",               # 1 if under severe time pressure
    "time_delta",                  # Time spent on this move relative to average

    # Move context features
    "is_recapture",                # 1 if this was a recapture situation
    "move_is_pawn_push",           # 1 if the blundering move was a pawn push
    "move_is_piece_move",          # 1 if the blundering move was a piece move
    "best_move_was_capture",       # 1 if the engine's best move was a capture
    "position_complexity",         # Heuristic complexity score (num legal moves)
]

NUM_FEATURES = len(FEATURE_NAMES)


# ── Feature Extraction ───────────────────────────────────────────────────

def extract_features(
    eval_before: float,
    eval_after: float,
    move_number: int,
    total_pieces: int = 24,
    material_white: int = 3900,
    material_black: int = 3900,
    has_queens: bool = True,
    minor_white: int = 4,
    minor_black: int = 4,
    pieces_en_prise: int = 0,
    hanging_value: int = 0,
    capture_available: bool = False,
    check_available: bool = False,
    fork_potential: float = 0.0,
    own_king_exposure: float = 0.0,
    opp_king_exposure: float = 0.0,
    own_king_pawn_shield: int = 3,
    king_has_castled: bool = True,
    doubled_pawns: int = 0,
    isolated_pawns: int = 0,
    passed_pawns: int = 0,
    pawn_islands: int = 2,
    pawn_structure_changed: bool = False,
    piece_mobility: float = 0.5,
    pieces_developed: int = 6,
    rooks_connected: bool = False,
    bishop_pair: bool = True,
    time_remaining_pct: float = 0.75,
    time_pressure: bool = False,
    time_delta: float = 0.0,
    is_recapture: bool = False,
    move_is_pawn: bool = False,
    move_is_piece: bool = True,
    best_move_capture: bool = False,
    num_legal_moves: int = 30,
) -> dict[str, float]:
    """
    Extract a complete feature vector from a blunder position.

    Args:
        eval_before:  Engine evaluation (centipawns) before the blunder move
        eval_after:   Engine evaluation (centipawns) after the blunder move
        move_number:  Move number in the game
        total_pieces: Total pieces on the board (including pawns, excluding kings)
        ... (see parameter docstrings)

    Returns:
        Dictionary mapping feature names to float values
    """
    # ── Evaluation delta features ──
    cp_loss = eval_before - eval_after
    cp_loss_norm = min(1.0, max(0.0, cp_loss / 500.0))  # Normalize to [0, 1]
    eval_winning = 1.0 if eval_before > 150 else 0.0
    eval_equal = 1.0 if -150 <= eval_before <= 150 else 0.0
    eval_losing = 1.0 if eval_before < -150 else 0.0

    # ── Game phase ──
    if move_number <= 12:
        phase = 0.0
        is_op, is_mid, is_end = 1.0, 0.0, 0.0
    elif total_pieces <= 10:
        phase = 1.0
        is_op, is_mid, is_end = 0.0, 0.0, 1.0
    else:
        phase = 0.5
        is_op, is_mid, is_end = 0.0, 1.0, 0.0

    # ── Material ──
    mat_balance = (material_white - material_black) / 100.0
    mat_total = (material_white + material_black) / 100.0

    # ── Tactical tension ──
    fork_score = min(1.0, fork_potential)

    # ── Position complexity ──
    complexity = min(1.0, num_legal_moves / 45.0)

    return {
        "cp_loss":                  cp_loss,
        "cp_loss_normalized":       cp_loss_norm,
        "eval_before":              eval_before / 100.0,  # Normalize to pawns
        "eval_after":               eval_after / 100.0,
        "eval_was_winning":         eval_winning,
        "eval_was_equal":           eval_equal,
        "eval_was_losing":          eval_losing,
        "game_phase":               phase,
        "move_number":              float(move_number),
        "total_pieces":             float(total_pieces),
        "is_opening":               is_op,
        "is_middlegame":            is_mid,
        "is_endgame":               is_end,
        "material_balance":         mat_balance,
        "material_total":           mat_total,
        "has_queens":               1.0 if has_queens else 0.0,
        "minor_piece_imbalance":    float(abs(minor_white - minor_black)),
        "pieces_en_prise":          float(pieces_en_prise),
        "hanging_material_value":   float(hanging_value) / 100.0,
        "capture_available":        1.0 if capture_available else 0.0,
        "check_available":          1.0 if check_available else 0.0,
        "fork_potential":           fork_score,
        "own_king_exposure":        own_king_exposure,
        "opp_king_exposure":        opp_king_exposure,
        "own_king_pawn_shield":     float(own_king_pawn_shield) / 3.0,
        "king_has_castled":         1.0 if king_has_castled else 0.0,
        "doubled_pawns":            float(doubled_pawns),
        "isolated_pawns":           float(isolated_pawns),
        "passed_pawns":             float(passed_pawns),
        "pawn_islands":             float(pawn_islands),
        "pawn_structure_change":    1.0 if pawn_structure_changed else 0.0,
        "piece_mobility":           piece_mobility,
        "pieces_developed":         float(pieces_developed) / 8.0,
        "rooks_connected":          1.0 if rooks_connected else 0.0,
        "bishop_pair":              1.0 if bishop_pair else 0.0,
        "time_remaining_pct":       time_remaining_pct,
        "time_pressure":            1.0 if time_pressure else 0.0,
        "time_delta":               time_delta,
        "is_recapture":             1.0 if is_recapture else 0.0,
        "move_is_pawn_push":        1.0 if move_is_pawn else 0.0,
        "move_is_piece_move":       1.0 if move_is_piece else 0.0,
        "best_move_was_capture":    1.0 if best_move_capture else 0.0,
        "position_complexity":      complexity,
    }


def features_to_array(features: dict[str, float]) -> list[float]:
    """Convert a feature dict to an ordered list for model input."""
    return [features[name] for name in FEATURE_NAMES]
