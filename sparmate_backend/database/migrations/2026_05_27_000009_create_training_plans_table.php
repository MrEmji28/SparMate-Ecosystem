<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('training_plans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->text('primary_directive');  // Main coaching instruction
            $table->json('weekly_focus');        // Skills to focus on this week
            /*
             * Example: ["Endgame Fundamentals", "Pawn Structure"]
             */
            $table->json('plan_items');          // Structured training schedule
            /*
             * Example:
             * [
             *   {"day": "Monday",    "activity": "Rook Endgame Drill",  "duration_min": 20, "type": "lesson"},
             *   {"day": "Tuesday",   "activity": "Tactical Puzzles",    "duration_min": 15, "type": "puzzle"},
             *   {"day": "Wednesday", "activity": "Spar vs Petrosian",   "duration_min": 30, "type": "sparring"}
             * ]
             */
            $table->timestamp('generated_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('training_plans');
    }
};
