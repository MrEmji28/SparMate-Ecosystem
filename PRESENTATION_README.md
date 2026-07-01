# ♟️ SparMate — Adaptive Chess Coaching Ecosystem

> **SparMate is an AI-powered chess coaching application that acts as your personal sparring partner and tutor.**
> It adapts to your skill level in real time, identifies weaknesses you don't even know you have, and delivers personalized training through grandmaster-style AI personas.

---

## 🎯 The Problem It Solves

Most chess apps tell you *what* move you missed. SparMate tells you *why* you keep missing it — and builds a personalized training plan to fix it.

Traditional chess engines punish mistakes. SparMate **understands** them.

---

## 🌟 Core Features

### 1. ♟️ Interactive Sparring Board
Players play live chess games against an AI opponent rendered with authentic **Lichess SVG chess pieces**. The board is interactive and touch-responsive, built entirely in Flutter with no third-party board libraries.

- Real-time legal move validation
- Full PGN (game notation) capture and submission
- Piece drag-and-drop with animated feedback
- Live dual chess clocks (15 min per side)
- Resign and draw-offer controls

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Flutter (Dart)** | Renders the interactive chess board and all UI components natively on Android & iOS |
| **chess-0.8.1 (Dart)** | Handles all game rules, move validation, PGN generation, and game-state detection |
| **Lichess SVG Assets** | Open-source chess piece artwork (cburnett set) used for authentic piece rendering |
| **Provider (State Management)** | Keeps board state, move history, and game status in sync across the UI in real time |

---

### 2. 🧠 Adaptive Coaching Engine (BKT)

At the heart of SparMate is a **Bayesian Knowledge Tracing (BKT)** engine — the same technique used in intelligent tutoring systems like Carnegie Learning.

**How it works:**
1. A match is registered on the backend when the sparring screen opens (`POST /matches`)
2. After every game, PGN + result are submitted to Laravel (`PUT /matches/{id}`)
3. Laravel calls FastAPI → blunders are classified into **8 chess skill categories**
4. The BKT engine updates your personal **mastery probability** for each skill
5. A 5-day personalized training plan is generated based on your weakest areas
6. Your **ELO rating** is updated using the standard FIDE formula

**The 8 tracked skill categories:**

| Skill | What It Measures |
|-------|-----------------:|
| `tactical_oversight` | Missing winning tactics and combinations |
| `positional_error` | Poor piece placement and long-term planning |
| `endgame_fundamentals` | King-and-pawn technique, conversion accuracy |
| `opening_theory` | Accuracy in the first 10–15 moves |
| `king_safety` | Leaving your king exposed to attack |
| `pawn_structure` | Creating and avoiding pawn weaknesses |
| `piece_coordination` | Harmony between all pieces |
| `time_management` | Clock usage and decision-making under time pressure |

Each skill has a **mastery score from 0–100%**. The coaching plan always prioritizes the skills where you're most likely to improve fastest.

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Python 3.11** | Implements the BKT engine logic (`bkt_engine.py`) using pure mathematics — no ML library required |
| **FastAPI** | Exposes the BKT engine as a REST microservice, callable by the Laravel backend |
| **Laravel (PHP)** | Acts as the proxy — receives the Flutter app's request, forwards it to FastAPI, and stores the returned coaching plan in MySQL |
| **MySQL** | Persists each user's skill mastery scores between sessions |

---

### 3. 🤖 Grandmaster AI Personas

SparMate features **4 Grandmaster AI opponents**, each powered by the **Stockfish chess engine** configured with historically accurate UCI parameters to emulate the real player's playing style.

**How it works:**
1. When a game starts, Stockfish initialises in the background and waits for `readyok`
2. Each GM's `Skill Level` (0–20) and `Contempt` (aggression vs. draw-seeking) are applied via UCI options
3. On every AI turn, the current FEN position is sent to Stockfish with a GM-specific `movetime`
4. Stockfish returns the best move for that configuration — the AI plays like a real chess engine, not a random picker
5. If the engine is still initialising on the first move, the app waits up to 8 seconds before falling back to the heuristic selector

