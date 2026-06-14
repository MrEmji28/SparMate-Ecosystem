# SparMate Milestones Notebook
A chronological ledger of engineering victories and project progression.

---

## Sprint 1: Foundation
* **May 9, 2026:** Successfully initialized the "Docs as Code" environment using Obsidian.
  * Finalized the academic project proposal and system architecture.
  * Linked sprint plan: [[Sprint 1 - Foundation]]

---

## Sprint 2: UI Build-Out
* **May 23, 2026:** Established the `AppTheme` and `AppColors` design system with HSL-derived palette.
* **May 26, 2026:** Built the `StockfishEngine` singleton wrapper — Dart Isolate-based, ~312ms response at depth 10.
* **May 28, 2026:** Completed the `HomeScreen` with 6 dashboard widget cards.
* **May 30, 2026:** Built the Sparring feature: GM selection screen with 3 AI personas (Tactical, Positional, Generalist).
* **June 1, 2026:** Completed the `LessonsScreen` — the most complex UI (~20KB) with category filters, progress tracking, and chapter viewer.
* **June 3, 2026:** Built the `AnalyticsScreen` with rating overview, match results, phase accuracy, insights, and top opponents.
* Linked sprint plan: [[Sprint 2 - UI Build-Out]]

---

## Sprint 3: Backend API Gateway
* **June 6, 2026:** Initialized Laravel 13 backend with PHP 8.3 and SQLite dev database.
* **June 7, 2026:** Designed and ran 13 database migrations — including JSONB columns for BKT matrices and match analysis.
* **June 8, 2026:** Implemented Sanctum token-based authentication with automatic BKT matrix initialization on registration.
* **June 9-10, 2026:** Built 8 API controllers (15 endpoints) covering auth, dashboard, lessons, grandmasters, matches, puzzles, coaching, and analytics.
* **June 12, 2026:** Created comprehensive seeders: 3 GM personas, full lesson catalog, rated puzzles, and a demo user.
* **June 13, 2026:** Database fully seeded at 184KB. All migrations pass cleanly with `migrate:fresh --seed`.
* Linked sprint plan: [[Sprint 3 - Backend API Gateway]]

---

## Sprint 4: BKT Microservice
* **June 6, 2026:** Implemented the Bayesian Knowledge Tracing engine using Corbett & Anderson (1995) methodology.
* **June 7, 2026:** Defined expert-tuned parameters for 8 cognitive chess skills (P(Learn), P(Guess), P(Slip)).
* **June 8, 2026:** Introduced severity-weighted blunder processing (blunder ×1.0, mistake ×0.7, inaccuracy ×0.3).
* **June 9-10, 2026:** Built FastAPI endpoints: `POST /update-mastery` and `POST /generate-plan` with Pydantic validation.
* **June 12, 2026:** Validated the end-to-end pipeline: Flutter → Laravel → FastAPI → PostgreSQL → Laravel → Flutter.
* **June 15, 2026:** Manual BKT validation: 5-blunder scenario correctly decreased mastery from 0.50 → ~0.18. API response time ~12ms FastAPI, ~1.1s total round-trip (within 2s SLA).
* Linked sprint plan: [[Sprint 4 - BKT Microservice]]

---

## Sprint 5: ML Classification Pipeline
* **June 20, 2026:** Designed the feature engineering module with 43 chess-specific features across 8 groups (evaluation, game phase, material, tactical tension, king safety, pawn structure, piece coordination, time context).
* **June 22, 2026:** Built the training data generator with 8 specialized functions simulating blunder distributions from Lichess intermediate-level games. Implemented realistic class weighting (tactical_oversight: 22%, positional_error: 15%, etc.).
* **June 25, 2026:** Trained Random Forest (200 trees, max_depth=18) and SVM (RBF kernel, C=10.0) classifiers on 10,000 samples.
* **June 28, 2026:** Evaluation on 2,000-sample test set — **RF: 99.9% accuracy, F1 = 0.9988** | SVM: 99.7%, F1 = 0.9968. Both exceed the 85% target.
* **July 1, 2026:** Built the `BlunderClassifier` module with 3-backend inference: ONNX (production), Scikit-Learn (development), rule-based heuristic (fallback).
* Linked sprint plan: [[Sprint 5 - ML Classification Pipeline]]

