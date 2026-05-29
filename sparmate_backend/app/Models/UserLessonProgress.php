<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserLessonProgress extends Model
{
    protected $table = 'user_lesson_progress';

    protected $fillable = [
        'user_id',
        'lesson_id',
        'current_chapter_id',
        'progress',
        'started_at',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'progress'     => 'float',
            'started_at'   => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    // ── Relationships ──────────────────────────────────────────────────

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function lesson(): BelongsTo
    {
        return $this->belongsTo(Lesson::class);
    }

    public function currentChapter(): BelongsTo
    {
        return $this->belongsTo(Chapter::class, 'current_chapter_id');
    }
}
