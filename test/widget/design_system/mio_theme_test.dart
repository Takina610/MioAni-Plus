import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    // A floor, and a wash over it: two paints rather than one decoration,
    // because a decoration's gradient is a paint shader and a paint with a
    // shader ignores its colour — the canvas would be as solid as its wash.
    final floor = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(MioBackdrop),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(floor.color, MioColors.background);
    expect(floor.color.a, 1);

    final wash = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MioBackdrop),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final gradient =
        (wash.decoration as BoxDecoration).gradient! as RadialGradient;
    expect(gradient.colors.first, MioColors.backdropGlow);
    // The halo fades out in its own hue, never towards black.
    expect(gradient.colors.last.a, 0);
    expect(gradient.colors.last.r, gradient.colors.first.r);
    expect(gradient.colors.last.g, gradient.colors.first.g);
  });

  testWidgets('nothing behind the canvas shows through it', (tester) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: boundary,
          // Something that could not be mistaken for a canvas, drawn behind
          // one: a screen that moves its canvas — the detail page arriving as a
          // drawer over the list — is bringing this with it.
          child: const ColoredBox(
            color: Color(0xFFFF0000),
            child: MioBackdrop(child: SizedBox.expand()),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(MioBackdrop));
    final bytes = await tester.runAsync(() async {
      final box =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await box.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return data;
    });

    Color pixelAt(int x, int y) {
      final index = (y * size.width.round() + x) * 4;
      return Color.fromARGB(
        bytes!.getUint8(index + 3),
        bytes.getUint8(index),
        bytes.getUint8(index + 1),
        bytes.getUint8(index + 2),
      );
    }

    // Anywhere the canvas is thin, the red behind it comes through.
    final width = size.width.round() - 1;
    final height = size.height.round() - 1;
    for (final (x, y) in <(int, int)>[
      (0, 0),
      (width, 0),
      (0, height),
      (width, height),
      (width ~/ 2, height ~/ 2),
      (1, height - 1),
    ]) {
      final pixel = pixelAt(x, y);
      expect(
        pixel.r,
        lessThan(64),
        reason: 'the canvas at $x,$y is $pixel, not the brand canvas',
      );
    }
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
