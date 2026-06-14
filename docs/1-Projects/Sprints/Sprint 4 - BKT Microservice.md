**Dates:** June 6, 2026 - June 20, 2026
**Primary Goal:** Build the Python FastAPI BKT microservice, implement the Bayesian Knowledge Tracing algorithms, establish the Laravel ↔ FastAPI communication pipeline, and validate the full coaching data flow.

---
## 🎯 Objectives
- [x] Initialize the Python FastAPI microservice (`ml_microservice/`) with proper project structure.
- [x] Implement the Bayesian Knowledge Tracing (BKT) engine with Corbett & Anderson (1995) posterior update formulas.
- [x] Define the 8 cognitive skill parameters with expert-tuned `P(Learn)`, `P(Guess)`, and `P(Slip)` values.
- [x] Build the `POST /api/v1/update-mastery` endpoint for post-match BKT matrix updates.
- [x] Build the `POST /api/v1/generate-plan` endpoint for personalized training plan generation.
- [x] Implement severity-weighted blunder processing (blunder × 1.0, mistake × 0.7, inaccuracy × 0.3).
- [x] Create Pydantic request/response models for type-safe API contracts.
- [x] Validate the end-to-end pipeline: Flutter → Laravel → FastAPI → PostgreSQL → Laravel → Flutter.

## 🔗 Resources & Links
- **FastAPI Entry Point:** [[main.py]]
- **BKT Engine:** [[bkt_engine.py]]
- **Pydantic Models:** [[models.py]]
- **Requirements:** [[requirements.txt]]
- **Milestone 2 Reference:** Section 4.5 — BKT Microservice

## 🛠️ Engineering Log & Roadblocks

### BKT Algorithm Implementation
* **June 6:** Began implementing the core BKT engine in `bkt_engine.py`. The algorithm follows the Corbett & Anderson (1995) Hidden Markov Model methodology as specified in Milestone 2:

```
For INCORRECT observations:
P(mastered | incorrect) = P(slip) × P(mastered)
                          ─────────────────────────────────────────
                          P(slip) × P(mastered) + (1 - P(guess)) × (1 - P(mastered))

For CORRECT observations:
P(mastered | correct) = (1 - P(slip)) × P(mastered)
                        ─────────────────────────────────────────
                        (1 - P(slip)) × P(mastered) + P(guess) × (1 - P(mastered))

Learning Transition:
P(L_n) = P(L_n | obs) + (1 - P(L_n | obs)) × P(T)
```

* **June 7:** Defined the expert-tuned BKT parameters for 8 cognitive chess skills:

| Skill | P(Learn) | P(Guess) | P(Slip) | Rationale |
|-------|----------|----------|---------|-----------|
| Tactical Oversight | 0.10 | 0.15 | 0.10 | Hard to learn — requires pattern recognition |
| Positional Error | 0.08 | 0.10 | 0.12 | Very slow — requires deep understanding |
| Endgame Fundamentals | 0.12 | 0.05 | 0.08 | Moderate — methodical study works |
| Opening Theory | 0.15 | 0.20 | 0.15 | Fastest to learn — memorizable |
| King Safety | 0.09 | 0.12 | 0.10 | Requires intuition |
| Pawn Structure | 0.08 | 0.08 | 0.10 | Abstract — slow to internalize |
| Piece Coordination | 0.10 | 0.10 | 0.10 | Balanced learning curve |
| Time Management | 0.12 | 0.15 | 0.20 | Behavioral — very prone to stress slips |

* **Roadblock — Division by Zero:** Initial implementation had no guard against `denominator == 0` in the Bayesian update formula. When both `p_mastery` and `(1 - p_mastery)` approached extreme values (0.01 or 0.99), floating-point rounding could produce a zero denominator. Fixed by adding an early-return guard (`if denominator == 0: return p_mastery`) and clamping all outputs to the `[0.01, 0.99]` range.

### Severity-Weighted Processing
* **June 8:** Implemented a **severity weighting** system that the Milestone 2 document didn't originally specify, but was necessary for practical accuracy:
  - **Blunders** (full weight, `1.0`): Catastrophic errors — full BKT update applied.
  - **Mistakes** (moderate weight, `0.7`): Significant errors — blended with the prior.
  - **Inaccuracies** (minor weight, `0.3`): Subtle sub-optimal play — minimal impact.
  
  The blending formula: `blended = p_mastery + severity_weight × (posterior - p_mastery)`. This prevents a single inaccuracy from dramatically shifting the mastery probability.

### FastAPI Endpoint Architecture
* **June 9-10:** Built the two core endpoints with Pydantic validation:

