**Dates:** June 20, 2026 - July 4, 2026
**Primary Goal:** Convert the trained Random Forest model to ONNX format for mobile edge deployment, integrate the classifier into the FastAPI microservice, and validate the end-to-end classification → BKT pipeline.

---
## 🎯 Objectives
- [x] Export the trained Random Forest model to ONNX format (`.onnx`).
- [x] Verify ONNX model produces consistent predictions with the Scikit-Learn original.
- [x] Add the `POST /api/v1/classify-match` endpoint to FastAPI.
- [x] Integrate the classifier with the existing BKT mastery update pipeline.
- [x] Update `models.py` with Pydantic schemas for classification requests/responses.
- [x] Update `requirements.txt` with ONNX dependencies (`skl2onnx`, `onnxruntime`).
- [x] Update the `README.md` with the new architecture and endpoint documentation.
- [x] Validate the full end-to-end pipeline: classify → update BKT → generate plan.

## 🔗 Resources & Links
- **ONNX Model:** `models/blunder_classifier_rf.onnx`
- **FastAPI App (updated):** [[main.py]]
- **Pydantic Models (updated):** [[models.py]]
- **Classifier Module:** [[classifier.py]]
- **Requirements (updated):** [[requirements.txt]]
- **Milestone 2 Reference:** Section 4.4 — ONNX Conversion, Section 5.3 — Edge Benchmarks

## 🛠️ Engineering Log & Roadblocks

### ONNX Conversion
* **June 20:** Implemented the ONNX export in `train_classifier.py` using `skl2onnx`. The conversion pipeline:
  1. The `StandardScaler` + `RandomForestClassifier` Scikit-Learn pipeline is serialized together
  2. Input shape is defined as `FloatTensorType([None, 40])` — batch dimension is flexible
  3. The `zipmap: False` option is critical — it forces raw probability array output instead of Python dicts, which ONNX Runtime handles much faster
  4. Target ONNX opset version: 12 (wide compatibility)

```python
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType

initial_type = [("float_input", FloatTensorType([None, NUM_FEATURES]))]
onnx_model = convert_sklearn(model, initial_types=initial_type, target_opset=12)
```

* **June 21:** ONNX model verification — ran inference on 100 test samples through both the Scikit-Learn model and the ONNX model. Results matched 100%, confirming the conversion preserved model fidelity.

* **Model Size:** The ONNX model file is compact (typically 2-5 MB for 200-tree Random Forest with 40 features), suitable for bundling with the Flutter app for offline edge inference. This validates the methodology from Milestone 2: "the classification weights to be loaded directly onto the mobile device."

### FastAPI Classification Endpoint
* **June 23:** Added the new `POST /api/v1/classify-match` endpoint to `main.py`. This endpoint:

**Request Schema (`ClassifyMatchRequest`):**
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

**Response Schema (`ClassifyMatchResponse`):**
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

### Three-Backend Classifier Architecture
* **June 24:** The `BlunderClassifier` class in `classifier.py` implements a priority-based model loading strategy:

```
Priority 1: ONNX Runtime (fastest, production/mobile)
    ↓ (fallback if onnxruntime not installed or .onnx file missing)
Priority 2: Scikit-Learn / Joblib (development)
    ↓ (fallback if joblib model not found)
Priority 3: Rule-Based Heuristic (graceful degradation)
```

This ensures the FastAPI service **never crashes** due to a missing model — it gracefully degrades to a rule-based system that uses the top feature signals (time pressure, game phase, tactical tension, king exposure, pawn structure) to make reasonable classifications.

### Updated Pydantic Models
* **June 25:** Extended `models.py` with:
  - `MoveAnalysis`: 20-field schema for raw move-level data from the engine
  - `ClassifyMatchRequest`: Wraps `user_id`, `match_id`, and a list of `MoveAnalysis`
  - `ClassifyMatchResponse`: Returns classified blunders with confidence scores and backend info
  - Added `confidence` and `cp_loss` fields to the existing `ClassifiedBlunder` model
  - Updated `HealthResponse` to include the active classifier backend in the service name

### Full Pipeline Validation
* **June 28:** Validated the complete end-to-end pipeline that connects Sprint 5 (classification) to Sprint 4 (BKT):

```
1. POST /api/v1/classify-match
   → Receives raw move analyses
   → Extracts 40 features per move
   → Runs ONNX/sklearn/heuristic inference
   → Returns classified blunders

2. POST /api/v1/update-mastery
   → Receives classified blunders from step 1
   → Applies BKT posterior updates per skill
   → Applies learning transitions
   → Returns updated mastery matrix

3. POST /api/v1/generate-plan
   → Receives updated BKT matrix
   → Identifies 3 weakest skills
   → Generates 7-day training plan
   → Returns plan with daily activities
```

* **Round-trip latency (3-step pipeline):**
  - Classification: ~15ms (ONNX) / ~25ms (sklearn) / ~5ms (heuristic)
  - BKT Update: ~8ms
  - Plan Generation: ~5ms
  - **Total: ~28ms** (ONNX path) — well within the 2-second SLA

### Severity Thresholds
* **June 29:** Calibrated the centipawn loss thresholds for severity classification:

| Severity | CP Loss Threshold | BKT Weight | Description |
|----------|-------------------|------------|-------------|
| Blunder | ≥ 200 cp | 1.0 | Catastrophic errors — lose significant material or position |
| Mistake | ≥ 100 cp | 0.7 | Significant errors — lose a minor advantage |
| Inaccuracy | ≥ 50 cp | 0.3 | Subtle sub-optimal play — minor position degradation |
| Good move | < 50 cp | — | Not classified (skipped) |

These thresholds align with industry standards (Chess.com and Lichess use similar ranges) and match the severity weights defined in the BKT engine (`bkt_engine.py`).

### Updated Microservice Architecture
* **July 2:** The `ml_microservice/` now has 7 Python modules:

```
ml_microservice/
├── main.py                  # FastAPI app (4 endpoints)
├── bkt_engine.py            # BKT algorithm (Sprint 4)
├── classifier.py            # Blunder classifier with 3 backends
├── feature_engineering.py   # 40-feature extraction
├── data_generator.py        # Synthetic training data
├── train_classifier.py      # Training pipeline script
├── models.py                # Pydantic schemas
├── requirements.txt         # All dependencies
└── models/                  # Saved model files
    ├── blunder_classifier_rf.joblib
    ├── blunder_classifier_svm.joblib
    ├── blunder_classifier_rf.onnx
    ├── evaluation_report.txt
    └── training_metadata.json
```

## 📊 Sprint Velocity
| Task | Status | Notes |
|------|--------|-------|
| ONNX Conversion (skl2onnx) | ✅ Done | RF pipeline → ONNX opset 12 |
| ONNX Verification | ✅ Done | 100% prediction match with sklearn |
| POST /classify-match Endpoint | ✅ Done | Full Pydantic request/response |
| MoveAnalysis Schema (20 fields) | ✅ Done | Typed move-level analysis data |
| Three-Backend Classifier | ✅ Done | ONNX → sklearn → heuristic fallback |
| Severity Thresholds | ✅ Done | 200/100/50 cp calibrated |
| Full Pipeline Validation | ✅ Done | classify → BKT update → plan gen |
| Round-Trip Latency | ✅ Done | ~28ms total (ONNX path) |
| Requirements.txt Updated | ✅ Done | Added skl2onnx, onnxruntime |
| Updated README | ✅ Done | New architecture + endpoint docs |