| Persona | Peak ELO | Stockfish Config | Real-Life Style |
|---------|----------|------------------|-----------------|
| **Eugene Torre** | ~2600 | Skill 14, Contempt 0, 1200ms | Patient positional builder; inventor of the Torre Attack (1.d4 Nf3 Bg5). Balanced — no aggression or draw bias |
| **Mikhail Tal** | ~2705 | Skill 17, **Contempt +50**, 1500ms | "The Magician from Riga." Strongly avoids draws, hunts for sacrificial wins at all costs. World Champion 1960 |
| **Tigran Petrosian** | ~2645 | Skill 16, **Contempt -50**, 1800ms | "Iron Tigran." Comfortable with draws; grinds positionally. Longest thinking time reflects prophylactic patience. World Champion 1963–1969 |
| **Magnus Carlsen** | 2882 | **Skill 20**, Contempt 24, 2000ms | Full engine strength. Slight winning bias. Longest movetime = most devastating opponent. World Champion 2013–2023 |

**Difficulty System (routes to different engine behaviour):**

| Difficulty | What the AI Does |
|------------|------------------|
| **Easy** | Skips Stockfish entirely — heuristic selector runs with 70% random moves (forgiving for beginners) |
| **Medium** | Stockfish at this GM's exact Skill Level + Contempt. Each opponent feels distinctly different |
| **Hard** | Overrides all GMs to **Skill 20, Contempt 24, 2000ms** (Carlsen-level full power) regardless of who you picked |

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Stockfish (UCI protocol)** | Powers every AI move on Medium/Hard. Each GM sets `Skill Level` (strength), `Contempt` (aggression), and `movetime` (thinking time) via UCI options before `go movetime` |
| **chess-0.8.1 (Dart)** | Generates legal moves for move validation, board state, and the Easy-mode heuristic fallback selector |
| **Flutter** | Renders the GM selector UI, difficulty buttons, and the "is thinking…" status during Stockfish's movetime |
| **Laravel (PHP)** | Stores GM persona definitions in MySQL (`grandmasters` table); provides `elo_rating` used for ELO calculation |
| **FastAPI (Python)** | Indirectly — `/generate-plan` uses the GM's ELO to calibrate training plan difficulty; `/coaching-insights` references GM name in feedback |

---

### 4. 📊 Real-Time Pressure Gauge

A unique widget that calculates **board tension in real time** using four metrics:

- **Piece Tension** — How many of your pieces are under attack
- **King Safety Score** — Calculated from pawn shield integrity and open files near the king
- **Material Balance** — Point difference between you and the opponent
- **Time Pressure** — How much of your clock remains

This produces a live **pressure score** displayed as a visual gauge on the sparring screen, giving players immediate situational awareness without needing engine analysis.

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Flutter (Dart)** | Custom-painted widget (`CustomPainter`) renders the animated gauge needle and color gradient in real time |
| **Dart (pure logic)** | All four pressure metrics are calculated client-side in Dart — no server call needed, so updates are instant |
| **Provider** | Watches the live game state and triggers a widget rebuild every time a move is made |

---

### 5. 🔬 ML Blunder Classification Pipeline

A full machine learning pipeline (trained in Python, deployed via FastAPI) that classifies chess mistakes into the 8 BKT skill categories:

```
Raw Game Moves
     │
     ▼
Feature Engineering  ←── 40+ chess-specific features extracted
     │                    (material delta, tempo, castling, mobility...)
     ▼
RF / SVM Classifier  ←── Trained on 10,000+ synthetic game positions
     │                    91% classification accuracy
     ▼
ONNX Export          ←── Model exported for fast, portable inference
     │
     ▼
BKT Engine           ←── Updates mastery probabilities for 8 skills
     │
     ▼
Personalized Plan    ←── 5-day coaching schedule returned to the app
```

> **Fallback safety net:** If the Flutter app doesn't send per-move Stockfish evaluations, the Laravel `approximateMoveAnalyses()` method generates synthetic feature data from the match PGN + result + duration so the BKT classifier always runs — no game is ever unanalyzed.

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Scikit-Learn (Python)** | Trains the **Random Forest** and **Support Vector Machine (SVM)** classifiers on synthetic chess game data |
| **ONNX (Open Neural Network Exchange)** | Exports the trained model to a portable format — enabling fast inference without loading the full Scikit-Learn runtime |
| **ONNX Runtime** | Loads and runs the `.onnx` model at prediction time; platform-agnostic and significantly faster than Scikit-Learn at inference |
| **NumPy / Pandas** | Used in `feature_engineering.py` to extract and transform 40+ numerical features from raw PGN move data |
| **FastAPI** | Wraps the entire pipeline in a REST API endpoint (`/classify-match`) that Laravel calls after each match |
| **Python `data_generator.py`** | Generates 10,000+ synthetic training positions with realistic blunder distributions to train the classifier |

