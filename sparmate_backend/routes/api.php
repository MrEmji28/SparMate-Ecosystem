<?php

use App\Http\Controllers\Api\V1\AnalyticsController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CoachingController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\GrandmasterController;
use App\Http\Controllers\Api\V1\LessonController;
use App\Http\Controllers\Api\V1\MatchController;
use App\Http\Controllers\Api\V1\OnboardingController;
use App\Http\Controllers\Api\V1\PuzzleController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| SparMate API Routes (v1)
|--------------------------------------------------------------------------
|
| All routes prefixed with /api/v1. Public routes handle authentication.
| Protected routes require a valid Sanctum token via the Authorization
| header: "Bearer {token}".
|
*/

Route::prefix('v1')->group(function () {

    // ── Public (No Auth Required) ─────────────────────────────────────
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login',    [AuthController::class, 'login']);

    // ── Protected (Sanctum Token Required) ────────────────────────────
    Route::middleware('auth:sanctum')->group(function () {

        // Auth
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/user',    [AuthController::class, 'user']);

        // Onboarding Survey
        Route::post('/onboarding', [OnboardingController::class, 'store']);

        // Dashboard (Home Screen aggregate)
        Route::get('/dashboard', [DashboardController::class, 'index']);

        // Lessons
        Route::get('/lessons',                     [LessonController::class, 'index']);
        Route::get('/lessons/{lesson}',            [LessonController::class, 'show']);
        Route::post('/lessons/{lesson}/progress',  [LessonController::class, 'updateProgress']);

        // Grandmasters
        Route::get('/grandmasters',               [GrandmasterController::class, 'index']);
        Route::get('/grandmasters/{grandmaster}',  [GrandmasterController::class, 'show']);

        // Sparring Matches
        Route::get('/matches',                  [MatchController::class, 'index']);
        Route::post('/matches',                 [MatchController::class, 'store']);
        Route::put('/matches/{match}',          [MatchController::class, 'update']);
        Route::post('/matches/{match}/analyze', [MatchController::class, 'analyze']);

        // Puzzles
        Route::get('/puzzles/daily',             [PuzzleController::class, 'daily']);
        Route::get('/puzzles/recent',            [PuzzleController::class, 'recent']);
        Route::post('/puzzles/{puzzle}/attempt',  [PuzzleController::class, 'attempt']);

        // Coaching Engine
        Route::get('/coaching/plan',     [CoachingController::class, 'plan']);
        Route::post('/coaching/refresh', [CoachingController::class, 'refresh']);

        // Analytics
        Route::get('/analytics/overview', [AnalyticsController::class, 'overview']);
    });
});
