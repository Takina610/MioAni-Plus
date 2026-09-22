import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/home/presentation/hero_louver.dart';
import 'package:mio_ani/src/features/home/presentation/home_page.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

import '../../support/fake_home_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('renders brand hero and all ready sections', (tester) async {
    await configureTestViewport(tester, size: const Size(800, 2400));

    await _pumpHome(tester, _readyRepository());
    await tester.pump();

    expect(find.text('MioAni'), findsOneWidget);
    expect(find.text('新番时间表'), findsOneWidget);
    expect(find.text('本季推荐'), findsOneWidget);
    expect(find.text('首推动画'), findsWidgets);
    expect(find.text('海报一'), findsOneWidget);
    // The schedule preview block now lives only on the schedule branch.
    expect(find.text('最近更新'), findsNothing);
    expect(find.text('放送预览'), findsNothing);
    expect(find.text('查看完整日程'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog failure keeps the brand shell and its shortcut', (
    tester,
  ) async {
    final snapshot = HomeSnapshot(
      catalog: const HomeSection<HomeCatalogContent>.failed(OfflineFailure()),
    );
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(snapshot),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    expect(find.text('当前处于离线状态'), findsOneWidget);
    expect(find.text('新番时间表'), findsOneWidget);
    expect(find.text('本季推荐'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale offline banner offers a retry', (tester) async {
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(
        testHomeSnapshot(
          catalog: HomeSection<HomeCatalogContent>.ready(
            value: const HomeCatalogContent(
              hero: <AnimeSummary>[],
              trending: <AnimeSummary>[],
            ),
            isStale: true,
            fetchedAt: DateTime.utc(2026, 8, 4, 8),
            refreshFailure: const OfflineFailure(),
          ),
        ),
      ),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    expect(find.textContaining('当前显示离线缓存'), findsOneWidget);
    expect(repository.calls, 1);

    await tester.tap(find.text('重试更新'));
    await tester.pump();
    expect(repository.calls, 2);
  });

  testWidgets('hero louver fans one card out between two slat windows', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    await _pumpHome(tester, _readyRepository());
    await tester.pump();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.viewportFraction, lessThan(1));
    // The dots and the pause control of the old carousel are gone.
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);

    final metrics = HeroLouverMetrics.forWidth(390 - 2 * MioSpacing.lg);
    final boxes = _heroBoxes(tester);
    expect(boxes, isNotEmpty);
    // Every card keeps the reference card size; only its window narrows, so the
    // slats stay slats of the same card instead of shrunken copies of it.
    for (final box in boxes) {
      expect(box.width, closeTo(metrics.cardWidth, 0.5));
      expect(box.height, closeTo(metrics.cardHeight, 0.5));
    }

    final windows = _heroWindows(tester);
    final centre = tester.getCenter(find.byType(PageView)).dx;
    final fanned = windows.singleWhere(
      (window) => (window.width - metrics.cardWidth).abs() < 0.5,
    );
    expect(fanned.width, greaterThan(fanned.height));
    expect(fanned.center.dx, closeTo(centre, 0.5));

    // The neighbours are slat-width windows flush with the strip edges, and as
    // tall as the card they show through.
    final slats = windows
        .where((window) => (window.width - metrics.slatWidth).abs() < 0.5)
        .toList();
    expect(slats, isNotEmpty);
    final stripLeft = MioSpacing.lg;
    final stripRight = 390 - MioSpacing.lg;
    for (final slat in slats) {
      expect(slat.width, closeTo(metrics.slatWidth, 0.5));
      expect(slat.top, closeTo(fanned.top, 0.5));
      expect(slat.bottom, closeTo(fanned.bottom, 0.5));
      final flushLeft = (slat.left - stripLeft).abs() < 0.5;
      final flushRight = (slat.right - stripRight).abs() < 0.5;
      expect(
        flushLeft || flushRight,
        isTrue,
        reason: 'slat $slat does not sit flush with a strip edge',
      );
    }
    expect(slats.any((slat) => (slat.left - stripLeft).abs() < 0.5), isTrue);
    expect(slats.any((slat) => (slat.right - stripRight).abs() < 0.5), isTrue);

    // Only the centred card carries a readable title; the slats show art alone
    // rather than a fragment of a title their window cuts off.
    final labelOpacities = tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(PageView),
            matching: find.byType(Opacity),
          ),
        )
        .map((opacity) => opacity.opacity)
        .toList();
    expect(labelOpacities.where((opacity) => opacity == 1), hasLength(1));
    expect(labelOpacities.where((opacity) => opacity == 0), isNotEmpty);
  });

  testWidgets('hero louver auto-advances after its dwell', (tester) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    await _pumpHome(tester, _readyRepository());
    await tester.pump();
    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    final start = controller.page!.round();

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.page!.round(), start + 1);
  });

  testWidgets('reduced motion keeps the louver static', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      () => tester.platformDispatcher.clearAccessibilityFeaturesTestValue(),
    );

    await _pumpHome(tester, _readyRepository());
    await tester.pump();
    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    final start = controller.page!.round();

    await tester.pump(const Duration(seconds: 12));

    expect(controller.page!.round(), start);
  });

  testWidgets('season posters wrap three per row in portrait tiles', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 2400));

    await _pumpHome(tester, _readyRepository());
    await tester.pump();

    final posters = _posterRects(tester, count: 4);
    expect(posters[0].top, posters[1].top);
    expect(posters[1].top, posters[2].top);
    expect(posters[3].top, greaterThan(posters[2].top));
    expect(posters[0].left, lessThan(posters[1].left));
    expect(posters[1].left, lessThan(posters[2].left));
    expect(posters.first.height, greaterThan(posters.first.width));
  });

  testWidgets('a row shares one poster height whatever the title length', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 2400));
    final posters = <AnimeSummary>[
      _anime(11, '短标题'),
      _anime(12, '很长很长的动画标题需要换成两行才能完整显示'),
      _anime(13, '中等长度的标题'),
    ];
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(
        testHomeSnapshot(
          catalog: HomeSection<HomeCatalogContent>.ready(
            value: HomeCatalogContent(
              hero: const <AnimeSummary>[],
              trending: posters,
            ),
          ),
        ),
      ),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    final rects = _posterRects(tester, count: 3);
    // A one-line title leaves its second line reserved instead of growing the
    // poster, so all three tiles keep the same height and poster band.
    expect(rects[0].height, closeTo(rects[1].height, 0.01));
    expect(rects[1].height, closeTo(rects[2].height, 0.01));
    expect(rects[0].top, closeTo(rects[1].top, 0.01));
    expect(rects[0].bottom, closeTo(rects[1].bottom, 0.01));
    expect(rects[0].width, closeTo(rects[1].width, 0.01));
    expect(tester.takeException(), isNull);
  });

  for (final size in <Size>[
    const Size(390, 844),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    testWidgets('supports ${size.width.toInt()}px layout at 200% text scale', (
      tester,
    ) async {
      await configureTestViewport(tester, size: size, textScaleFactor: 2);

      await _pumpHome(tester, _readyRepository());
      await tester.pump();

      expect(find.text('本季推荐'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpHome(WidgetTester tester, FakeHomeRepository repository) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
      retry: disableProviderRetry,
      child: const MaterialApp(home: HomePage()),
    ),
  );
}

FakeHomeRepository _readyRepository() {
  return FakeHomeRepository(watchFactory: () => Stream.value(_readySnapshot()));
}

List<Rect> _heroBoxes(WidgetTester tester) {
  final finder = _heroWindowFinder;
  return <Rect>[
    for (var index = 0; index < finder.evaluate().length; index += 1)
      tester.getRect(finder.at(index)),
  ];
}

/// The window each hero card is painted through, in screen coordinates.
List<Rect> _heroWindows(WidgetTester tester) {
  final finder = _heroWindowFinder;
  return <Rect>[
    for (var index = 0; index < finder.evaluate().length; index += 1)
      _heroWindow(tester, finder.at(index)),
  ];
}

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

List<Rect> _posterRects(WidgetTester tester, {required int count}) {
  final finder = find.descendant(
    of: find.byType(GridView),
    matching: find.byType(MioImage),
  );
  return <Rect>[
    for (var index = 0; index < count; index += 1)
      tester.getRect(finder.at(index)),
  ];
}

HomeSnapshot _readySnapshot() {
  final hero = <AnimeSummary>[_anime(1, '首推动画'), _anime(2, '第二部动画')];
  final posters = <AnimeSummary>[
    _anime(11, '海报一'),
    _anime(12, '海报二'),
    _anime(13, '海报三'),
    _anime(14, '海报四'),
  ];
  return testHomeSnapshot(
    catalog: HomeSection<HomeCatalogContent>.ready(
      value: HomeCatalogContent(hero: hero, trending: posters),
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
