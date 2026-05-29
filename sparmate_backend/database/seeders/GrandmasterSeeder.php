<?php

namespace Database\Seeders;

use App\Models\Grandmaster;
use Illuminate\Database\Seeder;

class GrandmasterSeeder extends Seeder
{
    /**
     * Seed the 4 Grandmaster AI personas matching the Flutter app.
     */
    public function run(): void
    {
        $grandmasters = [
            [
                'name'              => 'Torre',
                'full_name'         => 'Eugene Torre',
                'title'             => 'GM',
                'era'               => '1970s – present',
                'nationality'       => '🇵🇭 Philippines',
                'style'             => 'Solid Attacker',
                'style_description' => "Asia's first Grandmaster plays a balanced style with sharp tactical awareness. Known for his solid preparation and ability to unleash devastating attacks from stable positions.",
                'quote'             => '"Patience is the key. Wait for the right moment, then strike."',
                'strengths'         => ['Positional Preparation', 'Tactical Strikes', 'Endgame Technique'],
                'openings'          => ["Queen's Indian Defense", 'Nimzo-Indian', 'Ruy Lopez'],
                'color_hex'         => '#1565C0',
                'icon'              => 'security',
                'elo_rating'        => 2540,
                'sort_order'        => 1,
            ],
            [
                'name'              => 'Tal',
                'full_name'         => 'Mikhail Tal',
                'title'             => 'GM',
                'era'               => '1950s – 1992',
                'nationality'       => '🇱🇻 Latvia',
                'style'             => 'Tactical Magician',
                'style_description' => 'The "Magician from Riga" — the most daring attacker in chess history. Sacrifices pieces with reckless abandon, creating impossibly complex positions that overwhelm opponents.',
                'quote'             => '"You must take your opponent into a deep, dark forest where 2+2=5."',
                'strengths'         => ['Sacrificial Attacks', 'Complex Combinations', 'Psychological Pressure'],
                'openings'          => ['Sicilian Najdorf', "King's Indian", 'Benoni Defense'],
                'color_hex'         => '#6A1B9A',
                'icon'              => 'local_fire_department',
                'elo_rating'        => 2700,
                'sort_order'        => 2,
            ],
            [
                'name'              => 'Petrosian',
                'full_name'         => 'Tigran Petrosian',
                'title'             => 'GM',
                'era'               => '1950s – 1984',
                'nationality'       => '🇦🇲 Armenia',
                'style'             => 'Prophylactic Master',
                'style_description' => '"Iron Tigran" — the ultimate defensive genius. Masters the art of prevention, neutralizing threats before they arise and slowly squeezing the life out of any position.',
                'quote'             => '"The best move is often the one that prevents your opponent\'s idea."',
                'strengths'         => ['Prophylaxis', 'Exchange Sacrifices', 'Positional Grinding'],
                'openings'          => ['French Defense', 'Caro-Kann', 'English Opening'],
                'color_hex'         => '#2E7D32',
                'icon'              => 'shield',
                'elo_rating'        => 2650,
                'sort_order'        => 3,
            ],
            [
                'name'              => 'Carlsen',
                'full_name'         => 'Magnus Carlsen',
                'title'             => 'GM',
                'era'               => '2004 – present',
                'nationality'       => '🇳🇴 Norway',
                'style'             => 'Universal Genius',
                'style_description' => 'The greatest player of the modern era plays every style with superhuman precision. Grinds opponents down with relentless accuracy, especially in endgames where he finds wins from nothing.',
                'quote'             => '"I don\'t look at computers as opponents. I look at them as tools."',
                'strengths'         => ['Endgame Mastery', 'Universal Style', 'Relentless Pressure'],
                'openings'          => ['Ruy Lopez', 'English Opening', 'Catalan'],
                'color_hex'         => '#00838F',
                'icon'              => 'star',
                'elo_rating'        => 2882,
                'sort_order'        => 4,
            ],
        ];

        foreach ($grandmasters as $gm) {
            Grandmaster::create($gm);
        }
    }
}
