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
    skill_level: str | None = None,
) -> dict:
    """
    Generate a personalized training plan based on the BKT matrix
    and the user's skill level from onboarding.

    Strategy:
    1. Identify the weakest skills (lowest mastery probability)
    2. Adjust difficulty and session durations based on skill_level
    3. Create a weekly plan that prioritizes those skills
    4. Mix activity types (lessons, puzzles, sparring)
    """
    # Sort skills by mastery (ascending = weakest first)
    sorted_skills = sorted(bkt_matrix.items(), key=lambda x: x[1])
    weakest = sorted_skills[:3]  # Top 3 weakest

    # Format skill names for display
    def format_skill(key: str) -> str:
        return key.replace("_", " ").title()

    weekly_focus = [format_skill(s[0]) for s in weakest]

    # Determine effective skill level from onboarding or ELO
    if skill_level is None:
        if elo_rating >= 1400:
            skill_level = "advanced"
        elif elo_rating >= 1000:
            skill_level = "intermediate"
        else:
            skill_level = "beginner"

    # Skill-level-aware session durations
    session_durations = {
        "beginner":     {"lesson": 15, "puzzle": 10, "sparring": 15},
        "intermediate": {"lesson": 20, "puzzle": 15, "sparring": 25},
        "advanced":     {"lesson": 25, "puzzle": 20, "sparring": 30},
    }
    durations = session_durations.get(skill_level, session_durations["intermediate"])

    # Generate primary directive based on skill level
    weakest_skill = format_skill(weakest[0][0])
    weakest_pct = round(weakest[0][1] * 100)

    directives = {
        "beginner": (
            f"Welcome to your chess journey! Your training starts with building "
            f"strong fundamentals. We'll focus on {weakest_skill} first "
            f"(currently at {weakest_pct}% mastery) with beginner-friendly "
            f"lessons and simple puzzles. Take your time — consistency beats speed!"
        ),
        "intermediate": (
            f"Your {weakest_skill} is at {weakest_pct}% mastery — this is your "
            f"primary area for improvement. We'll combine targeted drills with "
            f"pattern recognition exercises. Focus areas: {', '.join(weekly_focus)}."
        ),
        "advanced": (
            f"At your level, precision matters. Your {weakest_skill} "
            f"({weakest_pct}% mastery) needs refinement. We'll use advanced tactical "
            f"puzzles, deep positional analysis, and competitive sparring to push "
            f"your skills further. Weak spots: {', '.join(weekly_focus)}."
        ),
    }
    primary_directive = directives.get(skill_level, directives["intermediate"])

    # Map skills to activity types — adjusted by skill level
    skill_activities_by_level = {
        "beginner": {
            "tactical_oversight":   ("Simple Capture Puzzles", "puzzle"),
            "positional_error":     ("Basic Piece Placement Lesson", "lesson"),
            "endgame_fundamentals": ("Checkmate Patterns Lesson", "lesson"),
            "opening_theory":       ("Opening Principles (Control the Center)", "lesson"),
            "king_safety":          ("King Safety Basics", "lesson"),
            "pawn_structure":       ("Introduction to Pawns", "lesson"),
            "piece_coordination":   ("Piece Development Exercise", "puzzle"),
            "time_management":      ("Untimed Practice Games", "sparring"),
        },
        "intermediate": {
            "tactical_oversight":   ("Tactical Pattern Drill (Pins & Forks)", "puzzle"),
            "positional_error":     ("Positional Strategy Lesson", "lesson"),
            "endgame_fundamentals": ("Endgame Technique Drill", "lesson"),
            "opening_theory":       ("Opening Repertoire Review", "lesson"),
            "king_safety":          ("King Safety Exercises", "puzzle"),
            "pawn_structure":       ("Pawn Structure Analysis", "lesson"),
            "piece_coordination":   ("Piece Coordination Puzzles", "puzzle"),
            "time_management":      ("Speed Puzzle Challenge", "puzzle"),
        },
        "advanced": {
            "tactical_oversight":   ("Advanced Tactical Combinations", "puzzle"),
            "positional_error":     ("Deep Positional Analysis", "lesson"),
            "endgame_fundamentals": ("Complex Endgame Study", "lesson"),
            "opening_theory":       ("Opening Preparation (Specific Lines)", "lesson"),
            "king_safety":          ("King Attack & Defense Patterns", "puzzle"),
            "pawn_structure":       ("Advanced Pawn Structures (IQP, Carlsbad)", "lesson"),
            "piece_coordination":   ("Piece Harmony & Prophylaxis", "puzzle"),
            "time_management":      ("Blitz Puzzle Rush (Timed)", "puzzle"),
        },
    }
    skill_activities = skill_activities_by_level.get(
        skill_level, skill_activities_by_level["intermediate"]
    )

    # Build weekly plan
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    plan_items = []

    for i, day in enumerate(days):
        if i < len(weakest):
            skill_key = weakest[i][0]
            activity, act_type = skill_activities.get(skill_key, ("General Practice", "lesson"))
        elif i == 5:
            # Saturday: sparring session
            if skill_level == "beginner":
                activity = "Practice Match vs Easy AI"
                act_type = "sparring"
            else:
                gm = "Petrosian" if weakest[0][0] in ["positional_error", "pawn_structure"] else "Tal"
                activity = f"Spar vs {gm}"
                act_type = "sparring"
        elif i == 6:
            # Sunday: review
            if skill_level == "beginner":
                activity = "Fun Review & Free Play"
            else:
                activity = "Weekly Game Review & Analysis"
            act_type = "lesson"
        else:
            # Cycle through weakest skills
            skill_key = weakest[i % len(weakest)][0]
            activity, act_type = skill_activities.get(skill_key, ("General Practice", "lesson"))

        plan_items.append({
            "day": day,
            "activity": activity,
            "duration_min": durations.get(act_type, 20),
            "type": act_type,
        })

    return {
        "primary_directive": primary_directive,
        "weekly_focus": weekly_focus,
        "plan_items": plan_items,
    }


