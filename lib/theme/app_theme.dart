import 'package:flutter/material.dart';

/// Brand palette: grayish-black surfaces with white as the accent.
/// Green and red are reserved for "worth it" / "not worth it".
abstract final class AppColors {
  static const background = Color(0xFF121212); // same as the logo PNG
  static const surface = Color(0xFF1C1D1F);
  static const surfaceHigh = Color(0xFF26282B);
  static const border = Color(0xFF34373B);

  static const accent = Color(0xFFFFFFFF);
  static const accentDim = Color(0xFFD4D6DA);
  static const accentSoft = Color(0x1FFFFFFF); // 12% white for tinted fills

  static const green = Color(0xFF2ECC71);

  static const red = Color(0xFFEF4444);
  static const redSoft = Color(0x26EF4444);
  static const gold = Color(0xFFFACC15);

  static const textPrimary = Color(0xFFF2F3F5);
  static const textSecondary = Color(0xFF9EA3AA);
  static const textMuted = Color(0xFF6B7078);
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.black,
        surface: AppColors.surface,
        error: AppColors.red,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    dividerColor: AppColors.border,
  );
}
