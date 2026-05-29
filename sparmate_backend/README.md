# SparMate Backend API

REST API gateway for the SparMate adaptive chess coaching platform, built with **Laravel 13** (PHP 8.3) and **Laravel Sanctum** for token-based mobile authentication.

## Architecture

```
┌─────────────────┐       Bearer Token        ┌──────────────────────┐
│                  │ ◄──────────────────────── │                      │
│   Laravel 13     │        JSON / REST        │    Flutter App       │
│   REST API       │ ────────────────────────► │    (Dart / FFI)      │
│   :8080          │                           │                      │
└────────┬─────────┘                           └──────────────────────┘
         │
         │  HTTP POST (internal)
         ▼
┌─────────────────┐
│   FastAPI BKT    │
│   Microservice   │  ← Bayesian Knowledge Tracing
│   :8000          │  ← Training Plan Generation
└────────┬─────────┘
         │
         ▼
┌─────────────────┐
│   SQLite / PgSQL │  ← JSON columns for BKT matrices,
│   Database       │    analysis data, lesson content
└─────────────────┘
```

Laravel serves as the **API gateway** — handling auth, CRUD, and request validation — while the **FastAPI microservice** handles computationally heavy BKT calculations. This keeps the gateway fast and the ML logic isolated.

---

## Requirements

- **PHP** ≥ 8.3
- **Composer** ≥ 2.x
- **SQLite** (default, development) or **PostgreSQL** ≥ 15 (production)
- **Python** ≥ 3.11 (for the BKT microservice)

---

## Quick Start

### 1. Install Dependencies

```bash
cd sparmate_backend
composer install
```

### 2. Environment Setup

```bash
cp .env.example .env
php artisan key:generate
```

The default `.env` uses SQLite. For PostgreSQL, update:

```dotenv
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=sparmate
DB_USERNAME=your_user
DB_PASSWORD=your_password
```

### 3. Run Migrations & Seed

```bash
php artisan migrate:fresh --seed
```

This creates all 13 tables and seeds:
- **4** Grandmaster AI personas (Torre, Tal, Petrosian, Carlsen)
- **8** chess lessons with **75** chapters of instructional content
- **20** puzzles with real FEN positions and solutions
- **1** demo user with match history, lesson progress, BKT matrix, and training plan

### 4. Start the Server

```bash
php artisan serve --port=8080
```

### 5. Start the BKT Microservice (optional, separate terminal)

```bash
cd ../ml_microservice
pip install -r requirements.txt
uvicorn main:app --reload --port=8000
```

> The Laravel API gracefully degrades if the FastAPI service is unavailable — coaching endpoints will generate fallback plans locally.

---

## Demo Credentials

| Field | Value |
|-------|-------|
| Email | `demo@sparmate.app` |
| Password | `password123` |

---

## Authentication

All protected endpoints require a **Sanctum Bearer token** in the `Authorization` header:

```
Authorization: Bearer {token}
```

### Login

```bash
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"email":"demo@sparmate.app","password":"password123"}'
```

**Response:**

```json
{
  "user": {
    "id": 1,
    "name": "Marc",
    "email": "demo@sparmate.app",
    "elo_rating": 1420,
    "streak_days": 7
  },
  "token": "1|abc123..."
}
```

### Register

```bash
curl -X POST http://localhost:8080/api/v1/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "New Player",
    "email": "player@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

New users are automatically initialized with:
- **ELO rating**: 1200
- **BKT matrix**: All 8 cognitive skills at 0.50 (uninformed prior)

---

## API Endpoints

All endpoints are prefixed with `/api/v1`.

### Public

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/register` | Create account, returns Sanctum token |
| `POST` | `/login` | Authenticate, returns Sanctum token |

### Protected (requires `Authorization: Bearer {token}`)

#### Auth & Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/logout` | Revoke current token |
| `GET` | `/user` | Get authenticated user profile with BKT matrix |

#### Dashboard (Home Screen)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/dashboard` | Aggregated home screen data: active lesson, recent match, daily puzzles, coaching summary, win/loss stats |

#### Lessons

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/lessons` | List all lessons with user progress. Supports `?category=Opening` filter |
| `GET` | `/lessons/{id}` | Lesson detail with full chapter content |
| `POST` | `/lessons/{id}/progress` | Update lesson progress. Body: `{"progress": 0.5, "current_chapter_id": 3}` |

#### Grandmasters

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/grandmasters` | List all GM AI personas |
| `GET` | `/grandmasters/{id}` | Single GM profile (style, strengths, openings) |

#### Sparring Matches

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/matches` | Paginated match history with GM details |
| `POST` | `/matches` | Start a match. Body: `{"grandmaster_id": 1}` |
| `PUT` | `/matches/{id}` | Complete a match. Body: `{"result": "win", "pgn": "...", "move_count": 42, "duration_seconds": 600}` |
| `POST` | `/matches/{id}/analyze` | Trigger BKT analysis via FastAPI microservice |

#### Puzzles

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/puzzles/daily` | Daily puzzle set (5 puzzles matched to user ELO) |
| `POST` | `/puzzles/{id}/attempt` | Record attempt. Body: `{"solved": true, "time_seconds": 45}` |
| `GET` | `/puzzles/recent` | Recent puzzle attempt history |