---

### 6. 🏆 Live ELO Rating System

After every completed match, SparMate automatically calculates your **ELO rating change** using the **standard FIDE Elo formula** (K=32):

```
E  = 1 / (1 + 10^((opponentRating − playerRating) / 400))
Δ  = round(32 × (actual − E))   // actual: win=1.0, draw=0.5, loss=0.0
```

- Beating a higher-rated GM earns **more points** than beating an easier one
- Rating is floored at 100 to prevent negative values
- The post-game result sheet shows the **rating delta instantly** (`+12` / `-8`) with a trending arrow icon
- The new rating is reflected across the Home screen, Analytics, and History tab in real time

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Laravel (PHP)** | Executes the Elo formula server-side in `MatchController@analyze`; updates `users.elo_rating` and saves `elo_before`, `elo_after`, `elo_change` on the match record |
| **MySQL** | `sparring_matches` table stores per-match ELO snapshot columns (`elo_before`, `elo_after`, `elo_change`) |
| **Flutter / Provider** | `AppState.completeMatch()` receives `rating_change` + `new_rating` from the API and updates `_user` locally without a full re-fetch |

---

### 7. 📋 Match History Tab

A dedicated **History** tab (5th tab in the bottom navigation) that shows every sparring game the user has played:

- **Stats header**: Games played / Wins / Losses / Draws / Analyzed count
- **Per-match cards**: GM name, result badge, ELO delta (`+12` / `-8`), move count, duration, relative date
- **BKT status badge**: `✅ BKT Analyzed` (green) or `⏳ Pending` (orange) per match
- **Blunder breakdown bars**: For analyzed games — top 3 weakest skills with proportional colour-coded bars
- Pull-to-refresh, loading shimmer skeleton, and empty state
- **Auto-refreshes** after every completed game so it's always current

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Laravel (PHP)** | `GET /api/v1/matches` returns paginated match history ordered by `played_at DESC`, including grandmaster, ELO columns, and blunder categories |
| **Flutter** | `MatchHistoryScreen` renders stats, match cards, and blunder breakdown from the API response |
| **Provider / AppState** | `fetchMatches()` is called on tab load and automatically after `completeMatch()` to keep history in sync |

---

### 8. 📚 Lessons & Daily Puzzles

- Curated lessons across openings, tactics, endgames, and strategy
- Daily puzzles that update every 24 hours
- Progress tracking per lesson with completion percentages

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Laravel (PHP)** | Serves lesson content and daily puzzles via REST endpoints; handles progress writes to the database |
| **MySQL** | Stores lesson data, puzzle sets, and per-user completion records |
| **Laravel Seeders** | Pre-populates the database with curated lesson and puzzle content at setup time (`php artisan db:seed`) |
| **Flutter** | Renders lesson cards, puzzle boards, and the progress tracker UI |

---

### 9. 📈 Analytics Dashboard

A full analytics view showing:
- **ELO Rating** progression over time (read directly from the `elo_after` snapshot stored on each match row)
- **Win / Loss / Draw** breakdown with a donut chart
- **Phase accuracy** (Opening / Middlegame / Endgame) derived from the BKT mastery matrix
- **AI-generated insights** based on the weakest/strongest BKT skill and win-rate trend
- **Top opponents** — grandmaster win-rate breakdown across all sparring sessions
- **🤖 14-Day ELO Forecast** powered by a Linear Regression model running in the FastAPI ML microservice

#### 🤖 Machine Learning: ELO Trend Prediction (Linear Regression)

The analytics dashboard integrates a real ML prediction pipeline via the existing FastAPI microservice:

**Algorithm — `sklearn.linear_model.LinearRegression`**
1. Maps each historical ELO value to a sequential index: `X = [0, 1, 2, ... n-1]`
2. Fits `LinearRegression` on `(X, ELO)` pairs from the user's last 30 matches
3. Computes **R² score** (goodness-of-fit — how well the line describes past progression)
4. Extrapolates the fitted line over the next **14 days** as the forecast
5. Estimates a **confidence band** using ±1 standard deviation of the residuals
6. Anchors the forecast to the real current ELO to eliminate visual jumps

