"""
Bayesian Knowledge Tracing (BKT) Engine for SparMate.

Implements the Corbett & Anderson (1995) methodology for tracking
student mastery of cognitive chess skills. This is the core
algorithmic component described in Milestone 2, Section 4.5.

The BKT model uses four parameters per skill:
  - P(L₀): Prior probability of mastery (initial knowledge)
  - P(T):  Probability of learning (transition from unmastered to mastered)
  - P(G):  Probability of guessing (correct despite not knowing)
  - P(S):  Probability of slipping (incorrect despite knowing)
"""


# ── BKT Skill Parameters ─────────────────────────────────────────────────
# Each chess cognitive skill has its own calibrated BKT parameters.
# These would normally be trained from data; here we use expert-tuned values.

SKILL_PARAMETERS: dict[str, dict[str, float]] = {
    "tactical_oversight": {
        "p_learn": 0.10,   # Hard to learn — requires pattern recognition
        "p_guess": 0.15,   # Occasionally find tactics by accident
        "p_slip":  0.10,   # Known patterns still missed under pressure
    },
    "positional_error": {
        "p_learn": 0.08,   # Very slow to learn — requires deep understanding
        "p_guess": 0.10,   # Rarely guess positional ideas correctly
        "p_slip":  0.12,   # Even masters make positional slips
    },
    "endgame_fundamentals": {
        "p_learn": 0.12,   # Moderate — can be studied methodically
        "p_guess": 0.05,   # Very hard to guess endgame technique
        "p_slip":  0.08,   # Well-known patterns are reliable
    },
    "opening_theory": {
        "p_learn": 0.15,   # Fastest to learn — memorizable
        "p_guess": 0.20,   # Common moves can be guessed
        "p_slip":  0.15,   # Easy to forget specific lines
    },
    "king_safety": {
        "p_learn": 0.09,   # Requires intuition
        "p_guess": 0.12,   # Sometimes instinctive
        "p_slip":  0.10,   # Overconfidence leads to slips
    },
    "pawn_structure": {
        "p_learn": 0.08,   # Abstract concept — slow to internalize
        "p_guess": 0.08,   # Hard to guess structural consequences
        "p_slip":  0.10,   # Easy to damage structure under pressure
    },
    "piece_coordination": {
        "p_learn": 0.10,
        "p_guess": 0.10,
        "p_slip":  0.10,
    },
    "time_management": {
        "p_learn": 0.12,   # Behavioral — can improve with practice
        "p_guess": 0.15,   # Sometimes lucky with time
        "p_slip":  0.20,   # Very prone to slips under stress
    },
}

# Severity multipliers: how much each severity level impacts the update
SEVERITY_WEIGHTS: dict[str, float] = {
    "blunder":    1.0,   # Full BKT update
    "mistake":    0.7,   # Moderate impact
    "inaccuracy": 0.3,   # Minor impact
}


def update_mastery_after_incorrect(
    p_mastery: float,
    p_slip: float,
    p_guess: float,
    severity_weight: float = 1.0,
) -> float:
    """
    Bayesian update of mastery probability after an INCORRECT application.

    Uses Bayes' theorem:
        P(mastered | incorrect) = P(incorrect | mastered) * P(mastered)
                                  ─────────────────────────────────────
                                           P(incorrect)

    Where:
        P(incorrect | mastered) = P(slip)
        P(incorrect | not mastered) = 1 - P(guess)

    The severity_weight scales the update: 1.0 for blunders, less for mistakes.
    """
    # Numerator: probability of mastery AND slipping
    numerator = p_mastery * p_slip

    # Denominator: total probability of an incorrect answer
    denominator = numerator + ((1 - p_mastery) * (1 - p_guess))

    if denominator == 0:
        return p_mastery

    # Raw posterior
    posterior = numerator / denominator

    # Blend with prior based on severity (less severe = less update)
    blended = p_mastery + severity_weight * (posterior - p_mastery)

    return max(0.01, min(0.99, blended))


def update_mastery_after_correct(
    p_mastery: float,
    p_slip: float,
    p_guess: float,
) -> float:
    """
    Bayesian update of mastery probability after a CORRECT application.

    P(mastered | correct) = P(correct | mastered) * P(mastered)
                            ───────────────────────────────────
                                     P(correct)

    Where:
        P(correct | mastered) = 1 - P(slip)
        P(correct | not mastered) = P(guess)
    """
    numerator = p_mastery * (1 - p_slip)
    denominator = numerator + ((1 - p_mastery) * p_guess)

    if denominator == 0:
        return p_mastery

    posterior = numerator / denominator
    return max(0.01, min(0.99, posterior))


