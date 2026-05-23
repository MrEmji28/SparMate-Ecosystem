import 'package:flutter/material.dart';

/// SparMate color palette — derived from the home screen design.
class AppColors {
  AppColors._();

  // ── Primary Blues ──────────────────────────────────────────────────────────
  static const Color primaryNavy = Color(0xFF1B2063);
  static const Color primaryBlue = Color(0xFF2A3BB7);
  static const Color primaryMedium = Color(0xFF3949AB);
  static const Color primaryLight = Color(0xFF5C6BC0);
  static const Color accentBlue = Color(0xFF3D5AFE);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2063), Color(0xFF2E3FA8), Color(0xFF3D54D9)],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D5AFE), Color(0xFF536DFE)],
  );

  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFFF0F2F8);
  static const Color cardBg = Colors.white;
  static const Color cardBgSubtle = Color(0xFFF7F8FC);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textDark = Color(0xFF1A1D3B);
  static const Color textMedium = Color(0xFF5A5F7D);
  static const Color textLight = Color(0xFF9EA3BE);
  static const Color textOnPrimary = Colors.white;

  // ── Accents ────────────────────────────────────────────────────────────────
  static const Color liveRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF43A047);
  static const Color insightsGreen = Color(0xFF00C853);
  static const Color ratingUp = Color(0xFF2196F3);
  static const Color starFilled = Color(0xFFFFB300);
  static const Color starEmpty = Color(0xFFD5D8E8);

  // ── Chips ──────────────────────────────────────────────────────────────────
  static const Color chipBlueBg = Color(0xFF283593);
  static const Color chipBlueText = Colors.white;

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  static const Color navActive = primaryBlue;
  static const Color navInactive = Color(0xFFB0B4CC);

  // ── Borders & Dividers ─────────────────────────────────────────────────────
  static const Color border = Color(0xFFE4E7F2);
  static const Color divider = Color(0xFFECEFF5);

  // ── Progress ───────────────────────────────────────────────────────────────
  static const Color progressTrack = Color(0xFFE0E3F0);
  static const Color progressFill = primaryBlue;
}
