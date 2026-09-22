import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/home/presentation/hero_louver.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// Where a slide's window lands inside the strip, mirroring the placement the
/// hero slide gives its card: centred in its own page slot, then shifted by the
/// metrics offset. The slot itself follows the page distance.
Rect _windowRect(HeroLouverMetrics metrics, double distance) {
  final slotWidth = metrics.cardWidth + metrics.gap;
  final slotLeft = metrics.pageWidth / 2 + distance * slotWidth - slotWidth / 2;
  final cardLeft =
      slotLeft +
      (slotWidth - metrics.cardWidth) / 2 +
      metrics.slotOffsetFor(distance);
  final windowWidth = metrics.windowWidthFor(distance);
  return Rect.fromLTWH(
    cardLeft + (metrics.cardWidth - windowWidth) / 2,
    0,
    windowWidth,
    metrics.cardHeight,
  );
}

void main() {
  group('HeroLouverMetrics', () {
    test('a phone strip holds the slats at their minimum and gives the card '
        'the rest', () {
      final metrics = HeroLouverMetrics.forWidth(390 - 2 * MioSpacing.lg);

      expect(metrics.slatWidth, 40);
      expect(metrics.cardWidth, 246);
      expect(metrics.cardHeight, 213);
      expect(metrics.gap, 8);
      expect(metrics.pageWidth, 390 - 2 * MioSpacing.lg);
      expect(metrics.viewportFraction, closeTo(254 / 342, 1e-9));
      // The reference card is landscape, not the portrait poster itself.
      expect(metrics.cardWidth, greaterThan(metrics.cardHeight));
    });

    test('a wide window grows the slats before it grows the card', () {
      final metrics = HeroLouverMetrics.forWidth(800 - 2 * MioSpacing.lg);

      expect(metrics.slatWidth, 56);
      expect(metrics.cardWidth, 300);
      // The strip keeps its size, so the louver stays centred in the slack.
      expect(metrics.pageWidth, 428);
      expect(metrics.viewportFraction, closeTo(308 / 428, 1e-9));
    });

    test('a narrow window gives way in the card, never in the slats', () {
      final metrics = HeroLouverMetrics.forWidth(320 - 2 * MioSpacing.lg);

      expect(metrics.slatWidth, 40);
      expect(metrics.cardWidth, 176);
      expect(metrics.pageWidth, 320 - 2 * MioSpacing.lg);
    });

    test('windows open to the whole card at the centre and close to a slat '
        'aside', () {
      final metrics = HeroLouverMetrics.forWidth(342);

      expect(metrics.windowWidthFor(0), metrics.cardWidth);
      expect(metrics.windowWidthFor(0.5), closeTo(143, 1e-9));
      expect(metrics.windowWidthFor(-1), metrics.slatWidth);
      expect(metrics.windowWidthFor(1), metrics.slatWidth);
      // Slides further out are never built wider than a slat.
      expect(metrics.windowWidthFor(-3), metrics.slatWidth);
      expect(metrics.windowWidthFor(4), metrics.slatWidth);

      expect(metrics.focusFor(0), 1);
      expect(metrics.focusFor(0.5), 0.5);
      expect(metrics.focusFor(-1), 0);
      expect(metrics.focusFor(2), 0);
    });

    test('a centred card keeps still and a settled slat lands on the strip '
        'edge', () {
      final metrics = HeroLouverMetrics.forWidth(342);

      expect(metrics.slotOffsetFor(0), 0);
      final centred = _windowRect(metrics, 0);
      expect(centred.width, metrics.cardWidth);
      expect(centred.center.dx, closeTo(metrics.pageWidth / 2, 1e-9));

      for (final distance in <double>[-1, 1]) {
        final window = _windowRect(metrics, distance);
        expect(window.width, metrics.slatWidth);
        expect(window.height, metrics.cardHeight);
        expect(window.top, centred.top);
        expect(window.bottom, centred.bottom);
        if (distance < 0) {
          expect(window.left, closeTo(0, 1e-9));
        } else {
          expect(window.right, closeTo(metrics.pageWidth, 1e-9));
        }
      }
    });
  });

  group('HeroWindowClipper', () {
    test('narrows the card around its middle, at full height', () {
      const clipper = HeroWindowClipper(windowWidth: 40, radius: MioRadii.lg);
      final clip = clipper.getClip(const Size(246, 213));

      expect(clip.width, 40);
      expect(clip.left, (246 - 40) / 2);
      expect(clip.top, 0);
      expect(clip.height, 213);
    });

    test('rounds a slat down to a capsule and a card at its own radius', () {
      final slat = const HeroWindowClipper(
        windowWidth: 40,
        radius: MioRadii.lg,
      ).getClip(const Size(246, 213));
      final card = const HeroWindowClipper(
        windowWidth: 246,
        radius: MioRadii.lg,
      ).getClip(const Size(246, 213));

      expect(slat.tlRadiusX, 20);
      expect(card.tlRadiusX, MioRadii.lg);
    });

    test('reclips only when the window or the radius moves', () {
      const clipper = HeroWindowClipper(windowWidth: 40, radius: MioRadii.lg);

      expect(
        clipper.shouldReclip(
          const HeroWindowClipper(windowWidth: 40, radius: MioRadii.lg),
        ),
        isFalse,
      );
      expect(
        clipper.shouldReclip(
          const HeroWindowClipper(windowWidth: 41, radius: MioRadii.lg),
        ),
        isTrue,
      );
    });
  });
}
