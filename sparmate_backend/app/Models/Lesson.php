<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Lesson extends Model
{
    protected $fillable = [
        'title',
        'slug',
        'category',
        'description',
        'icon',
        'color_hex',
        'chapter_count',
        'difficulty',
        'sort_order',
    ];

    // ── Relationships ──────────────────────────────────────────────────

    public function chapters(): HasMany
    {
        return $this->hasMany(Chapter::class)->orderBy('sort_order');
    }

    public function userProgress(): HasMany
    {
        return $this->hasMany(UserLessonProgress::class);
    }
}
