<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Chapter extends Model
{
    protected $fillable = [
        'lesson_id',
        'title',
        'sort_order',
        'content',
    ];

    protected function casts(): array
    {
        return [
            'content' => 'array',
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }
}
