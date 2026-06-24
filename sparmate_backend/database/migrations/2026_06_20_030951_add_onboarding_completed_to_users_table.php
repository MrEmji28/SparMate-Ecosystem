<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Add onboarding fields: skill_level and onboarding_completed flag.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('onboarding_completed')->default(false)->after('streak_days');
            $table->string('skill_level')->nullable()->after('onboarding_completed'); // beginner, intermediate, advanced
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['onboarding_completed', 'skill_level']);
        });
    }
};
