import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0066FF); // Electric Blue
  static const secondary = Color(0xFF00FF88); // Neon Green
  static const background = Color(0xFF0A0E27); // Deep Space
  static const card = Color(0xFF1A1F3A); // Dark Blue
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.grey;
}

final appTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: AppColors.background,
  cardColor: AppColors.card,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimary),
    bodyMedium: TextStyle(color: AppColors.textSecondary),
  ),
);
