<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('puzzle_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('puzzle_id')->constrained()->cascadeOnDelete();
            $table->boolean('solved')->default(false);
            $table->integer('time_seconds')->default(0);
            $table->timestamp('attempted_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('puzzle_attempts');
    }
};
