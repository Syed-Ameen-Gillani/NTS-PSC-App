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
      surface: AppColors.surface,
      onPrimary: AppColors.onPrimary,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.onBackground),
      bodyMedium: TextStyle(color: AppColors.onSurface),
      labelLarge: TextStyle(color: AppColors.onPrimary),
    ),
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      elevation: 0,
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
      surface: DarkAppColors.surface,
      onPrimary: DarkAppColors.onPrimary,
      onSurface: DarkAppColors.onSurface,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: DarkAppColors.onBackground),
      bodyMedium: TextStyle(color: DarkAppColors.onSurface),
      labelLarge: TextStyle(color: DarkAppColors.onPrimary),
    ),
    appBarTheme: const AppBarTheme(
      scrolledUnderElevation: 0,
      backgroundColor: DarkAppColors.background,
      elevation: 0,
    ),
  );
}