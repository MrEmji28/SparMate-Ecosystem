"""
Training Data Generator for SparMate Blunder Classification.

Generates synthetic training data that simulates the feature distributions
extracted from the Lichess open database. This module creates realistic
blunder scenarios across all 8 BKT skill categories, producing data that
matches the statistical properties of intermediate-level (ELO 1200–1600)
amateur chess games.

Reference: Milestone 2, Section 4.4 — "The dataset comprised millions of
anonymized amateur chess matches extracted from the open-source Lichess database."

Categories (mapped to BKT skills):
    0: tactical_oversight    — Missed tactics (forks, pins, skewers, discoveries)
    1: positional_error      — Poor strategic decisions (weak squares, bad trades)
    2: endgame_fundamentals  — Endgame technique failures (opposition, conversion)
    3: opening_theory        — Opening principles violated (development, center)
    4: king_safety           — King left exposed or castle compromised
    5: pawn_structure        — Doubled, isolated, or backwards pawns created
    6: piece_coordination    — Passive pieces, uncoordinated placement
    7: time_management       — Blunders caused by time pressure
"""

import random
import numpy as np
from feature_engineering import FEATURE_NAMES, NUM_FEATURES


# ── Category Labels ──────────────────────────────────────────────────────

CATEGORIES = [
    "tactical_oversight",
    "positional_error",
    "endgame_fundamentals",
    "opening_theory",
    "king_safety",
    "pawn_structure",
    "piece_coordination",
    "time_management",
]

CATEGORY_TO_INDEX = {cat: i for i, cat in enumerate(CATEGORIES)}
INDEX_TO_CATEGORY = {i: cat for i, cat in enumerate(CATEGORIES)}
NUM_CATEGORIES = len(CATEGORIES)


# ── Feature Distribution Profiles ────────────────────────────────────────

def _rand(low: float, high: float) -> float:
    """Uniform random with some Gaussian noise for realism."""
    base = random.uniform(low, high)
    noise = random.gauss(0, (high - low) * 0.05)
    return base + noise


def _clamp(val: float, low: float = 0.0, high: float = 1.0) -> float:
    return max(low, min(high, val))


def generate_tactical_oversight() -> list[float]:
    """
    Tactical oversights: Large CP loss, capture/check available but missed.
    Occurs in middlegame, high piece tension.
    """
    cp_loss = _rand(150, 600)           # Large material loss
    return [
        cp_loss,                         # cp_loss
        _clamp(cp_loss / 500),           # cp_loss_normalized
        _rand(0.5, 3.0),                # eval_before (was winning or equal)
        _rand(-3.0, -0.5),              # eval_after
        1.0 if random.random() > 0.4 else 0.0,  # eval_was_winning
        1.0 if random.random() > 0.7 else 0.0,  # eval_was_equal
        0.0,                             # eval_was_losing
        0.5,                             # game_phase (middlegame)
        _rand(15, 35),                  # move_number
        _rand(16, 28),                  # total_pieces
        0.0,                             # is_opening
        1.0,                             # is_middlegame
        0.0,                             # is_endgame
        _rand(-1, 3),                   # material_balance
        _rand(50, 75),                  # material_total
        1.0 if random.random() > 0.3 else 0.0,  # has_queens
        _rand(0, 2),                    # minor_piece_imbalance
        _rand(1, 4),                    # pieces_en_prise (HIGH — key signal)
        _rand(3, 9),                    # hanging_material_value (HIGH)
        1.0 if random.random() > 0.2 else 0.0,  # capture_available (HIGH)
        1.0 if random.random() > 0.5 else 0.0,  # check_available
        _rand(0.4, 1.0),               # fork_potential (HIGH)
        _rand(0.1, 0.5),               # own_king_exposure
        _rand(0.2, 0.6),               # opp_king_exposure
        _rand(0.5, 1.0),               # own_king_pawn_shield
        1.0 if random.random() > 0.3 else 0.0,  # king_has_castled
        _rand(0, 1),                    # doubled_pawns
        _rand(0, 1),                    # isolated_pawns
        _rand(0, 2),                    # passed_pawns
        _rand(2, 4),                    # pawn_islands
        0.0,                             # pawn_structure_change (LOW)
        _rand(0.4, 0.8),               # piece_mobility
        _rand(0.6, 1.0),               # pieces_developed
        1.0 if random.random() > 0.5 else 0.0,  # rooks_connected
        1.0 if random.random() > 0.5 else 0.0,  # bishop_pair
        _rand(0.3, 0.9),               # time_remaining_pct
        0.0 if random.random() > 0.3 else 1.0,  # time_pressure (usually not)
        _rand(-0.3, 0.3),              # time_delta
        1.0 if random.random() > 0.7 else 0.0,  # is_recapture
        0.0 if random.random() > 0.3 else 1.0,  # move_is_pawn_push
        1.0 if random.random() > 0.3 else 0.0,  # move_is_piece_move
        1.0 if random.random() > 0.2 else 0.0,  # best_move_was_capture (HIGH)
        _rand(0.5, 0.9),               # position_complexity (HIGH)
    ]