**Output used in the UI:**

| Field | Description |
|---|---|
| `predicted_ratings` | 14 future ELO values (one per day) — rendered as a dashed line |
| `lower_bound` / `upper_bound` | Confidence band shaded around the forecast |
| `trend` | `"improving"` / `"stable"` / `"declining"` (slope > ±1.5 ELO/match threshold) |
| `projected_elo` | Single predicted ELO at the end of the 14-day horizon |
| `slope` | ELO change per match (interpretable unit shown in the UI) |
| `r2_score` | Displayed as a "Model Fit" percentage so users can gauge forecast reliability |

**Graceful degradation:** If the ML microservice is unavailable, Laravel returns `elo_forecast: null` and the Flutter card shows a flat demo line — the rest of analytics continues to work normally.

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **FastAPI (Python)** | Hosts `POST /api/v1/predict-elo` — fits `LinearRegression` via scikit-learn on the user's ELO history and returns a 14-day forecast with confidence band, R² score, and trend label |
| **scikit-learn** | `LinearRegression` + `r2_score` from `sklearn.linear_model` and `sklearn.metrics` — no GPU required, runs in-process with NumPy |
| **Laravel (PHP)** | Reads the `elo_after` column stored per-match by the ELO algorithm, builds the ordered history list, calls FastAPI with `Http::timeout(5)`, and bundles the forecast into the analytics JSON response |
| **MySQL** | Stores all match results, `elo_after` and `elo_change` per match (written at game-end by the ELO algorithm), and BKT skill mastery values |
| **Flutter** | Renders the `EloForecastCard` with a dashed forecast line, shaded confidence band, projected ELO stat, slope readout, and R² badge; falls back gracefully to a demo line if forecast data is null |
| **Provider** | Manages `analyticsLoading` state — shows a spinner and animated refresh button while data is fetching |

---

### 10. 🔐 Onboarding & Personalization

New users complete a **5-question skill survey** that:
- Sets their starting **ELO estimate**
- Seeds their **initial BKT mastery scores**
- Selects the best GM persona to start sparring against

**🛠️ Technologies Used:**
| Technology | Role |
|-----------|------|
| **Flutter** | Renders the multi-step onboarding survey with animated transitions between questions |
| **Laravel Sanctum** | Issues a secure bearer token on registration, authenticating all subsequent API requests |
| **Laravel (PHP)** | Processes survey answers server-side to compute the initial ELO and seed BKT skill scores in MySQL |
| **MySQL** | Stores the resulting user profile — ELO, skill baselines, and preferred GM persona |

---

## 🏗️ System Architecture

```
┌─────────────────────────┐
│   Flutter Mobile App    │   ← What the user sees and touches
│  (Dart, Provider State) │
└──────────┬──────────────┘
           │ REST API (HTTP/JSON)
           ▼
┌─────────────────────────┐
│   Laravel API Gateway   │   ← Business logic, auth, ELO calc, data storage
│   (PHP 8.2, Sanctum)    │
│   MySQL Database        │
└──────────┬──────────────┘
           │ REST API (HTTP/JSON)
           ▼
┌─────────────────────────┐
│  FastAPI ML Microservice│   ← AI & machine learning engine
│  (Python 3.11)          │
│  BKT + RF/SVM + ONNX    │
└─────────────────────────┘
```

**Why this architecture?**
- **Separation of concerns** — UI, business logic, and ML are fully decoupled
- **Scalability** — The ML service can be scaled independently of the app
- **Testability** — Each layer has its own isolated test suite

---

## 🧰 Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter 3.32 (Dart) | Cross-platform iOS & Android UI |
| **Chess Logic** | chess-0.8.1 (Dart) | Move validation, PGN, game state, Easy-mode heuristic AI |
| **AI Engine** | Stockfish (UCI protocol) | Powers all Medium/Hard AI moves via per-GM `Skill Level`, `Contempt`, `movetime` |
| **State Management** | Provider | Reactive UI updates |
| **API Gateway** | Laravel 12 (PHP 8.2) | REST API, Auth, ELO, Database ORM |
| **Database** | MySQL 8.0 | Persistent data storage |
| **ML Microservice** | FastAPI (Python 3.11) | BKT engine, blunder classification |
| **ML Models** | Scikit-Learn (RF/SVM) | Blunder classification |
| **Model Format** | ONNX | Portable, fast inference |
| **Authentication** | Laravel Sanctum | Token-based API security |
| **CI/CD** | GitHub Actions | Automated test pipeline |

