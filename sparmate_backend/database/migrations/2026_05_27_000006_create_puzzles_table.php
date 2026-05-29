<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('puzzles', function (Blueprint $table) {
            $table->id();
            $table->string('fen');               // Starting position
            $table->json('solution_moves');       // ["e4", "Nf3", ...] correct move sequence
            $table->string('category');           // Tactics, Endgame, etc.
            $table->string('difficulty')->default('intermediate');
            $table->integer('rating')->default(1500);
            $table->string('theme')->nullable();  // Fork, Pin, Skewer, Mate-in-2, etc.
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('puzzles');
    }
};