# ── Coaching Insights Generator ──────────────────────────────────────────

# Templates for generating human-readable coaching indicators per category
INDICATOR_TEMPLATES: dict[str, list[str]] = {
    "tactical_oversight": [
        "Missed a {severity}-level tactical opportunity — a {tactic_type} was available.",
        "Overlooked a key capture that would have won material.",
        "A hanging piece went unnoticed, costing significant material.",
    ],
    "positional_error": [
        "A passive piece placement weakened your control of the center.",
        "Piece activity was low — your pieces lacked coordination and purpose.",
        "Positional imbalance grew gradually and became a long-term weakness.",
    ],
    "endgame_fundamentals": [
        "An isolated queen's pawn became a long-term weakness in the endgame.",
        "King activity in the endgame was insufficient — activate earlier.",
        "A theoretical endgame position was misplayed — review basic techniques.",
    ],
    "opening_theory": [
        "Early development was neglected — piece mobilization lagged behind.",
        "An opening inaccuracy allowed your opponent to seize the initiative.",
        "The chosen opening line led to a passive position by move 10.",
    ],
    "king_safety": [
        "King was left in the center too long, inviting tactical threats.",
        "Pawn shield was compromised, leaving the king exposed to attack.",
        "A premature pawn push around the king weakened its defensive cover.",
    ],
    "pawn_structure": [
        "Doubled pawns on the {file}-file restricted your bishop pair.",
        "An isolated pawn became a target and required constant defense.",
        "Pawn structure damage created permanent weaknesses that were exploited.",
    ],
    "piece_coordination": [
        "Pieces were poorly coordinated — they failed to support each other.",
        "A knight was stranded on the rim with no way back to active play.",
        "Rook connectivity was broken, reducing their combined power.",
    ],
    "time_management": [
        "Time pressure led to hasty decisions in a critical position.",
        "Too much time spent in the opening left insufficient time for the middlegame.",
        "Clock management was poor — several moves were made on increment only.",
    ],
}

POSITIVE_TEMPLATES: dict[str, list[str]] = {
    "tactical_oversight": [
        "Sharp tactical awareness — captured all available opportunities.",
        "Excellent calculation depth kept you ahead in complications.",
    ],
    "positional_error": [
        "Strong positional understanding maintained control throughout.",
        "Excellent piece placement created long-term strategic advantages.",
    ],
    "endgame_fundamentals": [
        "Clean endgame technique secured the point efficiently.",
        "Excellent central pawn chain maintained control. Replicate this.",
    ],
    "opening_theory": [
        "Solid opening preparation gave you a comfortable middlegame.",
        "Efficient development and early castling set a strong foundation.",
    ],
    "king_safety": [
        "King safety was well-maintained — pawn shield stayed intact.",
        "Timely castling and prophylactic moves kept the king secure.",
    ],
    "pawn_structure": [
        "Pawn structure remained healthy throughout the game.",
        "Excellent pawn play maintained structural integrity under pressure.",
    ],
    "piece_coordination": [
        "Excellent piece harmony — all pieces worked together effectively.",
        "Rooks were well-connected and controlled key open files.",
    ],
    "time_management": [
        "Excellent clock management — decisions were made with appropriate time.",
        "Good time allocation across all phases of the game.",
    ],
}

