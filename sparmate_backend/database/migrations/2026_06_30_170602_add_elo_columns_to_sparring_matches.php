<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Add ELO tracking columns to sparring_matches.
 *
 * elo_before  – the player's rating at the start of the match
 * elo_after   – the player's rating after the match
 * elo_change  – the signed delta (positive = gained, negative = lost)
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sparring_matches', function (Blueprint $table) {
            $table->integer('elo_before')->nullable()->after('pressure_avg');
            $table->integer('elo_after')->nullable()->after('elo_before');
            $table->integer('elo_change')->nullable()->after('elo_after');
        });
    }

    public function down(): void
    {
        Schema::table('sparring_matches', function (Blueprint $table) {
            $table->dropColumn(['elo_before', 'elo_after', 'elo_change']);
        });
    }
};
