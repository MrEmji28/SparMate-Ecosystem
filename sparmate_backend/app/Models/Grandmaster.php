<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Grandmaster extends Model
{
    protected $fillable = [
        'name',
        'full_name',
        'title',
        'era',
        'nationality',
        'style',
        'style_description',
        'quote',
        'strengths',
        'openings',
        'color_hex',
        'icon',
        'elo_rating',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'strengths' => 'array',
            'openings'  => 'array',
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function matches(): HasMany
    {
        return $this->hasMany(SparringMatch::class);
    }
}