FILES = ["a", "b", "c", "d", "e", "f", "g", "h"]
TACTIC_TYPES = ["fork", "pin", "skewer", "discovered attack", "back-rank threat"]


def generate_coaching_insights(
    recent_matches: list[dict],
    bkt_matrix: dict[str, float],
) -> dict:
    """
    Generate coaching indicators from recent match blunders.

    Each match produces 1-2 indicators — either highlighting
    specific mistakes or praising clean play in a skill area.

    Args:
        recent_matches: List of dicts with 'match_id', 'opponent_name',
                       'result', and 'blunders' (list of classified blunders)
        bkt_matrix: Current BKT mastery probabilities per skill

    Returns:
        Dict with 'recent_indicators' and 'skill_trends'
    """
    import random

    indicators = []
    skill_blunder_counts: dict[str, int] = {k: 0 for k in SKILL_PARAMETERS}

    for match_data in recent_matches:
        opponent = match_data.get("opponent_name", "Opponent")
        match_id = match_data.get("match_id", 0)
        blunders = match_data.get("blunders", [])

        if not blunders:
            # No blunders in this game — generate a positive indicator
            # Find the skill with highest mastery for positive feedback
            if bkt_matrix:
                best_skill = max(bkt_matrix, key=bkt_matrix.get)
                templates = POSITIVE_TEMPLATES.get(best_skill, POSITIVE_TEMPLATES["positional_error"])
                text = random.choice(templates)
                indicators.append({
                    "icon_type": "positive",
                    "opponent": opponent,
                    "text": text,
                    "category": best_skill,
                    "match_id": match_id,
                })
            continue

        # Group blunders by category for this match
        category_counts: dict[str, int] = {}
        worst_severity = "inaccuracy"
        for b in blunders:
            cat = b.get("category", "tactical_oversight")
            category_counts[cat] = category_counts.get(cat, 0) + 1
            skill_blunder_counts[cat] = skill_blunder_counts.get(cat, 0) + 1

            sev = b.get("severity", "mistake")
            if sev == "blunder" or (sev == "mistake" and worst_severity != "blunder"):
                worst_severity = sev

        # Generate indicator for the most frequent blunder category
        top_category = max(category_counts, key=category_counts.get)
        templates = INDICATOR_TEMPLATES.get(top_category, INDICATOR_TEMPLATES["positional_error"])
        text_template = random.choice(templates)

        # Fill template placeholders
        text = text_template.format(
            severity=worst_severity,
            tactic_type=random.choice(TACTIC_TYPES),
            file=random.choice(FILES),
        )

        indicators.append({
            "icon_type": "negative",
            "opponent": opponent,
            "text": text,
            "category": top_category,
            "match_id": match_id,
        })

        # If there's a secondary category with 2+ blunders, add another indicator
        if len(category_counts) > 1:
            secondary_cats = sorted(
                [(k, v) for k, v in category_counts.items() if k != top_category],
                key=lambda x: x[1],
                reverse=True,
            )
            if secondary_cats and secondary_cats[0][1] >= 2:
                sec_cat = secondary_cats[0][0]
                sec_templates = INDICATOR_TEMPLATES.get(sec_cat, INDICATOR_TEMPLATES["positional_error"])
                sec_text = random.choice(sec_templates).format(
                    severity=worst_severity,
                    tactic_type=random.choice(TACTIC_TYPES),
                    file=random.choice(FILES),
                )
                indicators.append({
                    "icon_type": "negative",
                    "opponent": opponent,
                    "text": sec_text,
                    "category": sec_cat,
                    "match_id": match_id,
                })

    # Limit to most recent 6 indicators
    indicators = indicators[:6]

    # Generate skill trends based on BKT matrix thresholds
    skill_trends = {}
    for skill, mastery in bkt_matrix.items():
        blunder_count = skill_blunder_counts.get(skill, 0)
        if blunder_count == 0 and mastery >= 0.6:
            skill_trends[skill] = "improving"
        elif blunder_count >= 3 or mastery < 0.3:
            skill_trends[skill] = "declining"
        else:
            skill_trends[skill] = "stable"

    return {
        "recent_indicators": indicators,
        "skill_trends": skill_trends,
    }


