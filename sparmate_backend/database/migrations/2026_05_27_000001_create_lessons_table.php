<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lessons', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('slug')->unique();
            $table->string('category'); // Opening, Middlegame, Endgame, Tactics, Strategy
            $table->text('description')->nullable();
            $table->string('icon')->default('book');
            $table->string('color_hex')->default('#3949AB');
            $table->integer('chapter_count')->default(0);
            $table->string('difficulty')->default('intermediate'); // beginner, intermediate, advanced
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lessons');
    }
};
