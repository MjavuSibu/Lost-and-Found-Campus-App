import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color cutBlue      = Color(0xFF003087);
  static const Color cutBlueMid   = Color(0xFF1A4DA8);
  static const Color cutBlueLight = Color(0xFF2563EB);
  static const Color cutGold      = Color(0xFFC8A951);
  static const Color cutGoldLight = Color(0xFFF0D98A);
  static const Color cutGoldDark  = Color(0xFFA8892F);

  static const Color lostRed      = Color(0xFFE5394B);
  static const Color lostRedBg    = Color(0xFFFEECEE);
  static const Color foundGreen   = Color(0xFF1AA96A);
  static const Color foundGreenBg = Color(0xFFE8F8F1);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningBg    = Color(0xFFFFF8E6);

  static const Color background = Color(0xFFF0F4FA);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surface2   = Color(0xFFF7F9FC);
  static const Color surface3   = Color(0xFFEEF2F8);

  static const Color textPrimary   = Color(0xFF0D1B3E);
  static const Color textSecondary = Color(0xFF5A6A8A);
  static const Color textMuted     = Color(0xFF9AAAC0);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFDDE5F0);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cutBlueLight, cutBlue],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cutBlue, cutBlueMid],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cutGold, cutGoldDark],
  );
}