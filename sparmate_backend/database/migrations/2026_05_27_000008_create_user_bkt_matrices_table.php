<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_bkt_matrices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->json('matrix'); // BKT probabilities per cognitive skill
            /*
             * Example matrix structure:
             * {
             *   "tactical_oversight":    0.45,
             *   "positional_error":      0.62,
             *   "endgame_fundamentals":  0.78,
             *   "opening_theory":        0.55,
             *   "king_safety":           0.40,
             *   "pawn_structure":        0.58,
             *   "piece_coordination":    0.50,
             *   "time_management":       0.35
             * }
             */
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_bkt_matrices');
    }
};
