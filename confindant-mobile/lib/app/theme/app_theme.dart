import 'package:confindant/app/theme/app_colors.dart';
import 'package:confindant/app/theme/app_radius.dart';
import 'package:confindant/app/theme/app_shadows.dart';
import 'package:confindant/app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentAction,
      brightness: Brightness.light,
      primary: AppColors.accentAction,
      surface: AppColors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      cardColor: AppColors.card,
      dividerColor: AppColors.divider,
      textTheme: const TextTheme(
        headlineLarge: AppTextStyles.screenTitle,
        titleLarge: AppTextStyles.sectionTitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.label,
        bodySmall: AppTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionTitle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
        labelStyle: AppTextStyles.label,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(
            color: AppColors.accentAction,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.white,
          backgroundColor: AppColors.accentAction,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accentAction,
          textStyle: AppTextStyles.button,
          side: const BorderSide(color: AppColors.accentAction),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentAction,
          textStyle: AppTextStyles.button,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[AppDecorationTheme()],
    );
  }
}

class AppDecorationTheme extends ThemeExtension<AppDecorationTheme> {
  const AppDecorationTheme({
    this.cardShadow = AppShadows.card,
    this.softShadow = AppShadows.soft,
    this.elevatedCardShadow = AppShadows.elevatedCard,
  });

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> softShadow;
  final List<BoxShadow> elevatedCardShadow;

  @override
  ThemeExtension<AppDecorationTheme> copyWith({
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? softShadow,
    List<BoxShadow>? elevatedCardShadow,
  }) {
    return AppDecorationTheme(
      cardShadow: cardShadow ?? this.cardShadow,
      softShadow: softShadow ?? this.softShadow,
      elevatedCardShadow: elevatedCardShadow ?? this.elevatedCardShadow,
    );
  }

  @override
  ThemeExtension<AppDecorationTheme> lerp(
    covariant ThemeExtension<AppDecorationTheme>? other,
    double t,
  ) {
    if (other is! AppDecorationTheme) return this;
    return t < 0.5 ? this : other;
  }
}
