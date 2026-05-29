<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserBktMatrix extends Model
{
    protected $table = 'user_bkt_matrices';

    protected $fillable = [
        'user_id',
        'matrix',
    ];

    protected function casts(): array
    {
        return [
            'matrix' => 'array',
        ];
    }

    /**
     * Default BKT matrix for new users — all skills start at 0.5 (unknown).
     */
    public static function defaultMatrix(): array
    {
        return [
            'tactical_oversight'   => 0.50,
            'positional_error'     => 0.50,
            'endgame_fundamentals' => 0.50,
            'opening_theory'       => 0.50,
            'king_safety'          => 0.50,
            'pawn_structure'       => 0.50,
            'piece_coordination'   => 0.50,
            'time_management'      => 0.50,
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