def generate_positional_error() -> list[float]:
    """
    Positional errors: Moderate CP loss, closed positions, no tactics available.
    Subtle strategic degradation.
    """
    cp_loss = _rand(50, 200)
    return [
        cp_loss,
        _clamp(cp_loss / 500),
        _rand(-0.5, 1.5),
        _rand(-2.0, -0.3),
        0.0 if random.random() > 0.3 else 1.0,
        1.0 if random.random() > 0.3 else 0.0,  # Usually equal positions
        0.0 if random.random() > 0.8 else 1.0,
        _rand(0.3, 0.7),               # Middlegame, sometimes late opening
        _rand(12, 30),
        _rand(18, 28),
        0.0 if random.random() > 0.3 else 1.0,
        1.0 if random.random() > 0.3 else 0.0,
        0.0,
        _rand(-1, 1),
        _rand(55, 78),
        1.0 if random.random() > 0.4 else 0.0,
        _rand(0, 1),
        _rand(0, 1),                    # pieces_en_prise (LOW — key)
        _rand(0, 2),                    # hanging_value (LOW)
        0.0 if random.random() > 0.3 else 1.0,  # capture_available (LOW)
        0.0,                             # check_available (LOW)
        _rand(0.0, 0.3),               # fork_potential (LOW)
        _rand(0.1, 0.4),
        _rand(0.1, 0.4),
        _rand(0.5, 1.0),
        1.0 if random.random() > 0.2 else 0.0,
        _rand(0, 2),                    # doubled_pawns (moderate)
        _rand(0, 2),                    # isolated_pawns (moderate)
        _rand(0, 1),
        _rand(2, 5),                    # pawn_islands (can be high)
        0.0 if random.random() > 0.4 else 1.0,
        _rand(0.2, 0.5),               # piece_mobility (LOW — key)
        _rand(0.5, 0.9),
        0.0 if random.random() > 0.6 else 1.0,
        1.0 if random.random() > 0.5 else 0.0,
        _rand(0.4, 0.9),
        0.0,
        _rand(-0.2, 0.2),
        0.0,
        1.0 if random.random() > 0.5 else 0.0,
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.6 else 1.0,
        _rand(0.2, 0.5),               # position_complexity (LOW — quiet)
    ]


def generate_endgame_fundamentals() -> list[float]:
    """
    Endgame mistakes: Low piece count, endgame phase, conversion failures.
    """
    cp_loss = _rand(80, 400)
    return [
        cp_loss,
        _clamp(cp_loss / 500),
        _rand(0.5, 5.0),               # Was often winning
        _rand(-1.0, 1.0),              # Threw away the win
        1.0 if random.random() > 0.3 else 0.0,
        0.0 if random.random() > 0.6 else 1.0,
        0.0,
        1.0,                             # game_phase = endgame (KEY)
        _rand(35, 60),                  # Late move number
        _rand(4, 10),                   # Low piece count (KEY)
        0.0,
        0.0,
        1.0,                             # is_endgame (KEY)
        _rand(0, 4),                    # material_balance (often winning)
        _rand(10, 30),                  # material_total (LOW)
        0.0,                             # has_queens (usually no)
        _rand(0, 1),
        _rand(0, 2),
        _rand(0, 3),
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.7 else 1.0,
        _rand(0.0, 0.3),
        _rand(0.3, 0.8),               # own_king_exposure (active king)
        _rand(0.3, 0.8),               # opp_king_exposure
        _rand(0.0, 0.5),               # pawn_shield (irrelevant in endgame)
        1.0 if random.random() > 0.5 else 0.0,
        _rand(0, 1),
        _rand(0, 1),
        _rand(1, 4),                    # passed_pawns (KEY — endgame focus)
        _rand(1, 3),
        0.0 if random.random() > 0.4 else 1.0,
        _rand(0.3, 0.7),
        _rand(0.3, 0.6),               # pieces_developed (fewer pieces)
        0.0 if random.random() > 0.5 else 1.0,
        0.0,                             # bishop_pair (rare in endgame)
        _rand(0.2, 0.6),               # time often running lower
        0.0 if random.random() > 0.5 else 1.0,
        _rand(-0.2, 0.3),
        0.0,
        1.0 if random.random() > 0.6 else 0.0,  # Pawn moves common
        0.0 if random.random() > 0.6 else 1.0,
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0.2, 0.5),
    ]


