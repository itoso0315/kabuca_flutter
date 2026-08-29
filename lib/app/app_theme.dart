import 'package:flutter/material.dart';

abstract final class AppColors {
  static const cream = Color(0xFFFFFBF2);
  static const surface = Color(0xFFFFFEFA);
  static const deepGreen = Color(0xFF174A3A);
  static const softGreen = Color(0xFFDCE9E1);
  static const textPrimary = Color(0xFF1D2823);
  static const textSecondary = Color(0xFF66736C);
  static const outline = Color(0xFFE3E6E1);
  static const gold = Color(0xFFC6A15B);
  static const packGreen = Color(0xFF103E31);
  static const packGreenLight = Color(0xFF286652);
  static const mutedGold = Color(0xFFD6B870);
}

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.deepGreen,
      onPrimary: Colors.white,
      primaryContainer: AppColors.softGreen,
      onPrimaryContainer: AppColors.deepGreen,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 17,
          height: 1.5,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.softGreen,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.deepGreen
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
