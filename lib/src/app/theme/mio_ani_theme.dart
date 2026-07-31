import 'package:flutter/material.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

abstract final class MioAniTheme {
  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: MioColors.accent,
          brightness: Brightness.dark,
          surface: MioColors.surface,
        ).copyWith(
          primary: MioColors.accent,
          onPrimary: MioColors.onAccent,
          surface: MioColors.surface,
          onSurface: MioColors.textPrimary,
          error: MioColors.error,
          outline: MioColors.outline,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MioColors.background,
      focusColor: MioColors.focus,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: MioColors.textPrimary,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
        ),
        titleLarge: TextStyle(
          color: MioColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: MioColors.textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: MioColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: MioColors.surface,
        indicatorColor: MioColors.surfaceHigh,
        height: 72,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: MioColors.surface,
        indicatorColor: MioColors.surfaceHigh,
        selectedIconTheme: IconThemeData(color: MioColors.accent),
        selectedLabelTextStyle: TextStyle(
          color: MioColors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            MioSizes.minimumTouchTarget,
            MioSizes.minimumTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MioRadii.md),
          ),
        ),
      ),
    );
  }
}
