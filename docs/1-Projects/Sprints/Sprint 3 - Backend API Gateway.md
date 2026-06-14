**Dates:** June 6, 2026 - June 20, 2026
**Primary Goal:** Deploy the PostgreSQL (SQLite dev) database schema, build the Laravel 13 RESTful API gateway with Sanctum authentication, and implement all model relationships.

---
## 🎯 Objectives
- [x] Initialize the Laravel 13 backend project (`sparmate_backend`) with PHP 8.3.
- [x] Configure SQLite as the development database (with PostgreSQL-ready JSONB patterns).
- [x] Design and run all database migrations (users, lessons, chapters, grandmasters, sparring_matches, puzzles, puzzle_attempts, user_bkt_matrices, training_plans, personal_access_tokens).
- [x] Implement Laravel Sanctum token-based authentication (register, login, logout, user profile).
- [x] Build all Eloquent models with relationships: `User`, `Lesson`, `Chapter`, `Grandmaster`, `SparringMatch`, `Puzzle`, `PuzzleAttempt`, `UserBktMatrix`, `TrainingPlan`, `UserLessonProgress`.
- [x] Create the API route structure under `/api/v1/` with public and protected route groups.
- [x] Seed the database with demo data: grandmasters (Tal, Petrosian, Fischer), lessons, puzzles, and a demo user.

## 🔗 Resources & Links
- **API Routes:** [[api.php]]
- **Auth Controller:** [[AuthController.php]]
- **Database Migrations:** [[database/migrations/]]
- **Seeders:** [[GrandmasterSeeder]], [[LessonSeeder]], [[PuzzleSeeder]], [[DemoUserSeeder]]
- **ERD Diagram:** [[sparmate_erd.svg]]
- **API Routes Diagram:** [[sparmate_api_routes.svg]]

## 🛠️ Engineering Log & Roadblocks

### Database Schema Design
* **June 6:** Initialized the Laravel project and configured SQLite for rapid local development. The `.env` maps `DB_CONNECTION=sqlite` with the database file at `database/database.sqlite`. PostgreSQL will be used in production; all schema design is forward-compatible.
* **June 7:** Ran migrations for the core relational tables. Key design decisions:
  - **`users`**: Extended Laravel's default with `elo_rating` (default 1200), `streak_days`, and `avatar_url`. Uses Sanctum's `HasApiTokens` trait for token-based mobile auth.
  - **`sparring_matches`**: Stores PGN strings, final FEN, result (`win`/`loss`/`draw`/`in_progress`), move count, duration, average pressure metric, and a JSONB `analysis` column for the classified blunder array from the ML pipeline.
  - **`user_bkt_matrices`**: The critical JSONB column — stores the entire BKT mastery matrix as a serialized JSON object with 8 cognitive skill probabilities (tactical_oversight, positional_error, endgame_fundamentals, opening_theory, king_safety, pawn_structure, piece_coordination, time_management). Default initialized to 0.50 for all skills.
  - **`training_plans`**: Stores the output of the FastAPI coaching engine — `primary_directive` (string), `weekly_focus` (JSON array), `plan_items` (JSON array of daily activities), and `generated_at` timestamp.
  - **`lessons` / `chapters`**: Hierarchical content structure. Each lesson has a category, difficulty, chapter count, color hex, and icon. Chapters belong to a lesson and contain markdown content.
  - **`puzzles`**: FEN position, solution moves (JSON), category, difficulty, rating, theme, and solution text.
  - **`puzzle_attempts`**: Tracks each user's attempt with solved status, time in seconds, and timestamp for streak calculation.

### Authentication Layer
* **June 8:** Implemented `AuthController` with three endpoints:
  - `POST /register`: Creates user + initializes a default BKT matrix (all skills at 0.50) + returns a Sanctum `plainTextToken`. This ensures every user has a coaching baseline from day one.
  - `POST /login`: Validates credentials via `Hash::check()`, returns user + token.
  - `GET /user`: Returns the authenticated user's profile with their BKT matrix eager-loaded.
* **Roadblock:** Initially forgot to initialize the BKT matrix on registration. Users who registered and immediately hit the coaching endpoint would get a null matrix. Fixed by adding `UserBktMatrix::create()` directly in the register method.