#### Coaching Engine

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/coaching/plan` | Current BKT matrix, weakest skills, and training plan |
| `POST` | `/coaching/refresh` | Regenerate training plan via FastAPI (or local fallback) |

#### Analytics

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/analytics/overview` | Rating history, W/L/D stats, phase accuracy, insights, top opponents |

---

## Database Schema

### Entity Relationship Overview

```
users ──┬── user_lesson_progress ── lessons ── chapters
        │
        ├── sparring_matches ── grandmasters
        │
        ├── puzzle_attempts ── puzzles
        │
        ├── user_bkt_matrices
        │
        └── training_plans
```

### Tables

| Table | Key Columns | Notes |
|-------|-------------|-------|
| `users` | `elo_rating`, `streak_days`, `avatar_url` | Extended with chess profile fields |
| `lessons` | `title`, `slug`, `category`, `difficulty` | Categories: Opening, Middlegame, Endgame, Tactics, Strategy |
| `chapters` | `lesson_id`, `content` (JSON) | Rich content with text, FEN positions, quiz markers |
| `user_lesson_progress` | `user_id`, `lesson_id`, `progress` (0-1) | Unique per user + lesson pair |
| `grandmasters` | `style`, `strengths` (JSON), `openings` (JSON) | 4 AI personas with personality data |
| `sparring_matches` | `pgn`, `result`, `analysis` (JSON) | Full game records with ML-classified blunders |
| `puzzles` | `fen`, `solution_moves` (JSON), `rating` | Real chess positions with difficulty ratings |
| `puzzle_attempts` | `solved`, `time_seconds` | Per-user solve tracking |
| `user_bkt_matrices` | `matrix` (JSON) | 8 cognitive skill mastery probabilities |
| `training_plans` | `weekly_focus` (JSON), `plan_items` (JSON) | AI-generated coaching schedules |

---

## BKT Cognitive Skills

The Bayesian Knowledge Tracing matrix tracks mastery across 8 chess cognitive dimensions:

| Skill | Description | Default |
|-------|-------------|---------|
| `tactical_oversight` | Pattern recognition for tactics (forks, pins, skewers) | 0.50 |
| `positional_error` | Strategic understanding of positional play | 0.50 |
| `endgame_fundamentals` | Lucena, Philidor, king opposition, pawn endgames | 0.50 |
| `opening_theory` | Knowledge of opening lines and transpositions | 0.50 |
| `king_safety` | Evaluation of king vulnerability and attack vectors | 0.50 |
| `pawn_structure` | Understanding of pawn chains, isolated pawns, pawn breaks | 0.50 |
| `piece_coordination` | Harmonious piece placement and avoiding redundancy | 0.50 |
| `time_management` | Clock usage and decision speed under pressure | 0.50 |

Each skill is updated after every analyzed match using the **Corbett & Anderson (1995)** Bayesian posterior formula with calibrated learning, guessing, and slip parameters.

---

## Project Structure

```
sparmate_backend/
├── app/
│   ├── Http/Controllers/Api/V1/
│   │   ├── AnalyticsController.php
│   │   ├── AuthController.php
│   │   ├── CoachingController.php
│   │   ├── DashboardController.php
│   │   ├── GrandmasterController.php
│   │   ├── LessonController.php
│   │   ├── MatchController.php
│   │   └── PuzzleController.php
│   └── Models/
│       ├── Chapter.php
│       ├── Grandmaster.php
│       ├── Lesson.php
│       ├── Puzzle.php
│       ├── PuzzleAttempt.php
│       ├── SparringMatch.php
│       ├── TrainingPlan.php
│       ├── User.php
│       ├── UserBktMatrix.php
│       └── UserLessonProgress.php
├── database/
│   ├── migrations/          # 13 migration files
│   └── seeders/
│       ├── DatabaseSeeder.php
│       ├── DemoUserSeeder.php
│       ├── GrandmasterSeeder.php
│       ├── LessonSeeder.php
│       └── PuzzleSeeder.php
├── routes/
│   ├── api.php              # All 20 API routes
│   └── web.php
├── config/
│   └── services.php         # FastAPI URL config
└── .env                     # FASTAPI_URL=http://127.0.0.1:8000
```

---

## FastAPI BKT Microservice

Located at `../ml_microservice/`. See [ml_microservice/README.md](../ml_microservice/README.md) for details.

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | `GET` | Service health check |
| `/api/v1/update-mastery` | `POST` | Update BKT matrix after match analysis |
| `/api/v1/generate-plan` | `POST` | Generate personalized training plan |

**Configuration:** Set `FASTAPI_URL` in `.env` (default: `http://127.0.0.1:8000`).

---

## Useful Commands

```bash
# Run migrations
php artisan migrate

# Reset and re-seed everything
php artisan migrate:fresh --seed

# List all registered routes
php artisan route:list --path=api

# Clear all caches
php artisan optimize:clear

# Interactive shell (Tinker)
php artisan tinker
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_CONNECTION` | `sqlite` | Database driver (`sqlite`, `pgsql`, `mysql`) |
| `DB_DATABASE` | `database/database.sqlite` | Database path (SQLite) or name (PgSQL) |
| `FASTAPI_URL` | `http://127.0.0.1:8000` | BKT microservice URL |
| `APP_URL` | `http://localhost` | Application base URL |

---

## License

This project is part of the SparMate academic capstone and is not licensed for public distribution.
