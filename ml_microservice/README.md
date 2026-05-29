# SparMate BKT Microservice

**Bayesian Knowledge Tracing** engine for adaptive chess coaching, built with **FastAPI** (Python 3.11+).

This microservice handles the computationally heavy mastery-tracking logic described in Milestone 2 (Section 4.5), keeping the Laravel API gateway lightweight.

## Architecture

```
Laravel Gateway ──POST──► FastAPI BKT Microservice
                            │
                            ├── /api/v1/update-mastery
                            │     Receives classified blunders
                            │     Applies Bayesian posterior updates
                            │     Returns updated mastery matrix
                            │
                            └── /api/v1/generate-plan
                                  Receives BKT matrix + ELO
                                  Identifies weakest skills
                                  Generates weekly training plan
```

## Quick Start

```bash
cd ml_microservice
pip install -r requirements.txt
uvicorn main:app --reload --port=8000
```

Health check: [http://localhost:8000/health](http://localhost:8000/health)

API docs: [http://localhost:8000/docs](http://localhost:8000/docs) (auto-generated Swagger UI)

---

## Endpoints

### `GET /health`

Returns service status.

```json
{
  "status": "online",
  "service": "SparMate BKT Microservice",
  "version": "1.0.0"
}
```

### `POST /api/v1/update-mastery`

Update a user's BKT matrix after a match.

**Request:**

```json
{
  "user_id": 1,
  "current_matrix": {
    "tactical_oversight": 0.45,
    "positional_error": 0.62,
    "endgame_fundamentals": 0.78,
    "opening_theory": 0.55,
    "king_safety": 0.40,
    "pawn_structure": 0.58,
    "piece_coordination": 0.50,
    "time_management": 0.35
  },
  "classified_blunders": [
    {"category": "tactical_oversight", "move": 23, "severity": "blunder"},
    {"category": "king_safety", "move": 31, "severity": "mistake"}
  ]
}
```

**Response:**

```json
{
  "status": "success",
  "user_id": 1,
  "new_matrix": {
    "tactical_oversight": 0.4012,
    "positional_error": 0.62,
    "endgame_fundamentals": 0.78,
    "opening_theory": 0.55,
    "king_safety": 0.3784,
    "pawn_structure": 0.58,
    "piece_coordination": 0.50,
    "time_management": 0.35
  },
  "skills_updated": ["king_safety", "tactical_oversight"]
}
```

### `POST /api/v1/generate-plan`

Generate a personalized training plan from a BKT matrix.

**Request:**

```json
{
  "user_id": 1,
  "bkt_matrix": {
    "tactical_oversight": 0.40,
    "positional_error": 0.62,
    "endgame_fundamentals": 0.78,
    "opening_theory": 0.55,
    "king_safety": 0.38,
    "pawn_structure": 0.58,
    "piece_coordination": 0.50,
    "time_management": 0.35
  },
  "elo_rating": 1420
}
```

**Response:**

```json
{
  "status": "success",
  "user_id": 1,
  "primary_directive": "Your Time Management is at 35% mastery — this is your primary area for improvement...",
  "weekly_focus": ["Time Management", "King Safety", "Tactical Oversight"],
  "plan_items": [
    {"day": "Monday", "activity": "Speed Puzzle Challenge", "duration_min": 20, "type": "puzzle"},
    {"day": "Tuesday", "activity": "King Safety Exercises", "duration_min": 20, "type": "puzzle"},
    {"day": "Wednesday", "activity": "Tactical Pattern Drill", "duration_min": 20, "type": "puzzle"},
    {"day": "Thursday", "activity": "Speed Puzzle Challenge", "duration_min": 20, "type": "puzzle"},
    {"day": "Friday", "activity": "King Safety Exercises", "duration_min": 20, "type": "puzzle"},
    {"day": "Saturday", "activity": "Spar vs Tal", "duration_min": 30, "type": "sparring"},
    {"day": "Sunday", "activity": "Weekly Game Review & Analysis", "duration_min": 20, "type": "lesson"}
  ]
}
```

---

## BKT Algorithm

Implements the **Corbett & Anderson (1995)** Bayesian Knowledge Tracing methodology.

### Model Parameters (per skill)

| Parameter | Symbol | Description |
|-----------|--------|-------------|
| Prior mastery | P(L₀) | Initial probability of knowing the skill |
| Learn rate | P(T) | Probability of learning after any observation |
| Guess rate | P(G) | Probability of correct answer despite not knowing |
| Slip rate | P(S) | Probability of incorrect answer despite knowing |

### Update Formula

After an **incorrect** observation (blunder/mistake):

```
P(mastered | incorrect) = P(slip) × P(mastered) / [P(slip) × P(mastered) + (1 - P(guess)) × (1 - P(mastered))]
```

After the posterior update, a **learning transition** is applied:

```
P(Lₙ) = P(Lₙ | obs) + (1 - P(Lₙ | obs)) × P(T)
```

### Severity Weighting

| Severity | Weight | Impact |
|----------|--------|--------|
| Blunder | 1.0 | Full Bayesian update |
| Mistake | 0.7 | Moderate update |
| Inaccuracy | 0.3 | Minor update |

---

## Project Structure

```
ml_microservice/
├── main.py            # FastAPI application with endpoints
├── bkt_engine.py      # Core BKT algorithm + plan generation
├── models.py          # Pydantic request/response schemas
└── requirements.txt   # Python dependencies
```

---

## License

Part of the SparMate academic capstone project.
