<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'elo_rating', 'avatar_url', 'streak_days'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function lessonProgress(): HasMany
    {
        return $this->hasMany(UserLessonProgress::class);
    }

    public function matches(): HasMany
    {
        return $this->hasMany(SparringMatch::class);
    }

    public function puzzleAttempts(): HasMany
    {
        return $this->hasMany(PuzzleAttempt::class);
    }

    public function bktMatrix(): HasOne
    {
        return $this->hasOne(UserBktMatrix::class);
    }

    public function trainingPlan(): HasOne
    {
        return $this->hasOne(TrainingPlan::class)->latestOfMany();
    }

    public function trainingPlans(): HasMany
    {
        return $this->hasMany(TrainingPlan::class);
    }
}
