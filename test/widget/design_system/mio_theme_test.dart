import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/theme/mio_ani_theme.dart';
import 'package:mio_ani/src/shared/design_system/mio_backdrop.dart';
import 'package:mio_ani/src/shared/design_system/mio_motion.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

void main() {
  test('dark theme is constructed from MioAni brand tokens', () {
    final theme = MioAniTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, MioColors.accent);
    expect(theme.colorScheme.surface, MioColors.surface);
    expect(theme.scaffoldBackgroundColor, MioColors.background);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
  });

  test('critical brand color pairs meet WCAG AA text contrast', () {
    double contrastRatio(Color foreground, Color background) {
      final lighter =
          foreground.computeLuminance() > background.computeLuminance()
          ? foreground
          : background;
      final darker = identical(lighter, foreground) ? background : foreground;
      return (lighter.computeLuminance() + 0.05) /
          (darker.computeLuminance() + 0.05);
    }

    expect(
      contrastRatio(MioColors.textPrimary, MioColors.background),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(MioColors.textSecondary, MioColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(MioColors.onAccent, MioColors.accent),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('the canvas is a dark brand colour rather than a neutral black', () {
    final background = MioColors.background;

    // Still a background: dark enough to sit under text without glow.
    expect(background.computeLuminance(), lessThan(0.02));
    // But a colour, not a shade of black: it carries the accent's green.
    expect(background.g, greaterThan(background.r));
    expect(background.g, greaterThan(background.b));
    expect(background.g - background.b, greaterThan(0.02));
  });

  testWidgets('the brand backdrop washes the accent over the canvas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MioBackdrop(child: SizedBox.expand())),
    );

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MioBackdrop),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.color, MioColors.background);
    final gradient = decoration.gradient! as RadialGradient;
    expect(gradient.colors.first, MioColors.backdropGlow);
    // The halo fades out in its own hue, never towards black.
    expect(gradient.colors.last.a, 0);
    expect(gradient.colors.last.r, gradient.colors.first.r);
    expect(gradient.colors.last.g, gradient.colors.first.g);
  });

  testWidgets('non-essential motion becomes immediate when disabled', (
    tester,
  ) async {
    late Duration resolved;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              resolved = MioMotion.resolve(context, MioDurations.medium);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(resolved, Duration.zero);
  });
}
