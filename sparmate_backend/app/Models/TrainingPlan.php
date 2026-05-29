<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TrainingPlan extends Model
{
    protected $fillable = [
        'user_id',
        'primary_directive',
        'weekly_focus',
        'plan_items',
        'generated_at',
    ];

    protected function casts(): array
    {
        return [
            'weekly_focus'  => 'array',
            'plan_items'    => 'array',
            'generated_at'  => 'datetime',
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
