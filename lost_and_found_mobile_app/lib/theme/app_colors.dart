import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color cutSage      = Color(0xFF4A7C59);
  static const Color cutSageMid   = Color(0xFF5D8A6A);
  static const Color cutSageLight = Color(0xFF7BA68A);
  static const Color cutSagePale  = Color(0xFFEAF2EC);
  static const Color cutSageDark  = Color(0xFF345440);

  static const Color cutGold      = Color(0xFFC8A951);
  static const Color cutGoldLight = Color(0xFFF0D98A);
  static const Color cutGoldDark  = Color(0xFFA8892F);

  static const Color lostRed      = Color(0xFFD94F4F);
  static const Color lostRedBg    = Color(0xFFFCEEEE);
  static const Color foundGreen   = Color(0xFF3A9E6F);
  static const Color foundGreenBg = Color(0xFFE8F5EF);
  static const Color warning      = Color(0xFFE8A838);
  static const Color warningBg    = Color(0xFFFFF6E6);

  static const Color background = Color(0xFFF4F7F5);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surface2   = Color(0xFFF7FAF8);
  static const Color surface3   = Color(0xFFEDF3EF);

  static const Color textPrimary   = Color(0xFF1A2E22);
  static const Color textSecondary = Color(0xFF4E6B57);
  static const Color textMuted     = Color(0xFF8FAD98);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFD4E2D8);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cutSageLight, cutSage],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cutSage, cutSageDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cutGold, cutGoldDark],
  );
}
