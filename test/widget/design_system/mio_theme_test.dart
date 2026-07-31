import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/theme/mio_ani_theme.dart';
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
