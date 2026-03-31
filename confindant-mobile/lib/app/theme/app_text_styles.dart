import 'package:confindant/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTextStyles {
  // Figma uses Gill Sans MT and Inter. Keep Gill Sans MT as preferred family.
  // If unavailable on target device/build, Flutter falls back to system sans.
  static const _displayFamily = 'Gill Sans MT';
  static const _bodyFamily = 'Inter';

  static const screenTitle = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 30,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 20,
    height: 1.35,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const label = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontFamily: _displayFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const caption = TextStyle(
    fontFamily: _bodyFamily,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );
}
