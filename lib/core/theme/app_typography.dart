import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get hero => const TextStyle(
    fontFamily: 'DM Serif Display',
    fontSize: 40,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get h1 => const TextStyle(
    fontFamily: 'DM Serif Display',
    fontSize: 32,
    color: AppColors.textPrimary,
  );

  static TextStyle get h2 => const TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get h3 => const TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => const TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodySmall => const TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    color: AppColors.textMuted,
  );

  static TextStyle get label => const TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );
}
