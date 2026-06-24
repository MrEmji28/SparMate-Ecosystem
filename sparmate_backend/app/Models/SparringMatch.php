<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SparringMatch extends Model
{
    protected $table = 'sparring_matches';

    protected $fillable = [
        'user_id',
        'grandmaster_id',
        'pgn',
        'fen_final',
        'result',
        'move_count',
        'duration_seconds',
        'pressure_avg',
        'analysis',
        'classified_blunders',
        'played_at',
    ];

    protected function casts(): array
    {
        return [
            'analysis'             => 'array',
            'classified_blunders'  => 'array',
            'pressure_avg'        => 'float',
            'played_at'           => 'datetime',
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function grandmaster(): BelongsTo
    {
        return $this->belongsTo(Grandmaster::class);
    }
}
