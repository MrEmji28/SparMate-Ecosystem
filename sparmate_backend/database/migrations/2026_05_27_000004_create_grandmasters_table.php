<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('grandmasters', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('full_name');
            $table->string('title')->default('GM');
            $table->string('era');
            $table->string('nationality');
            $table->string('style');
            $table->text('style_description');
            $table->text('quote');
            $table->json('strengths');   // ["Positional Preparation", "Tactical Strikes", ...]
            $table->json('openings');    // ["Queen's Indian Defense", "Nimzo-Indian", ...]
            $table->string('color_hex');
            $table->string('icon');
            $table->integer('elo_rating');
            $table->integer('sort_order')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('grandmasters');
    }
};
