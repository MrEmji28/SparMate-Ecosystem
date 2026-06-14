# SparMate ML Microservice

**Blunder Classification + Bayesian Knowledge Tracing** engine for adaptive chess coaching, built with **FastAPI** (Python 3.11+).

This microservice handles the computationally heavy ML and mastery-tracking logic described in Milestone 2 (Sections 4.4 and 4.5), keeping the Laravel API gateway lightweight.

## Architecture

```
Laravel Gateway ──POST──► FastAPI ML Microservice
                            │
                            ├── /api/v1/classify-match   (Sprint 5-6)
                            │     Receives move-level analysis data
                            │     Extracts 40 chess-specific features
                            │     Classifies via RF/ONNX/heuristic
                            │     Returns categorized blunders
                            │
                            ├── /api/v1/update-mastery   (Sprint 4)
                            │     Receives classified blunders
                            │     Applies Bayesian posterior updates
                            │     Returns updated mastery matrix
                            │
                            └── /api/v1/generate-plan    (Sprint 4)
                                  Receives BKT matrix + ELO
                                  Identifies weakest skills
                                  Generates weekly training plan
```

## Quick Start

```bash
cd ml_microservice

# Install dependencies
pip install -r requirements.txt

# Train the classifier (first time only)
python train_classifier.py

# Start the server
uvicorn main:app --reload --port=8000
```

Health check: [http://localhost:8000/health](http://localhost:8000/health)

API docs: [http://localhost:8000/docs](http://localhost:8000/docs) (auto-generated Swagger UI)

---

## ML Pipeline

### Blunder Classification

The classifier categorizes chess mistakes into 8 cognitive skill categories:

| Category | Description | Key Features |
|----------|-------------|--------------|
| `tactical_oversight` | Missed forks, pins, skewers | High CP loss, pieces en prise |
| `positional_error` | Poor strategic decisions | Low mobility, quiet positions |
| `endgame_fundamentals` | Failed endgame technique | Low piece count, passed pawns |
| `opening_theory` | Development violations | Early moves, low development |
| `king_safety` | Exposed king or broken shelter | High king exposure, low pawn shield |
| `pawn_structure` | Created pawn weaknesses | Doubled/isolated pawns, pawn push |
| `piece_coordination` | Passive, uncoordinated pieces | Very low mobility, no bishop pair |
| `time_management` | Clock-pressure blunders | Low time remaining, high time delta |

### Three-Backend Inference

```
Priority 1: ONNX Runtime (fastest, production)
    ↓ fallback
Priority 2: Scikit-Learn / Joblib (development)
    ↓ fallback
Priority 3: Rule-Based Heuristic (graceful degradation)
```

### Training Pipeline

```bash
python train_classifier.py
```

Outputs to `models/`:
- `blunder_classifier_rf.joblib` — Trained Random Forest (200 trees)
- `blunder_classifier_svm.joblib` — Trained SVM (RBF kernel)
- `blunder_classifier_rf.onnx` — ONNX export for edge deployment
- `evaluation_report.txt` — Classification metrics
- `training_metadata.json` — Full training metadata

---

## Endpoints

### `GET /health`

Returns service status and active classifier backend.

```json
{
  "status": "online",
  "service": "SparMate ML Microservice (classifier: onnx)",
  "version": "2.0.0"
}
```

### `POST /api/v1/classify-match`

Classify all mistakes in a completed sparring match.

**Request:**

```json
{
  "user_id": 1,
  "match_id": 42,
  "move_analyses": [
    {
      "eval_before": 150.0,
      "eval_after": -200.0,
      "move_number": 23,
      "total_pieces": 22,
      "pieces_en_prise": 3,
      "hanging_value": 500,
      "capture_available": true,
      "own_king_exposure": 0.2,
      "time_remaining_pct": 0.45,
      "time_pressure": false
    }
  ]
}
```

**Response:**

```json
{
  "status": "success",
  "user_id": 1,
  "match_id": 42,
  "classified_blunders": [
    {
      "category": "tactical_oversight",
      "severity": "blunder",
      "move": 23,
      "confidence": 0.872,
      "cp_loss": 350.0
    }
  ],
  "total_moves_analyzed": 40,
  "blunders_found": 3,
  "classifier_backend": "onnx"
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
  "primary_directive": "Your Time Management is at 35% mastery...",
  "weekly_focus": ["Time Management", "King Safety", "Tactical Oversight"],
  "plan_items": [
    {"day": "Monday", "activity": "Speed Puzzle Challenge", "duration_min": 20, "type": "puzzle"},
    {"day": "Saturday", "activity": "Spar vs Tal", "duration_min": 30, "type": "sparring"},
    {"day": "Sunday", "activity": "Weekly Game Review & Analysis", "duration_min": 20, "type": "lesson"}
  ]
}
```

---

## BKT Algorithm

Implements the **Corbett & Anderson (1995)** Bayesian Knowledge Tracing methodology.

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

| Severity | Weight | CP Loss Threshold |
|----------|--------|-------------------|
| Blunder | 1.0 | ≥ 200 cp |
| Mistake | 0.7 | ≥ 100 cp |
| Inaccuracy | 0.3 | ≥ 50 cp |

---

## Project Structure

```
ml_microservice/
├── main.py                  # FastAPI application (4 endpoints)
├── bkt_engine.py            # Core BKT algorithm + plan generation
├── classifier.py            # Blunder classifier (3 backends)
├── feature_engineering.py   # 40-feature extraction module
├── data_generator.py        # Synthetic training data generator
├── train_classifier.py      # Training pipeline script
├── models.py                # Pydantic request/response schemas
├── requirements.txt         # Python dependencies
└── models/                  # Trained model files
    ├── blunder_classifier_rf.joblib
    ├── blunder_classifier_svm.joblib
    ├── blunder_classifier_rf.onnx
    ├── evaluation_report.txt
    └── training_metadata.json
```

---

## License

Part of the SparMate academic capstone project.
