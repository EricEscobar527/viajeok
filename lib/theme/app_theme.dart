import 'package:flutter/material.dart';

/// Brand palette: slate-gray surfaces (lighter than near-black) with white
/// as the accent. Green and red are reserved for "worth it" / "not worth it".
abstract final class AppColors {
  // Keep `background` in sync with launch_background.xml and TripOverlay.kt.
  static const background = Color(0xFF1F2329);
  static const surface = Color(0xFF2A2F36);
  static const surfaceHigh = Color(0xFF353B43);
  static const border = Color(0xFF434A53);

  static const accent = Color(0xFFFFFFFF);
  static const accentSoft = Color(0x1AFFFFFF); // 10% white for tinted fills

  static const green = Color(0xFF34D399);
  static const red = Color(0xFFF87171);

  static const textPrimary = Color(0xFFF5F6F8);
  static const textSecondary = Color(0xFFB4BAC2);
  static const textMuted = Color(0xFF848B95);
}

/// Corner radius used across cards and buttons: squarer than pill shapes.
const kRadius = 14.0;

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
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.black
            : AppColors.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.accent
            : AppColors.surfaceHigh,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.surfaceHigh,
      thumbColor: AppColors.accent,
      valueIndicatorColor: AppColors.surfaceHigh,
      valueIndicatorTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      ),
    ),
  );
}