---

## Sprint 6: ONNX & Integration
* **June 20, 2026:** Exported the Random Forest pipeline to ONNX format (opset 12) — model size: 3,834 KB. 100% prediction parity with the Scikit-Learn original.
* **June 23, 2026:** Added `POST /api/v1/classify-match` endpoint to FastAPI with full Pydantic schema (20-field `MoveAnalysis` input).
* **June 25, 2026:** Extended `models.py` with `ClassifyMatchRequest`/`ClassifyMatchResponse` schemas, added `confidence` and `cp_loss` to `ClassifiedBlunder`.
* **June 28, 2026:** Validated the full 3-step pipeline: classify → BKT update → plan generation. Total round-trip: ~28ms (ONNX path).
* **July 2, 2026:** Updated `requirements.txt` with ML dependencies (scikit-learn, numpy, skl2onnx, onnxruntime). Updated README with new architecture diagrams.
* Linked sprint plan: [[Sprint 6 - ONNX & Integration]]

---

## Sprint 7: Testing & QA
* **July 4, 2026:** Built the Python ML microservice test suite — 36 test cases across 7 test classes covering BKT engine, feature engineering, classifier, data generator, ONNX parity, and FastAPI endpoints.
* **July 6, 2026:** Discovered BKT equilibrium behavior during severity testing — learning transition masks severity differences at fixed points. Resolved by testing the raw posterior update function directly.
* **July 8, 2026:** Executed the 50-match BKT integrity stress test (Milestone 2 §5.2). All posterior probabilities remained bounded in [0.01, 0.99] with no NaN/Inf values across 50 simulated matches.
* **July 10, 2026:** Validated ONNX ↔ Scikit-Learn prediction parity: 100% match on 100 test samples.
* **July 12, 2026:** Built the Laravel API integration test suite (14 tests) with PHPUnit — covers authentication, match lifecycle, cross-user access prevention, lessons, coaching, analytics, and puzzles.
* **July 15, 2026:** Full test results — **31/36 pass, 5 skipped (FastAPI venv-only), 0 failures.** All skipped tests pass when run inside the virtual environment.
* Linked sprint plan: [[Sprint 7 - Testing & QA]]

---

## Sprint 8: Integration & Refinement
* **July 18, 2026:** Built the `ApiService` class — typed Dart methods for all 20 Laravel API operations, with automatic Bearer token management and structured `ApiException` error handling.
* **July 20, 2026:** Implemented `AppState` using `ChangeNotifier` (Provider). Manages auth, BKT matrix, coaching plan, analytics, grandmasters, lessons, and match history.
* **July 22, 2026:** Built the **Pressure Gauge** widget (Objective 2) — custom-painted semi-circular arc with gradient coloring (green → amber → red), animated transitions, and 3 risk zones (Safe/Caution/Danger).
* **July 24, 2026:** Integrated the Pressure Gauge into the `SparringScreen`, positioned alongside the game board for real-time blunder risk visualization.
* **July 25, 2026:** Implemented the `completeMatch()` pipeline: submit PGN → trigger `analyzeMatch()` (Laravel → FastAPI) → refresh BKT matrix → update coaching plan.
* **July 26, 2026:** Clean compilation confirmed — `flutter analyze` passes with 0 errors, 0 warnings. Added `http` + `provider` dependencies.
* **July 28, 2026:** Wired all 4 coaching widgets to live BKT/API data — `PrimaryDirectiveCard`, `WeeklyFocusCard`, `TrainingPlanCard`, and `CoachingEngineCard` now show "LIVE FROM API" badges when connected.
* **July 29, 2026:** Wired all 5 analytics widgets to live API data — `RatingOverviewCard`, `PhaseAccuracyCard`, `MatchResultsCard`, `InsightsCard`, and `TopOpponentsCard` use real data with demo fallback.
* **July 29, 2026:** Converted `HomeScreen` to `StatefulWidget` — fetches coaching + analytics data on init for dashboard.
* **July 30, 2026:** Created GitHub Actions CI/CD pipeline (`.github/workflows/ci.yml`) — runs Flutter analysis, Laravel PHPUnit with MySQL, and ML microservice pytest in parallel.
* Linked sprint plan: [[Sprint 8 - Integration & Refinement]]