def apply_learning_transition(p_mastery: float, p_learn: float) -> float:
    """
    Apply the learning transition after any observation.

    P(L_n) = P(L_n | obs) + (1 - P(L_n | obs)) * P(T)

    This accounts for the possibility that the student learned
    from the experience regardless of the outcome.
    """
    return p_mastery + (1 - p_mastery) * p_learn


def process_match_blunders(
    current_matrix: dict[str, float],
    classified_blunders: list[dict],
) -> tuple[dict[str, float], list[str]]:
    """
    Process a list of classified blunders from a match and update
    the BKT mastery matrix.

    Args:
        current_matrix: Current BKT mastery probabilities per skill
        classified_blunders: List of dicts with 'category' and 'severity'

    Returns:
        Tuple of (updated_matrix, list_of_skills_updated)
    """
    updated_matrix = dict(current_matrix)
    skills_updated = set()

    for blunder in classified_blunders:
        skill = blunder.get("category", "")
        severity = blunder.get("severity", "mistake")

        if skill not in SKILL_PARAMETERS:
            continue

        params = SKILL_PARAMETERS[skill]
        severity_weight = SEVERITY_WEIGHTS.get(severity, 0.5)
        current_mastery = updated_matrix.get(skill, 0.5)

        # Step 1: Bayesian update (incorrect observation)
        posterior = update_mastery_after_incorrect(
            p_mastery=current_mastery,
            p_slip=params["p_slip"],
            p_guess=params["p_guess"],
            severity_weight=severity_weight,
        )

        # Step 2: Apply learning transition
        final = apply_learning_transition(posterior, params["p_learn"])

        updated_matrix[skill] = round(final, 4)
        skills_updated.add(skill)

    return updated_matrix, sorted(skills_updated)


def generate_training_plan(
    bkt_matrix: dict[str, float],
    elo_rating: int,
) -> dict:
    """
    Generate a personalized training plan based on the BKT matrix.

    Strategy:
    1. Identify the weakest skills (lowest mastery probability)
    2. Create a weekly plan that prioritizes those skills
    3. Mix activity types (lessons, puzzles, sparring)
    """
    # Sort skills by mastery (ascending = weakest first)
    sorted_skills = sorted(bkt_matrix.items(), key=lambda x: x[1])
    weakest = sorted_skills[:3]  # Top 3 weakest

    # Format skill names for display
    def format_skill(key: str) -> str:
        return key.replace("_", " ").title()

    weekly_focus = [format_skill(s[0]) for s in weakest]

    # Generate primary directive
    weakest_skill = format_skill(weakest[0][0])
    weakest_pct = round(weakest[0][1] * 100)
    primary_directive = (
        f"Your {weakest_skill} is at {weakest_pct}% mastery — this is your primary area "
        f"for improvement. Focus on targeted drills and deliberate practice in this area "
        f"before moving to your other weak areas: {', '.join(weekly_focus[1:])}."
    )

    # Map skills to activity types
    skill_activities = {
        "tactical_oversight":   ("Tactical Pattern Drill", "puzzle"),
        "positional_error":     ("Positional Strategy Lesson", "lesson"),
        "endgame_fundamentals": ("Endgame Technique Drill", "lesson"),
        "opening_theory":       ("Opening Repertoire Review", "lesson"),
        "king_safety":          ("King Safety Exercises", "puzzle"),
        "pawn_structure":       ("Pawn Structure Analysis", "lesson"),
        "piece_coordination":   ("Piece Coordination Puzzles", "puzzle"),
        "time_management":      ("Speed Puzzle Challenge", "puzzle"),
    }

    # Build weekly plan
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    plan_items = []

    for i, day in enumerate(days):
        if i < len(weakest):
            skill_key = weakest[i][0]
            activity, act_type = skill_activities.get(skill_key, ("General Practice", "lesson"))
        elif i == 5:
            # Saturday: sparring
            gm = "Petrosian" if weakest[0][0] in ["positional_error", "pawn_structure"] else "Tal"
            activity = f"Spar vs {gm}"
            act_type = "sparring"
        elif i == 6:
            # Sunday: review
            activity = "Weekly Game Review & Analysis"
            act_type = "lesson"
        else:
            # Cycle through weakest skills
            skill_key = weakest[i % len(weakest)][0]
            activity, act_type = skill_activities.get(skill_key, ("General Practice", "lesson"))

        plan_items.append({
            "day": day,
            "activity": activity,
            "duration_min": 30 if act_type == "sparring" else 20,
            "type": act_type,
        })

    return {
        "primary_directive": primary_directive,
        "weekly_focus": weekly_focus,
        "plan_items": plan_items,
    }