def generate_opening_theory() -> list[float]:
    """
    Opening theory violations: Early moves, development issues, center neglect.
    """
    cp_loss = _rand(30, 180)
    return [
        cp_loss,
        _clamp(cp_loss / 500),
        _rand(-0.3, 0.5),              # Usually equal or slight
        _rand(-1.5, -0.2),
        0.0,
        1.0,                             # eval_was_equal (KEY — opening)
        0.0,
        0.0,                             # game_phase = opening (KEY)
        _rand(3, 12),                   # Early move number (KEY)
        _rand(26, 32),                  # Most pieces still on board
        1.0,                             # is_opening (KEY)
        0.0,
        0.0,
        _rand(-0.5, 0.5),
        _rand(70, 80),                  # material_total (HIGH — all pieces)
        1.0,                             # has_queens
        _rand(0, 1),
        _rand(0, 1),
        _rand(0, 2),
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.8 else 1.0,
        _rand(0.0, 0.2),
        _rand(0.0, 0.2),               # Kings usually safe
        _rand(0.0, 0.2),
        _rand(0.8, 1.0),               # Full pawn shield
        0.0 if random.random() > 0.6 else 1.0,  # Often NOT castled yet (KEY)
        _rand(0, 1),
        _rand(0, 1),
        0.0,                             # No passed pawns in opening
        _rand(1, 2),
        0.0 if random.random() > 0.3 else 1.0,
        _rand(0.3, 0.6),
        _rand(0.1, 0.5),               # pieces_developed (LOW — key signal)
        0.0,
        1.0 if random.random() > 0.5 else 0.0,
        _rand(0.7, 1.0),               # Lots of time remaining
        0.0,                             # No time pressure
        _rand(-0.1, 0.1),
        0.0,
        1.0 if random.random() > 0.5 else 0.0,  # Pawn pushes common in opening
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.7 else 1.0,
        _rand(0.4, 0.7),
    ]


def generate_king_safety() -> list[float]:
    """
    King safety blunders: Exposed king, broken pawn shield, under attack.
    """
    cp_loss = _rand(100, 500)
    return [
        cp_loss,
        _clamp(cp_loss / 500),
        _rand(0.0, 2.0),
        _rand(-4.0, -1.0),             # Big eval drop — king exposed
        0.0 if random.random() > 0.5 else 1.0,
        1.0 if random.random() > 0.5 else 0.0,
        0.0,
        0.5,                             # Middlegame
        _rand(15, 35),
        _rand(18, 28),
        0.0,
        1.0,
        0.0,
        _rand(-1, 2),
        _rand(50, 75),
        1.0,                             # Queens on board (KEY — attacks)
        _rand(0, 2),
        _rand(1, 3),
        _rand(1, 5),
        1.0 if random.random() > 0.4 else 0.0,
        1.0 if random.random() > 0.3 else 0.0,  # Checks often available
        _rand(0.2, 0.6),
        _rand(0.5, 1.0),               # own_king_exposure (HIGH — KEY)
        _rand(0.1, 0.5),
        _rand(0.0, 0.4),               # own_king_pawn_shield (LOW — KEY)
        0.0 if random.random() > 0.4 else 1.0,  # Often NOT castled or shield broken
        _rand(0, 1),
        _rand(0, 1),
        _rand(0, 1),
        _rand(2, 4),
        1.0 if random.random() > 0.5 else 0.0,  # Pawn structure change
        _rand(0.3, 0.7),
        _rand(0.5, 0.9),
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0.3, 0.8),
        0.0 if random.random() > 0.6 else 1.0,
        _rand(-0.3, 0.3),
        0.0,
        1.0 if random.random() > 0.6 else 0.0,  # Pawn moves that weaken king
        0.0 if random.random() > 0.6 else 1.0,
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0.5, 0.9),               # Complex positions
    ]


