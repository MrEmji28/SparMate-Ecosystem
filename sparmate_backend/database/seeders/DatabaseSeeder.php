<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     *
     * Order matters: Grandmasters and Lessons must be seeded before
     * the DemoUser, which references them for match history and progress.
     */
    public function run(): void
    {
        $this->call([
            GrandmasterSeeder::class,
            LessonSeeder::class,
            PuzzleSeeder::class,
            DemoUserSeeder::class,
        ]);
    }
}
