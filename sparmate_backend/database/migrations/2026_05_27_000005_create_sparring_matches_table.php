<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sparring_matches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('grandmaster_id')->constrained()->cascadeOnDelete();
            $table->text('pgn')->nullable();       // Portable Game Notation of the full match
            $table->text('fen_final')->nullable();  // Final board position
            $table->string('result')->default('in_progress'); // win, loss, draw, in_progress
            $table->integer('move_count')->default(0);
            $table->integer('duration_seconds')->default(0);
            $table->float('pressure_avg')->nullable();  // Average pressure metric during game
            $table->json('analysis')->nullable();   // Classified blunders from ML pipeline
            $table->timestamp('played_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sparring_matches');
    }
};
