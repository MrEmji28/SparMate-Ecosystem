# ♟️ SparMate — Adaptive Chess Coaching Ecosystem

> **SparMate moves beyond simply punishing mistakes; it acts as an adaptive sparring partner and tutor.** It uses Bayesian Knowledge Tracing (BKT), machine-learned blunder classification, and grandmaster-style AI personas to provide personalized, evolving chess coaching.

[![CI](https://github.com/MrEmji28/SparMate-Ecosystem/actions/workflows/ci.yml/badge.svg)](https://github.com/MrEmji28/SparMate-Ecosystem/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.32-blue?logo=flutter)](https://flutter.dev)
[![Laravel](https://img.shields.io/badge/Laravel-12.x-red?logo=laravel)](https://laravel.com)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green?logo=fastapi)](https://fastapi.tiangolo.com)
[![License](https://img.shields.io/badge/License-GPLv3-yellow)](LICENSE)

---

## 📐 Architecture

```
┌──────────────────┐     HTTP      ┌───────────────────┐     HTTP      ┌──────────────────┐
│   Flutter App    │ ────────────► │   Laravel API     │ ────────────► │  FastAPI ML      │
│   (Dart/Flutter) │               │   Gateway (PHP)   │               │  Microservice    │
│                  │               │                   │               │  (Python)        │
│  • Sparring UI   │               │  • Auth (Sanctum) │               │  • BKT Engine    │
│  • Coaching View │               │  • Match CRUD     │               │  • RF/SVM Models │
│  • Analytics     │               │  • Coaching Proxy  │               │  • ONNX Runtime  │
│  • Pressure Gauge│               │  • Analytics       │               │  • Feature Eng.  │
└──────────────────┘               └───────────────────┘               └──────────────────┘
       :8000                              :8000                              :8001
   Provider State                       MySQL DB                        Scikit-Learn
```

---

## 🧩 Project Structure

```
SparMate/
├── sparmate_app/          # Flutter mobile application
│   ├── assets/pieces/     # Lichess cburnett SVG chess pieces
│   └── lib/
│       ├── core/          # Theme, engine, services, state
│       ├── features/      # Auth, Home, Sparring, Coaching, Analytics, Lessons
│       └── shared/        # AppShell, reusable widgets
│
├── sparmate_backend/      # Laravel API gateway
│   ├── app/Http/Controllers/Api/V1/   # REST controllers
│   ├── app/Models/                     # Eloquent models
│   ├── database/migrations/           # Schema migrations
│   ├── database/seeders/              # GM & lesson seeders
│   ├── routes/api.php                 # API routes
│   └── tests/Feature/                 # PHPUnit integration tests
│
├── ml_microservice/       # FastAPI + ML pipeline
│   ├── app.py                         # FastAPI server
│   ├── bkt_engine.py                  # Bayesian Knowledge Tracing
│   ├── classifier.py                  # Blunder classifier (RF/SVM/ONNX)
│   ├── feature_engineering.py         # 40+ chess features
│   ├── train_classifier.py            # Model training script
│   ├── data_generator.py              # Synthetic training data
│   ├── test_microservice.py           # Pytest suite
│   └── models/                        # Trained .joblib + .onnx models
│
├── docs/                  # Obsidian documentation vault
│   ├── 1-Projects/Sprints/            # Sprint logs (1–9)
│   └── 3-Resources/                   # SVG diagrams (ERD, API, wireframes)
│
└── .github/workflows/ci.yml          # GitHub Actions CI pipeline
```

---

## 🔧 Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| **Flutter SDK** | ≥ 3.32 | Mobile app |
| **Dart** | ≥ 3.8 | Flutter language |
| **PHP** | ≥ 8.2 | Laravel backend |
| **Composer** | ≥ 2.x | PHP dependencies |
| **MySQL** | ≥ 8.0 | Database |
| **Python** | ≥ 3.11 | ML microservice |
| **pip** | ≥ 23.x | Python dependencies |
| **Android Studio / Xcode** | Latest | Emulator/Simulator |

---

## 🚀 Getting Started

### Step 1: Clone the Repository

```bash
git clone https://github.com/MrEmji28/SparMate-Ecosystem.git
cd SparMate-Ecosystem
```

### Step 2: Start MySQL

Ensure MySQL is running and create the database:

```sql
CREATE DATABASE sparmate;
```

### Step 3: Set Up the Laravel Backend

```bash
cd sparmate_backend

# Install PHP dependencies
composer install

# Configure environment
cp .env.example .env
php artisan key:generate

# Edit .env with your MySQL credentials:
#   DB_DATABASE=sparmate
#   DB_USERNAME=root
#   DB_PASSWORD=your_password
#   FASTAPI_URL=http://127.0.0.1:8001

# Run migrations and seed the database
php artisan migrate --seed

# Start the Laravel server
php artisan serve
# ✅ Running at http://127.0.0.1:8000
```

### Step 4: Set Up the ML Microservice

```bash
cd ml_microservice

# Create and activate a virtual environment
python3 -m venv venv
source venv/bin/activate        # macOS/Linux
# venv\Scripts\activate         # Windows

# Install Python dependencies
pip install -r requirements.txt

# Start the FastAPI server
uvicorn app:app --port 8001
# ✅ Running at http://127.0.0.1:8001
```

### Step 5: Run the Flutter App

```bash
cd sparmate_app

# Install Dart dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

> **💡 Tip:** The app works in **demo mode** without the backend. When the backend is running, widgets show "LIVE FROM API" badges with real data.

---

## 📱 Flutter → Backend Connection

The Flutter `ApiService` base URL depends on your platform:

| Platform | Base URL | Why |
|----------|----------|-----|
| **Android Emulator** | `http://10.0.2.2:8000` | Emulator maps `10.0.2.2` to host `localhost` |
| **iOS Simulator** | `http://127.0.0.1:8000` | Direct localhost access |
| **Physical Device** | `http://<your-ip>:8000` | Use your machine's LAN IP |
| **Chrome (Web)** | `http://localhost:8000` | Direct localhost |

To change the base URL, edit [`sparmate_app/lib/core/services/api_service.dart`](sparmate_app/lib/core/services/api_service.dart) line 13.

---

## 🧪 Testing

### Run All Tests

```bash
# Laravel (14 integration tests)
cd sparmate_backend && php artisan test

# ML Microservice (17 tests)
cd ml_microservice && source venv/bin/activate && python -m pytest test_microservice.py -v

# Flutter (static analysis)
cd sparmate_app && flutter analyze
```

### Laravel Test Suite

```
✅ Authentication (register, login, logout, token guard)
✅ Dashboard endpoint
✅ Grandmaster CRUD
✅ Match lifecycle (create → update → analyze)
✅ Cross-user access prevention (403)
✅ Coaching plan (generate + refresh)
✅ Lesson progress tracking
✅ Analytics overview
✅ Daily puzzles
```

### ML Microservice Test Suite

```
✅ Health check endpoint
✅ Feature engineering (40+ features)
✅ BKT mastery updates (8 skill categories)
✅ Training plan generation (5-day schedule)
✅ Blunder classification (RF + SVM + ONNX)
✅ ONNX ↔ Scikit-Learn prediction parity
✅ Edge cases (empty input, invalid data)
```

### Quick API Smoke Test

```bash
# Register
curl -X POST http://127.0.0.1:8000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com","password":"password","password_confirmation":"password"}'

# Login (copy the token)
curl -X POST http://127.0.0.1:8000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password"}'

# Dashboard
curl http://127.0.0.1:8000/api/v1/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"

# Coaching plan (triggers FastAPI BKT engine)
curl http://127.0.0.1:8000/api/v1/coaching/plan \
  -H "Authorization: Bearer YOUR_TOKEN"

# Analytics
curl http://127.0.0.1:8000/api/v1/analytics/overview \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🎯 API Reference

### Authentication & Onboarding
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/register` | Register a new user |
| POST | `/api/v1/login` | Login (returns Sanctum token) |
| POST | `/api/v1/logout` | Revoke current token |
| GET | `/api/v1/user` | Get authenticated user |
| POST | `/api/v1/onboarding` | Submit 5-question skill survey (sets ELO + BKT) |

### Dashboard & Coaching
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/dashboard` | Home screen data |
| GET | `/api/v1/coaching/plan` | Get BKT coaching plan |
| POST | `/api/v1/coaching/refresh` | Re-generate plan via FastAPI |

### Sparring Matches
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/matches` | List match history |
| POST | `/api/v1/matches` | Start a new match |
| PUT | `/api/v1/matches/{id}` | Submit game result + PGN |
| POST | `/api/v1/matches/{id}/analyze` | Trigger BKT analysis |

### Lessons & Puzzles
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/lessons` | List all lessons |
| GET | `/api/v1/lessons/{id}` | Get lesson detail |
| POST | `/api/v1/lessons/{id}/progress` | Update lesson progress |
| GET | `/api/v1/puzzles/daily` | Get daily puzzles |
| POST | `/api/v1/puzzles/{id}/attempt` | Submit puzzle attempt |

### Analytics
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/analytics/overview` | Full analytics (rating, W/L/D, insights) |

### Grandmasters
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/grandmasters` | List all GM personas |
| GET | `/api/v1/grandmasters/{id}` | Get GM detail |

---

## 🏗️ Milestone 2 Objectives

| # | Objective | Description | Status |
|---|-----------|-------------|:------:|
| 1 | **Heuristic-Based Style Profiles** | 5 GM personas (Torre, Tal, Petrosian, Carlsen, Fischer) with playstyle-weighted Stockfish parameters | ✅ |
| 2 | **Rule-Based Pressure Analysis** | Real-time Pressure Gauge widget using piece tension, king safety, time pressure, and material metrics | ✅ |
| 3 | **Adaptive Coaching Engine** | BKT mastery tracking → RF/SVM blunder classification → ONNX export → FastAPI microservice → Laravel proxy | ✅ |

---

## 📋 Sprint History

| Sprint | Focus | Key Deliverable |
|--------|-------|-----------------|
| 1 | Project Setup | Flutter scaffold, Laravel API, MySQL schema, Obsidian docs |
| 2 | UI Build-Out | 5 screens (Home, Sparring, Coaching, Analytics, Lessons) |
| 3 | Backend API | 15 REST endpoints, Sanctum auth, Eloquent models |
| 4 | BKT Microservice | FastAPI, BKT engine, 8-skill mastery model |
| 5 | ML Pipeline | RF/SVM classifiers, 40+ features, 91% accuracy |
| 6 | ONNX & Integration | ONNX export, Laravel→FastAPI proxy, Stockfish engine |
| 7 | Testing & QA | 31 tests (PHPUnit + pytest), ONNX parity validation |
| 8 | Integration | API service layer, Provider state, Pressure Gauge, CI/CD |
| 9 | UX & Gameplay | Onboarding survey, dynamic dashboard, interactive chess board, Lichess SVG pieces |

---

## 📄 License

This project uses [Stockfish](https://stockfishchess.org/) which is licensed under **GPLv3**. The SparMate project is therefore also licensed under the [GNU General Public License v3.0](LICENSE).

---

## 👤 Author

**Marc Gene Crisolo** — Capstone Project, Milestone 2
