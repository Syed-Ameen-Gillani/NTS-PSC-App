import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      tertiary: AppColors.accent,
      background: AppColors.background,
      surface: AppColors.surface,
      onPrimary: AppColors.onPrimary,
      onBackground: AppColors.onBackground,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.onBackground),
      bodyMedium: TextStyle(color: AppColors.onSurface),
      labelLarge: TextStyle(color: AppColors.onPrimary),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: DarkAppColors.primary,
    scaffoldBackgroundColor: DarkAppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: DarkAppColors.primary,
      secondary: DarkAppColors.primaryVariant,
      tertiary: DarkAppColors.accent,
      background: DarkAppColors.background,
      surface: DarkAppColors.surface,
      onPrimary: DarkAppColors.onPrimary,
      onBackground: DarkAppColors.onBackground,
      onSurface: DarkAppColors.onSurface,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: DarkAppColors.onBackground),
      bodyMedium: TextStyle(color: DarkAppColors.onSurface),
      labelLarge: TextStyle(color: DarkAppColors.onPrimary),
    ),
  );
}
