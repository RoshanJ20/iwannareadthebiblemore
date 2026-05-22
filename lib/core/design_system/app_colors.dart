import 'package:flutter/material.dart';

abstract class AppColors {
  // Backgrounds — warm charcoal, like a candlelit room at night
  static const Color background = Color(0xFF0E0B08);
  static const Color surface = Color(0xFF1A1610);
  static const Color surfaceElevated = Color(0xFF272118);

  // Brand — warm amber (candlelight glow)
  static const Color primary = Color(0xFFE8940A);
  static const Color primaryVariant = Color(0xFFB67008);

  // Gamification tiers
  static const Color streakOrange = Color(0xFFF07030);
  static const Color streakRed = Color(0xFFD04040);
  static const Color streakGold = Color(0xFFDDB830);
  static const Color streakDiamond = Color(0xFF60C8E0);
  static const Color success = Color(0xFF5A9E70);
  static const Color error = Color(0xFFC84040);

  // Text — warm parchment tones
  static const Color textPrimary = Color(0xFFF0E8D8);
  static const Color textSecondary = Color(0xFFB0986A);
  static const Color textMuted = Color(0xFF6A5438);

  // XP economy — same hue as streakGold; update independently if XP branding diverges
  static const Color xpGold = streakGold;
}
