<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PuzzleAttempt extends Model
{
    protected $fillable = [
        'user_id',
        'puzzle_id',
        'solved',
        'time_seconds',
        'attempted_at',
    ];

    protected function casts(): array
    {
        return [
            'solved'       => 'boolean',
            'attempted_at' => 'datetime',
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function puzzle(): BelongsTo
    {
        return $this->belongsTo(Puzzle::class);
    }
}
