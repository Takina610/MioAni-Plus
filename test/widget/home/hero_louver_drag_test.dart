import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/home/presentation/hero_louver.dart';
import 'package:mio_ani/src/features/home/presentation/home_page.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

import '../../support/fake_home_repository.dart';
import '../../support/test_viewport.dart';

/// The strip is dragged here and then read out of the geometry it drew: where
/// each window stands, how wide it is, and which title is the lit one. Nothing
/// private to the strip is needed to say whether a slide is behaving.
void main() {
  testWidgets('a slow drag eases the outgoing slat off the strip', (
    tester,
  ) async {
    const width = 390.0;
    await configureTestViewport(tester, size: const Size(width, 844));
    await _pumpHome(tester);

    final metrics = HeroLouverMetrics.forWidth(width - 2 * MioSpacing.lg);
    final strip = tester.getRect(find.byKey(heroStripKey));
    expect(strip.width, closeTo(metrics.pageWidth, 0.5));

    // At rest: one card between two slats, each flush with a strip edge, and
    // the wider window straddles the strip's middle.
    final resting = _windows(tester, metrics);
    expect(resting.centred.width, closeTo(metrics.cardWidth, 0.5));
    expect(resting.centred.center.dx, closeTo(strip.center.dx, 0.5));
    expect(resting.leftSlat.left, closeTo(strip.left, 0.5));
    expect(resting.rightSlat.right, closeTo(strip.right, 0.5));

    // Drag until the strip is between two slides, which is where the outgoing
    // slat used to disappear instead of easing out.
    final gesture = await tester.startGesture(strip.center);
    var dragging = _windows(tester, metrics);
    for (
      var step = 0;
      step < 20 && _dragFraction(dragging.distances) < 0.15;
      step += 1
    ) {
      await gesture.moveBy(const Offset(-12, 0));
      await tester.pump();
      dragging = _windows(tester, metrics);
    }
    expect(
      _dragFraction(dragging.distances),
      inInclusiveRange(0.15, 0.25),
      reason: 'the drag has to land while the outgoing slat is on its way out',
    );

    // Every window stands one slice from the next, and is exactly as wide as
    // its distance from the scroll position says. A window that stopped moving
    // while the strip kept going would fail both.
    expect(dragging.distances, hasLength(5));
    for (var index = 1; index < dragging.distances.length; index += 1) {
      expect(
        dragging.distances[index] - dragging.distances[index - 1],
        closeTo(1, 0.02),
      );
    }
    for (final entry in dragging.byDistance.entries) {
      expect(
        entry.value.width,
        closeTo(metrics.windowWidthFor(entry.key), 1),
        reason: 'window ${entry.value} is not as wide as ${entry.key} says',
      );
    }

    // The strip shows three slides: the slat easing out, the card giving up the
    // middle, and the one taking it. Nothing has dropped off it or popped back
    // on early.
    expect(_visible(dragging, strip), hasLength(3));

    // The slat on its way out still shows a band at the left edge, having moved
    // by as much as the strip did.
    final leaving = _leftmostVisible(dragging, strip);
    expect(leaving.width, closeTo(metrics.slatWidth, 1));
    expect(leaving.left, lessThan(strip.left));
    expect(leaving.right, greaterThan(strip.left));
    expect(leaving.right, lessThan(strip.left + metrics.slatWidth));

    await gesture.up();
    await tester.pumpAndSettle();

    // Letting go settles the strip on a whole slide again.
    final settled = _windows(tester, metrics);
    expect(settled.centred.width, closeTo(metrics.cardWidth, 0.5));
    expect(settled.leftSlat.left, closeTo(strip.left, 0.5));
    expect(settled.rightSlat.right, closeTo(strip.right, 0.5));
  });

  testWidgets('a flick sends the strip on to the next slide', (tester) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    await _pumpHome(tester);

    expect(_litTitle(tester), '首推动画');

    await tester.fling(find.byKey(heroStripKey), const Offset(-160, 0), 1600);
    await tester.pumpAndSettle();

    expect(_litTitle(tester), '第二部动画');
  });

  testWidgets('a slide in flight is dropped with the section', (tester) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    await _pumpHome(tester);

    // Let the dwell fire and the strip be halfway to the next slide, then take
    // the page away under it the way switching branches would.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    expect(tester.takeException(), isNull);
  });
}