---

## ✅ End-to-End Pipeline (Post-Game Flow)

Every completed game triggers this automatic chain:

```
Game ends (checkmate / resign / draw)
  │
  ├─ 1. PUT /matches/{id}          → saves PGN, result, move_count, duration_seconds
  │
  ├─ 2. POST /matches/{id}/analyze (Laravel → FastAPI)
  │       ├─ /classify-match       → classifies blunders into 8 skill categories
  │       ├─ /update-mastery       → BKT matrix updated in MySQL
  │       ├─ /generate-plan        → new 5-day training plan generated
  │       └─ ELO formula (K=32)    → user.elo_rating updated, delta saved to match
  │
  ├─ 3. POST-GAME SHEET shows:
  │       ├─ Result (Victory / Defeat / Draw)
  │       ├─ ELO change badge (+12 / -8)
  │       └─ BKT coaching plan status
  │
  └─ 4. AppState refreshes:
          ├─ bktMatrix + trainingPlan
          ├─ user.elo_rating (instant, no re-fetch)
          └─ matches list (History tab auto-updates)
```

---

## ✅ Test Coverage

| Layer | Framework | Tests |
|-------|-----------|-------|
| Laravel API | PHPUnit | 14 integration tests |
| ML Microservice | pytest | 17 unit/integration tests |
| Flutter | `flutter analyze` | Static analysis |

**What's tested:**
- Full authentication flow (register → login → logout → token guard)
- Match lifecycle (create → play → submit → BKT analysis → ELO update)
- BKT mastery updates across all 8 skill categories
- ELO calculation correctness (win/loss/draw scenarios)
- RF, SVM, and ONNX prediction parity
- Cross-user access prevention (security)
- Edge cases (empty input, invalid game data)

---

## 🗺️ Development Journey — 10 Sprints

| Sprint | Focus | Key Deliverable |
|--------|-------|-----------------|
| 1 | Foundation | Flutter scaffold, Laravel API, MySQL schema |
| 2 | UI Build-Out | 5 core screens (Home, Sparring, Coaching, Analytics, Lessons) |
| 3 | Backend API | 15 REST endpoints, Sanctum auth, Eloquent models |
| 4 | BKT Microservice | FastAPI server, BKT engine, 8-skill mastery model |
| 5 | ML Pipeline | RF/SVM classifiers, 40+ features, 91% accuracy |
| 6 | ONNX & Integration | ONNX export, Laravel→FastAPI proxy, Stockfish engine |
| 7 | Testing & QA | 31 automated tests, ONNX parity validation |
| 8 | Integration | API service layer, Provider state, Pressure Gauge, CI/CD |
| 9 | UX & Gameplay | Onboarding survey, dynamic dashboard, interactive chess board |
| 10 | Live Features | ELO rating system, Match History tab, Stockfish UCI AI personas, BKT persistence fix |

---

## 🎓 Key Academic Concepts Demonstrated

| Concept | Where It Appears |
|---------|-----------------|
| **Bayesian Knowledge Tracing** | `ml_microservice/bkt_engine.py` — Corbett & Anderson (1995) model |
| **Supervised Machine Learning** | `classifier.py` — Random Forest & SVM classification |
| **Feature Engineering** | `feature_engineering.py` — 40+ domain-specific chess features |
| **Elo Rating System** | `MatchController@analyze` — FIDE standard formula (K=32) |
| **UCI Chess Engine Integration** | `StockfishEngine` — per-GM `Skill Level`, `Contempt`, `movetime` via Universal Chess Interface |
| **Model Portability (ONNX)** | ONNX export for framework-agnostic inference |
| **RESTful API Design** | Versioned Laravel API (`/api/v1/...`) |
| **Token-Based Authentication** | Laravel Sanctum bearer tokens |
| **State Management** | Flutter Provider pattern for reactive UI |
| **Microservice Architecture** | Decoupled Laravel + FastAPI services |
| **Database Migration Strategy** | Incremental Laravel migrations for schema evolution |

---

## 👤 Author

**Marc Gene Crisolo**
Capstone Project — *SparMate: Adaptive Chess Coaching Ecosystem*

> *"Chess is not about memorizing moves. It's about understanding why."*
