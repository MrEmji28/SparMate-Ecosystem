<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Puzzle extends Model
{
    protected $fillable = [
        'fen',
        'solution_moves',
        'category',
        'difficulty',
        'rating',
        'theme',
    ];

    protected function casts(): array
    {
        return [
            'solution_moves' => 'array',
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function attempts(): HasMany
    {
        return $this->hasMany(PuzzleAttempt::class);
    }
}
