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
      // A page opens over the one it was opened from and does not transition
      // into place: what a reader watches is the page they opened arriving, and
      // the list they opened it from staying exactly as they left it.
      //
      // Material's own Android transition would do neither: it shrinks and dims
      // the page underneath while fading the new one up, which puts two pictures
      // of the app on screen at once at half strength. The app draws its own way
      // of arriving — the detail page comes up from the bottom edge, around the
      // frame the tapped picture is landing in — and this is where the framework
      // is told not to add a second one.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _StillPages(),
        },
      ),
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

/// Pages that do not move: the page below stays where it is, and the page above
/// is drawn as it is.
///
/// Marking a route as opaque is what keeps the list behind it from being drawn
/// at all once the page has settled; this only decides what happens on the way
/// there, and on the way there the app wants nothing but its own motion.
class _StillPages extends PageTransitionsBuilder {
  const _StillPages();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
