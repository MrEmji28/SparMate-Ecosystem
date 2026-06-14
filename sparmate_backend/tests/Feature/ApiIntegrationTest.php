<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserBktMatrix;
use App\Models\Grandmaster;
use App\Models\Lesson;
use App\Models\Puzzle;
use App\Models\SparringMatch;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Sprint 7 — API Integration Tests
 *
 * Tests all Laravel API endpoints for correct HTTP responses,
 * authentication enforcement, data integrity, and business logic.
 *
 * Usage:
 *   cd sparmate_backend
 *   php artisan test --filter=ApiIntegrationTest
 */
class ApiIntegrationTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();

        // Create a test user with Sanctum token
        $this->user = User::factory()->create([
            'name'       => 'Test Player',
            'email'      => 'test@sparmate.dev',
            'password'   => bcrypt('password123'),
            'elo_rating' => 1350,
        ]);

        // Create BKT matrix for the user
        UserBktMatrix::create([
            'user_id' => $this->user->id,
            'matrix'  => [
                'tactical_oversight'    => 0.50,
                'positional_error'      => 0.50,
                'endgame_fundamentals'  => 0.50,
                'opening_theory'        => 0.50,
                'king_safety'           => 0.50,
                'pawn_structure'        => 0.50,
                'piece_coordination'    => 0.50,
                'time_management'       => 0.50,
            ],
        ]);

        $this->token = $this->user->createToken('test-token')->plainTextToken;
    }

    // ── Authentication Tests ────────────────────────────────────────────

    public function test_register_creates_user_and_bkt_matrix(): void
    {
        $response = $this->postJson('/api/v1/register', [
            'name'                  => 'New User',
            'email'                 => 'newuser@sparmate.dev',
            'password'              => 'securepassword',
            'password_confirmation' => 'securepassword',
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure([
            'user' => ['id', 'name', 'email'],
            'token',
        ]);

        // Verify BKT matrix was auto-created
        $userId = $response->json('user.id');
        $this->assertDatabaseHas('user_bkt_matrices', [
            'user_id' => $userId,
        ]);
    }

    public function test_login_returns_token(): void
    {
        $response = $this->postJson('/api/v1/login', [
            'email'    => 'test@sparmate.dev',
            'password' => 'password123',
        ]);

        $response->assertStatus(200);
        $response->assertJsonStructure(['user', 'token']);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        $response = $this->postJson('/api/v1/login', [
            'email'    => 'test@sparmate.dev',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401);
    }

    public function test_protected_routes_require_auth(): void
    {
        $response = $this->getJson('/api/v1/dashboard');
        $response->assertStatus(401);

        $response = $this->getJson('/api/v1/matches');
        $response->assertStatus(401);

        $response = $this->getJson('/api/v1/coaching/plan');
        $response->assertStatus(401);
    }

    public function test_user_profile_returns_authenticated_user(): void
    {
        $response = $this->withToken($this->token)
            ->getJson('/api/v1/user');

        $response->assertStatus(200);
        $response->assertJson([
            'id'    => $this->user->id,
            'email' => 'test@sparmate.dev',
        ]);
    }

    // ── Dashboard Tests ─────────────────────────────────────────────────

    public function test_dashboard_returns_aggregated_data(): void
    {
        $response = $this->withToken($this->token)
            ->getJson('/api/v1/dashboard');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'user',
        ]);
    }

    // ── Grandmaster Tests ───────────────────────────────────────────────

    public function test_grandmasters_index(): void
    {
        Grandmaster::create([
            'name'              => 'Tal',
            'full_name'         => 'Mikhail Tal',
            'title'             => 'World Champion',
            'era'               => '1960s',
            'nationality'       => 'Latvian',
            'style'             => 'Tactical',
            'style_description' => 'Aggressive and sacrificial',
            'quote'             => 'You must take your opponent into a deep dark forest...',
            'strengths'         => ['Sacrifices', 'Combinations'],
            'openings'          => ['Sicilian Defense', 'Kings Indian'],
            'color_hex'         => '#E53935',
            'icon'              => 'fire',
            'elo_rating'        => 2700,
            'sort_order'        => 1,
        ]);

        $response = $this->withToken($this->token)
            ->getJson('/api/v1/grandmasters');

        $response->assertStatus(200);
        $response->assertJsonCount(1);
        $response->assertJsonFragment(['name' => 'Tal']);
    }

    // ── Match Lifecycle Tests ───────────────────────────────────────────

    public function test_create_match(): void
    {
        $gm = Grandmaster::create([
            'name'              => 'Fischer',
            'full_name'         => 'Bobby Fischer',
            'title'             => 'World Champion',
            'era'               => '1970s',
            'nationality'       => 'American',
            'style'             => 'Generalist',
            'style_description' => 'Universal and precise',
            'quote'             => 'Chess demands total concentration.',
            'strengths'         => ['Precision', 'Endgame'],
            'openings'          => ['Ruy Lopez', 'Sicilian Defense'],
            'color_hex'         => '#1E88E5',
            'icon'              => 'star',
            'elo_rating'        => 2785,
            'sort_order'        => 3,
        ]);

        $response = $this->withToken($this->token)
            ->postJson('/api/v1/matches', [
                'grandmaster_id' => $gm->id,
                'color'          => 'white',
            ]);

        $response->assertStatus(201);
        $response->assertJsonFragment(['result' => 'in_progress']);
    }

    public function test_update_match_with_pgn(): void
    {
        $gm = Grandmaster::create([
            'name' => 'Petrosian', 'full_name' => 'Tigran Petrosian',
            'title' => 'World Champion', 'era' => '1960s',
            'nationality' => 'Armenian', 'style' => 'Positional',
            'style_description' => 'Prophylactic', 'quote' => 'Defense wins.',
            'strengths' => ['Defense'], 'openings' => ['Queens Indian'],
            'color_hex' => '#43A047', 'icon' => 'shield',
            'elo_rating' => 2650, 'sort_order' => 2,
        ]);

        $match = SparringMatch::create([
            'user_id'        => $this->user->id,
            'grandmaster_id' => $gm->id,
            'result'         => 'in_progress',
            'color'          => 'white',
        ]);

        $response = $this->withToken($this->token)
            ->putJson("/api/v1/matches/{$match->id}", [
                'pgn'        => '1. e4 e5 2. Nf3 Nc6 3. Bb5 a6',
                'final_fen'  => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR',
                'result'     => 'win',
                'move_count' => 30,
                'duration'   => 600,
            ]);

        $response->assertStatus(200);
        $response->assertJsonFragment(['result' => 'win']);
    }

    public function test_cannot_update_other_users_match(): void
    {
        $otherUser = User::factory()->create();
        $gm = Grandmaster::create([
            'name' => 'Tal', 'full_name' => 'Mikhail Tal',
            'title' => 'WC', 'era' => '60s', 'nationality' => 'LV',
            'style' => 'Tactical', 'style_description' => 'Aggressive',
            'quote' => 'Quote', 'strengths' => [], 'openings' => [],
            'color_hex' => '#E53935', 'icon' => 'fire',
            'elo_rating' => 2700, 'sort_order' => 1,
        ]);

        $match = SparringMatch::create([
            'user_id'        => $otherUser->id,
            'grandmaster_id' => $gm->id,
            'result'         => 'in_progress',
            'color'          => 'white',
        ]);

        $response = $this->withToken($this->token)
            ->putJson("/api/v1/matches/{$match->id}", [
                'result' => 'win',
            ]);

        $response->assertStatus(403);
    }

    // ── Lesson Tests ────────────────────────────────────────────────────

    public function test_lessons_index(): void
    {
        Lesson::create([
            'title'         => 'Opening Principles',
            'description'   => 'Learn the basics of opening play.',
            'category'      => 'Opening',
            'difficulty'    => 'Beginner',
            'chapter_count' => 5,
            'color_hex'     => '#FF9800',
            'icon'          => 'book',
        ]);

        $response = $this->withToken($this->token)
            ->getJson('/api/v1/lessons');

        $response->assertStatus(200);
        $response->assertJsonFragment(['title' => 'Opening Principles']);
    }

    // ── Coaching Tests ──────────────────────────────────────────────────

    public function test_coaching_plan_returns_bkt_data(): void
    {
        $response = $this->withToken($this->token)
            ->getJson('/api/v1/coaching/plan');

        $response->assertStatus(200);
    }

    // ── Analytics Tests ─────────────────────────────────────────────────

    public function test_analytics_overview(): void
    {
        $response = $this->withToken($this->token)
            ->getJson('/api/v1/analytics/overview');

        $response->assertStatus(200);
    }

    // ── Puzzle Tests ────────────────────────────────────────────────────

    public function test_daily_puzzles(): void
    {
        Puzzle::create([
            'fen'           => 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
            'solution_moves' => ['e4', 'Nf3'],
            'category'      => 'Tactics',
            'difficulty'    => 'Intermediate',
            'rating'        => 1400,
            'theme'         => 'Fork',
            'solution_text' => 'Find the fork with Nf3.',
        ]);

        $response = $this->withToken($this->token)
            ->getJson('/api/v1/puzzles/daily');

        $response->assertStatus(200);
    }
}