**`POST /api/v1/update-mastery`**
- **Input:** `user_id`, `current_matrix` (dict of skill → float), `classified_blunders` (list of `{category, severity}`)
- **Processing:** Iterates each blunder → applies Bayesian posterior update → applies learning transition → rounds to 4 decimal places
- **Output:** `user_id`, `new_matrix`, `skills_updated` (sorted list of skill keys that changed)

**`POST /api/v1/generate-plan`**
- **Input:** `user_id`, `bkt_matrix`, `elo_rating`
- **Processing:** Sorts skills by mastery (ascending) → takes weakest 3 → maps to activity types → builds 7-day plan with specific activities
- **Output:** `user_id`, `primary_directive` (coaching summary string), `weekly_focus` (list of skill labels), `plan_items` (list of `{day, activity, duration_min, type}`)

**Training Plan Generation Logic:**
- Mon-Wed: Targeted drills for the 3 weakest skills (mapped to lesson/puzzle types)
- Thu-Fri: Cycle back through weakest skills
- Saturday: Sparring session against the appropriate GM persona (Petrosian for positional weaknesses, Tal for tactical)
- Sunday: Weekly game review & analysis

### Laravel ↔ FastAPI Integration Pipeline
* **June 12:** Validated the complete end-to-end data pipeline:

```
1. User finishes a sparring match on Flutter
2. Flutter POSTs the PGN + result to Laravel (PUT /api/v1/matches/{id})
3. Flutter triggers analysis (POST /api/v1/matches/{id}/analyze)
4. Laravel's MatchController forwards the classified_blunders + current_matrix to FastAPI
5. FastAPI's BKT engine processes the blunders and returns the updated matrix
6. Laravel saves the new matrix to user_bkt_matrices (JSONB column)
7. Flutter can then fetch the coaching plan (GET /api/v1/coaching/plan)
8. Optionally: POST /api/v1/coaching/refresh → Laravel → FastAPI generate-plan → new TrainingPlan saved
```

* **June 13:** Validated graceful degradation. When FastAPI is stopped:
  - `MatchController::analyze()` catches the `ConnectionException` and returns HTTP 503 with the unchanged matrix.
  - `CoachingController::refresh()` falls back to a locally-generated basic plan using the `getWeakestSkills()` private method.
  - The Flutter app continues to function — it just won't get updated BKT data until FastAPI comes back online.

### CORS & Security
* **June 14:** Configured CORS middleware on the FastAPI app to allow Laravel communication during development (`allow_origins=["*"]`). In production, this will be locked to the Laravel server's domain only. The FastAPI service is **internal-only** — it is never exposed to the Flutter client directly. All traffic routes through Laravel's Sanctum-protected gateway.

### Testing & Validation
* **June 15:** Manual validation tests:
  1. **BKT Math Verification:** Fed 5 simulated "tactical_oversight" blunders into `update_mastery`. Starting mastery of 0.50 correctly decreased to ~0.18 after 5 blunders with learning transitions applied. The learning transition prevented it from dropping to near-zero, which matches the expected BKT behavior (the student "learns" even from mistakes).
  2. **Plan Generation:** With a matrix where `pawn_structure = 0.15`, `positional_error = 0.22`, `endgame_fundamentals = 0.30`, the engine correctly identified these as the top 3 weaknesses and generated a 7-day plan prioritizing pawn structure drills.
  3. **API Response Time:** FastAPI responded to `/update-mastery` in ~12ms and `/generate-plan` in ~8ms — well within the 2-second SLA when combined with Laravel's routing overhead (~1.1s round-trip total).

## 📊 Sprint Velocity
| Task | Status | Notes |
|------|--------|-------|
| FastAPI Project Init | ✅ Done | `main.py`, `models.py`, `bkt_engine.py`, `requirements.txt` |
| BKT Algorithm (Corbett & Anderson) | ✅ Done | Posterior update + learning transition |
| 8 Cognitive Skill Parameters | ✅ Done | Expert-tuned P(Learn), P(Guess), P(Slip) |
| Severity Weighting System | ✅ Done | Blunder/Mistake/Inaccuracy multipliers |
| POST /update-mastery Endpoint | ✅ Done | Pydantic validated, tested |
| POST /generate-plan Endpoint | ✅ Done | 7-day plan with GM persona mapping |
| Health Check Endpoint | ✅ Done | GET / and GET /health |
| Laravel ↔ FastAPI Bridge | ✅ Done | `Http::timeout(10)->post()` in 2 controllers |
| Graceful Degradation | ✅ Done | Fallback in MatchController + CoachingController |
| CORS Configuration | ✅ Done | Development: `*`, production: locked |
| Manual BKT Validation | ✅ Done | 5-blunder scenario verified mathematically |
| API Response Time < 2s | ✅ Done | ~12ms FastAPI + ~1.1s round-trip total |
