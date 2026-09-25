import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/home/presentation/hero_louver.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// Where a slide's window lands on the strip, which is what the strip lays out:
/// centred on the slide's slice and as wide as its focus says.
Rect _windowRect(HeroLouverMetrics metrics, double distance) {
  final width = metrics.windowWidthFor(distance);
  return Rect.fromLTWH(
    metrics.windowCenterFor(distance) - width / 2,
    0,
    width,
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
      // The reference card is landscape, not the portrait poster itself.
      expect(metrics.cardWidth, greaterThan(metrics.cardHeight));
    });

    test('a wide window grows the slats before it grows the card', () {
      final metrics = HeroLouverMetrics.forWidth(800 - 2 * MioSpacing.lg);

      expect(metrics.slatWidth, 56);
      expect(metrics.cardWidth, 300);
      // The strip keeps its size, so the louver stays centred in the slack.
      expect(metrics.pageWidth, 428);
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

    test('a slice stands half a card and slat plus the gap from the next', () {
      final metrics = HeroLouverMetrics.forWidth(342);

      expect(metrics.sliceSpacing, closeTo(151, 1e-9));
      expect(
        metrics.sliceSpacing,
        closeTo(
          (metrics.cardWidth + metrics.slatWidth) / 2 + metrics.gap,
          1e-9,
        ),
      );
    });

    test('a centred card keeps still and a settled slat lands on the strip '
        'edge', () {
      final metrics = HeroLouverMetrics.forWidth(342);

      expect(metrics.windowCenterFor(0), metrics.pageWidth / 2);
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

    test(
      'a drag carries every window along the slice grid, at any distance',
      () {
        final metrics = HeroLouverMetrics.forWidth(342);
        final centre = metrics.pageWidth / 2;

        for (final distance in <double>[
          -2.5,
          -1.75,
          -1.25,
          -1,
          -0.5,
          0,
          0.5,
          1,
          1.25,
          1.75,
          2.5,
        ]) {
          expect(
            metrics.windowCenterFor(distance),
            closeTo(centre + distance * metrics.sliceSpacing, 1e-9),
            reason: 'the window of a slide $distance slices out has drifted',
          );
        }
      },
    );

    test('an outgoing slat eases off the edge instead of dropping out', () {
      final metrics = HeroLouverMetrics.forWidth(342);

      // Still on the strip a quarter of a slice into the drag, having moved a
      // quarter of a slice. It used to be gone by then, carried away at the
      // width of a whole card rather than at the strip's own step.
      final quarter = _windowRect(metrics, -1.25);
      expect(quarter.width, metrics.slatWidth);
      expect(
        quarter.right,
        closeTo(metrics.slatWidth - 0.25 * metrics.sliceSpacing, 1e-9),
      );
      expect(quarter.right, greaterThan(0));
      expect(quarter.right, lessThan(metrics.slatWidth));

      // Gone once it has travelled its own width, and not before.
      expect(_windowRect(metrics, -1.5).right, lessThan(0));
      expect(_windowRect(metrics, -1).right, closeTo(metrics.slatWidth, 1e-9));
    });

    test('the incoming slide waits off the strip as long as the outgoing one '
        'takes to leave', () {
      final metrics = HeroLouverMetrics.forWidth(342);
      final flush = metrics.pageWidth - metrics.slatWidth;

      final arriving = _windowRect(metrics, 1.25);
      expect(arriving.left, closeTo(flush + 0.25 * metrics.sliceSpacing, 1e-9));
      expect(arriving.left, greaterThan(flush));
      expect(arriving.left, lessThan(metrics.pageWidth));
      expect(_windowRect(metrics, 1.5).left, greaterThan(metrics.pageWidth));
    });

    test('neighbouring windows keep their gap while the drag is in flight', () {
      final metrics = HeroLouverMetrics.forWidth(342);

      for (final position in <double>[0.1, 0.25, 0.5, 0.75, 0.9]) {
        final outgoing = _windowRect(metrics, -position);
        final incoming = _windowRect(metrics, 1 - position);
        expect(
          incoming.left - outgoing.right,
          closeTo(metrics.gap, 1e-9),
          reason: 'the gap closed while dragging $position of a slide',
        );
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