### API Controllers
* **June 9-10:** Built the 8 API controllers under `App\Http\Controllers\Api\V1\`:

| Controller | Endpoints | Purpose |
|-----------|-----------|---------|
| `AuthController` | POST /register, POST /login, POST /logout, GET /user | Sanctum token auth lifecycle |
| `DashboardController` | GET /dashboard | Home screen aggregate (active lesson, recent match, daily puzzles, coaching summary, user stats) |
| `LessonController` | GET /lessons, GET /lessons/{id}, POST /lessons/{id}/progress | Lesson catalog with category filtering + progress tracking |
| `GrandmasterController` | GET /grandmasters, GET /grandmasters/{id} | GM persona listing for the sparring selection screen |
| `MatchController` | GET /matches, POST /matches, PUT /matches/{id}, POST /matches/{id}/analyze | Full match lifecycle: create → update with PGN → trigger BKT analysis |
| `PuzzleController` | GET /puzzles/daily, GET /puzzles/recent, POST /puzzles/{id}/attempt | ELO-adaptive daily puzzle selection + attempt tracking + streak logic |
| `CoachingController` | GET /coaching/plan, POST /coaching/refresh | BKT matrix viewer + FastAPI plan generation trigger |
| `AnalyticsController` | GET /analytics/overview | Rating history, match results, phase accuracy, AI insights, top opponents |

### Seeding & Demo Data
* **June 12:** Created comprehensive seeders:
  - **`GrandmasterSeeder`**: 3 AI personas — Tal (Tactical, aggressive, sacrificial), Petrosian (Positional, prophylactic, fortress), Fischer (Generalist, precise, universal). Each includes full metadata: era, nationality, style description, quote, strengths array, preferred openings array, ELO rating, color hex, and icon.
  - **`LessonSeeder`**: Full lesson catalog spanning Opening, Middlegame, Endgame, Tactics, and Strategy categories with hierarchical chapters.
  - **`PuzzleSeeder`**: Rated puzzles across multiple themes (fork, pin, skewer, back-rank mate, etc.).
  - **`DemoUserSeeder`**: Creates a test user with pre-populated match history, lesson progress, puzzle attempts, and a calibrated BKT matrix.
* **June 13:** Ran `php artisan migrate:fresh --seed` — all tables created, all seeders run, demo user functional with `database.sqlite` at 184KB.

### Key Architecture Decisions
* **June 14-15:** Documented the critical integration patterns:
  1. **FastAPI Bridge**: `MatchController::analyze()` and `CoachingController::refresh()` both use Laravel's `Http::timeout(10)->post()` to forward payloads to the FastAPI BKT microservice at `http://127.0.0.1:8000`. Both implement **graceful degradation**: if FastAPI is unavailable, the controller falls back to the existing matrix (match analysis) or generates a basic local plan (coaching).
  2. **JSONB Strategy**: The `analysis` column on `sparring_matches` and the `matrix` column on `user_bkt_matrices` both use `'array'` casting in Eloquent. This means Laravel automatically handles JSON encode/decode, while PostgreSQL will use its native JSONB indexing in production.
  3. **Route Protection**: All API routes except `/register` and `/login` are wrapped in `Route::middleware('auth:sanctum')`. The `MatchController` additionally checks `$match->user_id !== $request->user()->id` to prevent cross-user access.

## 📊 Sprint Velocity
| Task | Status | Notes |
|------|--------|-------|
| Laravel 13 Project Init | ✅ Done | PHP 8.3, SQLite dev DB |
| Database Migrations (13 files) | ✅ Done | All tables including JSONB columns |
| Sanctum Authentication | ✅ Done | Token-based mobile auth |
| Eloquent Models (10 models) | ✅ Done | Full relationship graph |
| API Routes (`/api/v1/`) | ✅ Done | 15 endpoints, public + protected |
| API Controllers (8 controllers) | ✅ Done | Full CRUD + BKT integration |
| Database Seeders (4 seeders) | ✅ Done | GM, Lessons, Puzzles, Demo User |
| FastAPI Bridge Config | ✅ Done | `services.fastapi.url` in config |
| Graceful Degradation | ✅ Done | Fallback when FastAPI unavailable |