/// The windows the strip has laid out, with how far each stands from the scroll
/// position in slices: the centred slide is at 0, its neighbour at 1, and so on.
final class _Windows {
  const _Windows(this.byDistance);

  final Map<double, Rect> byDistance;

  List<double> get distances => byDistance.keys.toList()..sort();

  Rect get centred => _nearest(0);
  Rect get leftSlat => _nearest(-1);
  Rect get rightSlat => _nearest(1);

  Rect _nearest(double slide) {
    return byDistance.entries
        .reduce(
          (a, b) => (a.key - slide).abs() <= (b.key - slide).abs() ? a : b,
        )
        .value;
  }
}

/// Where the strip sits between two slides, from the distances the windows stand
/// at: whole slices apart, so the fraction is the drag itself.
double _dragFraction(Iterable<double> distances) {
  final moved = -distances.first;
  return moved - moved.floorToDouble();
}

_Windows _windows(WidgetTester tester, HeroLouverMetrics metrics) {
  final strip = tester.getRect(find.byKey(heroStripKey));
  return _Windows(<double, Rect>{
    for (final window in _heroWindows(tester))
      (window.center.dx - strip.center.dx) / metrics.sliceSpacing: window,
  });
}

/// The windows the strip is showing any part of.
Iterable<Rect> _visible(_Windows windows, Rect strip) {
  return windows.byDistance.values.where(
    (window) => window.right > strip.left && window.left < strip.right,
  );
}

Rect _leftmostVisible(_Windows windows, Rect strip) {
  return _visible(windows, strip).reduce((a, b) => a.left <= b.left ? a : b);
}

/// The title of the card the strip is offering, which is the only fully lit one.
String _litTitle(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byKey(heroStripKey),
    matching: find.byType(Opacity),
  );
  for (var index = 0; index < finder.evaluate().length; index += 1) {
    if (tester.widget<Opacity>(finder.at(index)).opacity == 1) {
      return tester
              .widget<Text>(
                find.descendant(
                  of: finder.at(index),
                  matching: find.byType(Text),
                ),
              )
              .data ??
          '';
    }
  }
  return '';
}

List<Rect> _heroWindows(WidgetTester tester) {
  final finder = _heroWindowFinder;
  return <Rect>[
    for (var index = 0; index < finder.evaluate().length; index += 1)
      _heroWindow(tester, finder.at(index)),
  ];
}

/// The window a hero card is painted through, in screen coordinates.
Rect _heroWindow(WidgetTester tester, Finder finder) {
  final box = tester.getRect(finder);
  final clipper =
      tester.widget<ClipRRect>(finder).clipper! as HeroWindowClipper;
  final clip = clipper.getClip(box.size);
  return Rect.fromLTWH(
    box.left + clip.left,
    box.top + clip.top,
    clip.width,
    clip.height,
  );
}

final Finder _heroWindowFinder = find.byWidgetPredicate(
  (widget) => widget is ClipRRect && widget.clipper is HeroWindowClipper,
);

/// Pumps the home page and then once more, which is the frame the home
/// controller's first snapshot lands on.
Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeRepositoryProvider.overrideWithValue(
          FakeHomeRepository(watchFactory: () => Stream.value(_snapshot())),
        ),
      ],
      retry: disableProviderRetry,
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pump();
}

HomeSnapshot _snapshot() {
  return testHomeSnapshot(
    catalog: HomeSection<HomeCatalogContent>.ready(
      value: HomeCatalogContent(
        hero: <AnimeSummary>[_anime(1, '首推动画'), _anime(2, '第二部动画')],
        trending: const <AnimeSummary>[],
      ),
    ),
  );
}

AnimeSummary _anime(int id, String title) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: title,
    sourceTitle: '',
  );
}
