import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const String _font = 'Outfit';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _font,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: _font,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _font,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 1.0,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnDark,
    letterSpacing: 0.3,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: AppColors.textMuted,
    letterSpacing: 1.2,
  );
}