def generate_pawn_structure() -> list[float]:
    """
    Pawn structure damage: Creating weaknesses, isolated/doubled pawns.
    """
    cp_loss = _rand(30, 150)            # Often subtle
    return [
        cp_loss,
        _clamp(cp_loss / 500),
        _rand(-0.5, 1.0),
        _rand(-1.5, 0.0),
        0.0 if random.random() > 0.6 else 1.0,
        1.0 if random.random() > 0.4 else 0.0,
        0.0 if random.random() > 0.9 else 1.0,
        _rand(0.3, 0.7),
        _rand(10, 30),
        _rand(18, 28),
        0.0 if random.random() > 0.4 else 1.0,
        1.0 if random.random() > 0.4 else 0.0,
        0.0,
        _rand(-1, 1),
        _rand(55, 75),
        1.0 if random.random() > 0.4 else 0.0,
        _rand(0, 1),
        _rand(0, 1),
        _rand(0, 2),
        0.0 if random.random() > 0.5 else 1.0,
        0.0,
        _rand(0.0, 0.2),
        _rand(0.1, 0.4),
        _rand(0.1, 0.4),
        _rand(0.5, 1.0),
        1.0 if random.random() > 0.3 else 0.0,
        _rand(1, 3),                    # doubled_pawns (HIGH — KEY)
        _rand(1, 3),                    # isolated_pawns (HIGH — KEY)
        _rand(0, 1),
        _rand(3, 5),                    # pawn_islands (HIGH — KEY)
        1.0,                             # pawn_structure_change (KEY)
        _rand(0.3, 0.6),
        _rand(0.4, 0.8),
        0.0 if random.random() > 0.5 else 1.0,
        1.0 if random.random() > 0.5 else 0.0,
        _rand(0.4, 0.9),
        0.0,
        _rand(-0.2, 0.2),
        0.0,
        1.0,                             # move_is_pawn_push (KEY)
        0.0,                             # NOT a piece move
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0.3, 0.6),
    ]


def generate_piece_coordination() -> list[float]:
    """
    Piece coordination failures: Passive pieces, lack of harmony.
    """
    cp_loss = _rand(40, 180)
    return [
        cp_loss,
        _clamp(cp_loss / 500),
        _rand(-0.3, 1.0),
        _rand(-2.0, -0.3),
        0.0 if random.random() > 0.5 else 1.0,
        1.0 if random.random() > 0.5 else 0.0,
        0.0 if random.random() > 0.8 else 1.0,
        0.5,
        _rand(15, 35),
        _rand(16, 26),
        0.0,
        1.0,
        0.0,
        _rand(-1, 1),
        _rand(45, 70),
        1.0 if random.random() > 0.4 else 0.0,
        _rand(0, 2),
        _rand(0, 2),
        _rand(0, 3),
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.7 else 1.0,
        _rand(0.1, 0.4),
        _rand(0.1, 0.4),
        _rand(0.2, 0.5),
        _rand(0.4, 0.9),
        1.0 if random.random() > 0.3 else 0.0,
        _rand(0, 1),
        _rand(0, 2),
        _rand(0, 1),
        _rand(2, 4),
        0.0 if random.random() > 0.7 else 1.0,
        _rand(0.1, 0.3),               # piece_mobility (VERY LOW — KEY)
        _rand(0.3, 0.6),               # pieces_developed (LOW — KEY)
        0.0,                             # rooks_connected (NO — KEY)
        0.0,                             # bishop_pair (NO — KEY)
        _rand(0.4, 0.8),
        0.0 if random.random() > 0.7 else 1.0,
        _rand(-0.2, 0.2),
        0.0,
        0.0 if random.random() > 0.4 else 1.0,
        1.0 if random.random() > 0.4 else 0.0,
        0.0 if random.random() > 0.6 else 1.0,
        _rand(0.3, 0.6),
    ]


