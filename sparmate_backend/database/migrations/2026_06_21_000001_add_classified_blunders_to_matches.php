<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Add classified_blunders JSON column to sparring_matches.
     *
     * Stores the ML classifier output (category, severity, confidence, etc.)
     * separately from raw move analysis data, enabling the coaching engine
     * to generate indicators from past match blunders.
     */
    public function up(): void
    {
        Schema::table('sparring_matches', function (Blueprint $table) {
            $table->json('classified_blunders')->nullable()->after('analysis');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sparring_matches', function (Blueprint $table) {
            $table->dropColumn('classified_blunders');
        });
    }
};
