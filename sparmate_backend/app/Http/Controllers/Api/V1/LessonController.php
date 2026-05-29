<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Lesson;
use App\Models\UserLessonProgress;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LessonController extends Controller
{
    /**
     * List all lessons with the authenticated user's progress.
     * Supports optional category filtering.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Lesson::with('chapters:id,lesson_id,title,sort_order')
            ->orderBy('sort_order');

        // Optional category filter (matches the filter chips in LessonsScreen)
        if ($request->has('category') && $request->category !== 'All') {
            $query->where('category', $request->category);
        }

        $lessons = $query->get()->map(function (Lesson $lesson) use ($user) {
            $progress = $user->lessonProgress()
                ->where('lesson_id', $lesson->id)
                ->first();

            return [
                'id'            => $lesson->id,
                'title'         => $lesson->title,
                'slug'          => $lesson->slug,
                'category'      => $lesson->category,
                'description'   => $lesson->description,
                'icon'          => $lesson->icon,
                'color_hex'     => $lesson->color_hex,
                'chapter_count' => $lesson->chapter_count,
                'difficulty'    => $lesson->difficulty,
                'chapters'      => $lesson->chapters->map(fn ($ch) => [
                    'id'    => $ch->id,
                    'title' => $ch->title,
                ]),
                'progress'      => $progress?->progress ?? 0.0,
                'started'       => $progress !== null,
            ];
        });

        // Split into categories for the Flutter UI
        $active = $lessons->filter(fn ($l) => $l['progress'] > 0 && $l['progress'] < 1.0);
        $recommended = $lessons->filter(fn ($l) => $l['progress'] === 0.0)->take(3);

        return response()->json([
            'lessons'     => $lessons->values(),
            'active'      => $active->values(),
            'recommended' => $recommended->values(),
            'categories'  => ['All', 'Opening', 'Middlegame', 'Endgame', 'Tactics', 'Strategy'],
        ]);
    }

    /**
     * Show a single lesson with full chapter content.
     */
    public function show(Request $request, Lesson $lesson): JsonResponse
    {
        $user = $request->user();
        $lesson->load('chapters');

        $progress = $user->lessonProgress()
            ->where('lesson_id', $lesson->id)
            ->first();

        return response()->json([
            'lesson' => [
                'id'            => $lesson->id,
                'title'         => $lesson->title,
                'slug'          => $lesson->slug,
                'category'      => $lesson->category,
                'description'   => $lesson->description,
                'icon'          => $lesson->icon,
                'color_hex'     => $lesson->color_hex,
                'chapter_count' => $lesson->chapter_count,
                'difficulty'    => $lesson->difficulty,
                'chapters'      => $lesson->chapters->map(fn ($ch) => [
                    'id'         => $ch->id,
                    'title'      => $ch->title,
                    'sort_order' => $ch->sort_order,
                    'content'    => $ch->content,
                ]),
            ],
            'progress' => [
                'current_chapter_id' => $progress?->current_chapter_id,
                'progress'           => $progress?->progress ?? 0.0,
                'started_at'         => $progress?->started_at?->toISOString(),
                'completed_at'       => $progress?->completed_at?->toISOString(),
            ],
        ]);
    }

    /**
     * Update the user's progress on a lesson.
     */
    public function updateProgress(Request $request, Lesson $lesson): JsonResponse
    {
        $validated = $request->validate([
            'current_chapter_id' => 'nullable|exists:chapters,id',
            'progress'           => 'required|numeric|min:0|max:1',
        ]);

        $progress = UserLessonProgress::updateOrCreate(
            [
                'user_id'  => $request->user()->id,
                'lesson_id' => $lesson->id,
            ],
            [
                'current_chapter_id' => $validated['current_chapter_id'] ?? null,
                'progress'           => $validated['progress'],
                'started_at'         => now(),
                'completed_at'       => $validated['progress'] >= 1.0 ? now() : null,
            ],
        );

        return response()->json([
            'message'  => 'Progress updated.',
            'progress' => $progress,
        ]);
    }
}