def generate_time_management() -> list[float]:
    """
    Time management blunders: Under severe time pressure, clock-related errors.
    """
    cp_loss = _rand(100, 600)           # Can be very large under time pressure
    return [
        cp_loss,
        _clamp(cp_loss / 500),
        _rand(-1.0, 2.0),              # Any position
        _rand(-5.0, -0.5),             # Big drops
        0.0 if random.random() > 0.5 else 1.0,
        1.0 if random.random() > 0.5 else 0.0,
        0.0 if random.random() > 0.7 else 1.0,
        _rand(0.3, 0.8),               # Any phase
        _rand(25, 50),                  # Later in the game
        _rand(10, 24),
        0.0,
        1.0 if random.random() > 0.4 else 0.0,
        0.0 if random.random() > 0.4 else 1.0,
        _rand(-2, 2),
        _rand(30, 65),
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0, 2),
        _rand(0, 3),
        _rand(0, 5),
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0.1, 0.5),
        _rand(0.1, 0.5),
        _rand(0.2, 0.6),
        _rand(0.3, 0.8),
        1.0 if random.random() > 0.4 else 0.0,
        _rand(0, 2),
        _rand(0, 2),
        _rand(0, 2),
        _rand(2, 4),
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0.3, 0.7),
        _rand(0.4, 0.8),
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0.0, 0.1),               # time_remaining_pct (VERY LOW — KEY)
        1.0,                             # time_pressure (KEY)
        _rand(0.5, 2.0),               # time_delta (HIGH — rushed — KEY)
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.5 else 1.0,
        0.0 if random.random() > 0.5 else 1.0,
        _rand(0.4, 0.8),
    ]


# ── Generator Registry ───────────────────────────────────────────────────

GENERATORS = {
    0: generate_tactical_oversight,
    1: generate_positional_error,
    2: generate_endgame_fundamentals,
    3: generate_opening_theory,
    4: generate_king_safety,
    5: generate_pawn_structure,
    6: generate_piece_coordination,
    7: generate_time_management,
}


def generate_dataset(
    n_samples: int = 10000,
    seed: int = 42,
    class_weights: dict[int, float] | None = None,
) -> tuple[np.ndarray, np.ndarray]:
    """
    Generate a labeled dataset of blunder feature vectors.

    Args:
        n_samples:     Total number of samples to generate
        seed:          Random seed for reproducibility
        class_weights: Optional dict of class_index → relative weight.
                       Default distributes samples proportionally to real-world
                       frequencies (tactical errors are most common).

    Returns:
        Tuple of (X, y) where X is (n_samples, NUM_FEATURES) and
        y is (n_samples,) with integer class labels
    """
    random.seed(seed)
    np.random.seed(seed)

    if class_weights is None:
        # Real-world frequency: tactical errors are most common
        class_weights = {
            0: 0.22,   # tactical_oversight
            1: 0.15,   # positional_error
            2: 0.10,   # endgame_fundamentals
            3: 0.13,   # opening_theory
            4: 0.12,   # king_safety
            5: 0.10,   # pawn_structure
            6: 0.08,   # piece_coordination
            7: 0.10,   # time_management
        }

    # Calculate samples per class
    total_weight = sum(class_weights.values())
    class_samples = {}
    remaining = n_samples
    for cls in sorted(class_weights.keys()):
        if cls == max(class_weights.keys()):
            class_samples[cls] = remaining
        else:
            count = int(n_samples * class_weights[cls] / total_weight)
            class_samples[cls] = count
            remaining -= count

    X = []
    y = []

    for cls, count in class_samples.items():
        generator = GENERATORS[cls]
        for _ in range(count):
            features = generator()
            # Add slight cross-class noise for realism (makes classification harder)
            for j in range(len(features)):
                features[j] += random.gauss(0, 0.02)
            X.append(features)
            y.append(cls)

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int64)

    # Shuffle
    indices = np.arange(len(X))
    np.random.shuffle(indices)
    X = X[indices]
    y = y[indices]

    return X, y


if __name__ == "__main__":
    X, y = generate_dataset(n_samples=100)
    print(f"Generated dataset: X.shape={X.shape}, y.shape={y.shape}")
    print(f"Class distribution: {dict(zip(*np.unique(y, return_counts=True)))}")
    print(f"Feature range: min={X.min():.3f}, max={X.max():.3f}")
