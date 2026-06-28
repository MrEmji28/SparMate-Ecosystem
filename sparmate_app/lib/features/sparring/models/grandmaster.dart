import 'package:flutter/material.dart';

/// Data model representing a Grandmaster AI persona.
class Grandmaster {
  final String name;
  final String fullName;
  final String title;
  final String era;
  final String nationality;
  final String style;
  final String styleDescription;
  final String quote;
  final List<String> strengths;
  final List<String> openings;
  final Color color;
  final IconData icon;
  final String imagePath;
  final int eloRating;

  const Grandmaster({
    required this.name,
    required this.fullName,
    required this.title,
    required this.era,
    required this.nationality,
    required this.style,
    required this.styleDescription,
    required this.quote,
    required this.strengths,
    required this.openings,
    required this.color,
    required this.icon,
    required this.imagePath,
    required this.eloRating,
  });

  static const torre = Grandmaster(
    name: 'Torre',
    fullName: 'Eugene Torre',
    title: 'GM',
    era: '1970s – present',
    nationality: '🇵🇭 Philippines',
    style: 'Solid Attacker',
    styleDescription:
        'Asia\'s first Grandmaster plays a balanced style with sharp tactical awareness. '
        'Known for his solid preparation and ability to unleash devastating attacks from stable positions.',
    quote: '"Patience is the key. Wait for the right moment, then strike."',
    strengths: ['Positional Preparation', 'Tactical Strikes', 'Endgame Technique'],
    openings: ['Queen\'s Indian Defense', 'Nimzo-Indian', 'Ruy Lopez'],
    color: Color(0xFF1565C0),
    icon: Icons.security,
    imagePath: 'assets/grandmasters/torre.jpeg',
    eloRating: 2540,
  );

  static const tal = Grandmaster(
    name: 'Tal',
    fullName: 'Mikhail Tal',
    title: 'GM',
    era: '1950s – 1992',
    nationality: '🇱🇻 Latvia',
    style: 'Tactical Magician',
    styleDescription:
        'The "Magician from Riga" — the most daring attacker in chess history. '
        'Sacrifices pieces with reckless abandon, creating impossibly complex positions that overwhelm opponents.',
    quote: '"You must take your opponent into a deep, dark forest where 2+2=5."',
    strengths: ['Sacrificial Attacks', 'Complex Combinations', 'Psychological Pressure'],
    openings: ['Sicilian Najdorf', 'King\'s Indian', 'Benoni Defense'],
    color: Color(0xFF6A1B9A),
    icon: Icons.local_fire_department,
    imagePath: 'assets/grandmasters/tal.jpeg',
    eloRating: 2700,
  );

  static const petrosian = Grandmaster(
    name: 'Petrosian',
    fullName: 'Tigran Petrosian',
    title: 'GM',
    era: '1950s – 1984',
    nationality: '🇦🇲 Armenia',
    style: 'Prophylactic Master',
    styleDescription:
        '"Iron Tigran" — the ultimate defensive genius. '
        'Masters the art of prevention, neutralizing threats before they arise and slowly squeezing the life out of any position.',
    quote: '"The best move is often the one that prevents your opponent\'s idea."',
    strengths: ['Prophylaxis', 'Exchange Sacrifices', 'Positional Grinding'],
    openings: ['French Defense', 'Caro-Kann', 'English Opening'],
    color: Color(0xFF2E7D32),
    icon: Icons.shield,
    imagePath: 'assets/grandmasters/petrosian.webp',
    eloRating: 2650,
  );

  static const carlsen = Grandmaster(
    name: 'Carlsen',
    fullName: 'Magnus Carlsen',
    title: 'GM',
    era: '2004 – present',
    nationality: '🇳🇴 Norway',
    style: 'Universal Genius',
    styleDescription:
        'The greatest player of the modern era plays every style with superhuman precision. '
        'Grinds opponents down with relentless accuracy, especially in endgames where he finds wins from nothing.',
    quote: '"I don\'t look at computers as opponents. I look at them as tools."',
    strengths: ['Endgame Mastery', 'Universal Style', 'Relentless Pressure'],
    openings: ['Ruy Lopez', 'English Opening', 'Catalan'],
    color: Color(0xFF00838F),
    icon: Icons.star,
    imagePath: 'assets/grandmasters/magnus.jpeg',
    eloRating: 2882,
  );

  static const all = [torre, tal, petrosian, carlsen];
}
