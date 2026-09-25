import 'dart:async';

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
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

import '../../support/fake_home_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('a grid laid out before the window has a width still stands', (
    tester,
  ) async {
    // The first frame of a cold start on Android lays the page out once inside
    // a zero-width viewport. A tile cannot be divided out of nothing, and this
    // is what a negative tile used to do here: assert inside the text
    // measurement, which threw away the first frame and left the app on its
    // splash screen.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWithValue(_readyRepository()),
        ],
        retry: disableProviderRetry,
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(width: 0, child: HomePage())),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a season with nothing in it says so instead of waiting', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    // The snapshot is the answer: the season grid is done reading, and it came
    // back empty. Standing empty tiles up here would be a page pretending to
    // still be loading, and would keep the skeleton's sweep running forever.
    await _pumpHome(
      tester,
      FakeHomeRepository(
        watchFactory: () => Stream.value(
          testHomeSnapshot(
            catalog: const HomeSection<HomeCatalogContent>.ready(
              value: HomeCatalogContent(
                hero: <AnimeSummary>[],
                trending: <AnimeSummary>[],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('本季暂无可推荐的作品'), findsOneWidget);
    expect(find.byType(MioPlaceholder), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the season grid holds the page while the catalog is read', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final catalog = StreamController<HomeSnapshot>();
    addTearDown(catalog.close);
    final repository = FakeHomeRepository(watchFactory: () => catalog.stream);

    await _pumpHome(tester, repository);
    await tester.pump();

    // The section names itself and stands the posters up before it has any:
    // the page a reader lands on is the page they will read, and nothing on it
    // spins while it fills in.
    expect(find.text('本季推荐'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GridView).first,
        matching: find.byType(MioPlaceholder),
      ),
      findsWidgets,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    catalog.add(_readySnapshot());
    await tester.pump();
    expect(find.text('海报一'), findsOneWidget);
  });

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

  testWidgets('a stale catalog whose refresh failed draws no banner', (
    tester,
  ) async {
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

    // The page is the page. What the app is doing with its cache, and whether
    // the last background read went through, is not something a reader is shown
    // on any screen — see `no_cache_notices_test.dart` for the rule.
    expect(find.text('MioAni'), findsOneWidget);
    expect(find.textContaining('缓存'), findsNothing);
    expect(find.text('重试更新'), findsNothing);
    expect(repository.calls, 1);
  });

  testWidgets('hero louver fans one card out between two slat windows', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    await _pumpHome(tester, _readyRepository());
    await tester.pump();

    // The dots and the pause control of the old carousel are gone.
    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);

    final metrics = HeroLouverMetrics.forWidth(390 - 2 * MioSpacing.lg);
    final strip = tester.getRect(find.byKey(heroStripKey));
    expect(strip.width, closeTo(metrics.pageWidth, 0.5));

    // Every card keeps the reference card size; only its window narrows, so the
    // slats stay slats of the same card instead of shrunken copies of it.
    final boxes = _heroBoxes(tester);
    expect(boxes, isNotEmpty);
    for (final box in boxes) {
      expect(box.width, closeTo(metrics.cardWidth, 0.5));
      expect(box.height, closeTo(metrics.cardHeight, 0.5));
    }

    // One window is the whole card, centred on the strip, and the strip edges
    // carry the slat its neighbour shows through.
    final windows = _heroWindows(tester);
    final fanned = windows.singleWhere(
      (window) => (window.width - metrics.cardWidth).abs() < 0.5,
    );
    expect(fanned.width, greaterThan(fanned.height));
    expect(fanned.center.dx, closeTo(strip.center.dx, 0.5));

    final slats = windows
        .where((window) => (window.width - metrics.slatWidth).abs() < 0.5)
        .where(
          (window) => window.right > strip.left && window.left < strip.right,
        )
        .toList();
    expect(slats, hasLength(2));
    for (final slat in slats) {
      expect(slat.top, closeTo(fanned.top, 0.5));
      expect(slat.bottom, closeTo(fanned.bottom, 0.5));
      final flushLeft = (slat.left - strip.left).abs() < 0.5;
      final flushRight = (slat.right - strip.right).abs() < 0.5;
      expect(
        flushLeft || flushRight,
        isTrue,
        reason: 'slat $slat does not sit flush with a strip edge',
      );
    }
    expect(slats.any((slat) => (slat.left - strip.left).abs() < 0.5), isTrue);
    expect(slats.any((slat) => (slat.right - strip.right).abs() < 0.5), isTrue);

    // Only the centred card carries a readable title; the slats show art alone
    // rather than a fragment of a title their window cuts off.
    final labelOpacities = tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byKey(heroStripKey),
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
    expect(_litHeroTitle(tester), '首推动画');

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));

    expect(_litHeroTitle(tester), '第二部动画');
  });

  testWidgets('reduced motion keeps the louver static', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      () => tester.platformDispatcher.clearAccessibilityFeaturesTestValue(),
    );

    await _pumpHome(tester, _readyRepository());
    await tester.pump();
    final start = _litHeroTitle(tester);

    await tester.pump(const Duration(seconds: 12));

    expect(_litHeroTitle(tester), start);
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

  testWidgets('explore sits below the season grid and pulls pages to its end', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(_readySnapshot()),
      explorePages: testExploreRanking(pages: 6),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    // The feed lives under the season grid and opens on the first page of the
    // ranking.
    await _scrollTo(tester, find.text('探索'));
    await _scrollTo(tester, find.text('探索1-1'));

    // Walking to the far end of the ranking is what fetches the pages behind
    // it; the feed ends by saying so rather than by going quiet.
    await _scrollTo(tester, find.text('探索6-20'));
    await _scrollTo(tester, find.text('已显示全部 120 部作品'));
    expect(repository.exploreRequests, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every section heading breaks the page at the same line', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 2400));

    await _pumpHome(tester, _readyRepository());
    await tester.pump();

    // The gap above a heading belongs to the heading, so the season grid and
    // the explore feed both start the same distance below whatever precedes
    // them. The feed's own heading used to sit flush against the grid above it.
    final heroBottom = _heroWindows(
      tester,
    ).map((window) => window.bottom).reduce((a, b) => a > b ? a : b);
    final seasonHeadingTop = tester.getRect(find.text('本季推荐')).top;
    final seasonGridBottom = tester.getRect(find.byType(GridView).first).bottom;
    final exploreHeadingTop = tester.getRect(find.text('探索')).top;

    expect(seasonHeadingTop - heroBottom, MioSpacing.xl);
    expect(exploreHeadingTop - seasonGridBottom, MioSpacing.xl);
  });

  testWidgets('the feed reads on as the reader reaches it, not all at once', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(_readySnapshot()),
      explorePages: testExploreRanking(pages: 40),
    );

    await _pumpHome(tester, repository);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Every sliver of a scroll view is built whether or not it is on screen, so
    // a trigger parked at the feed's tail would pull the whole ranking — and
    // every cover in it — in one burst on the first frame. What the reader has
    // room for decides instead: a screenful of posters is read, not forty
    // pages of them.
    expect(
      repository.lastExplorePage,
      lessThanOrEqualTo(2),
      reason: 'opening the page read ${repository.lastExplorePage} pages',
    );
    final afterOpening = repository.exploreRequests;

    // And nothing keeps draining in the background while the reader sits still.
    await tester.pump(const Duration(seconds: 1));
    expect(repository.exploreRequests, afterOpening);

    // Walking down the feed is what reads it on.
    await _scrollTo(tester, find.text('探索4-1'));
    expect(repository.exploreRequests, greaterThan(afterOpening));
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping the hero does not read the feed on', (tester) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(_readySnapshot()),
      explorePages: testExploreRanking(pages: 40),
    );

    await _pumpHome(tester, repository);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final afterOpening = repository.exploreRequests;

    // The hero strip is a horizontal scrollable nested in the page, so its
    // drags travel up through the page's own scroll listeners. Reading them as
    // "the reader reached the end" would pull pages while the reader is only
    // looking at the carousel.
    final hero = find.byKey(heroStripKey);
    await tester.drag(hero, const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.drag(hero, const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(repository.exploreRequests, afterOpening);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pulling the page down refreshes every partition on it', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(_readySnapshot()),
      explorePages: testExploreRanking(pages: 3),
    );

    await _pumpHome(tester, repository);
    await tester.pump();
    expect(repository.calls, 1);
    expect(repository.lastForceRefresh, isFalse);
    // The feed fills to the viewport on its own, so the count to compare
    // against is whatever it reached before the gesture.
    final exploreReads = repository.exploreRequests;
    expect(exploreReads, greaterThanOrEqualTo(1));

    // One gesture from the reader is one refresh: the season grid and the
    // explore ranking behind it both re-read, and neither is served its cache.
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(repository.lastForceRefresh, isTrue);
    // The head of the ranking was re-read rather than served from the cache.
    // How many pages follow is the feed refilling to the viewport, so only the
    // direction of the count is asserted here.
    expect(repository.exploreRequests, greaterThan(exploreReads));
    expect(repository.lastExploreForceRefresh, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the explore feed ends at the ranking without asking again', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(_readySnapshot()),
      explorePages: testExploreRanking(pages: 1),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    await _scrollTo(tester, find.text('已显示全部 20 部作品'));

    expect(repository.exploreRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed explore page offers a retry and keeps the feed', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(_readySnapshot()),
      explorePages: testExploreRanking(pages: 2),
      explorePageFailure: const OfflineFailure(),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    await _scrollTo(tester, find.text('加载更多失败，重试'));
    // The page that failed did not take the posters already loaded with it.
    expect(find.textContaining('探索1-'), findsWidgets);

    repository.explorePageFailure = null;
    await tester.tap(find.text('加载更多失败，重试'));
    await tester.pump();
    await _scrollTo(tester, find.text('探索2-1'));

    // The head, the page that failed, and the retry that replaced it.
    expect(repository.exploreRequests, 3);
    expect(repository.lastExplorePage, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed explore head names its section and retries', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(_readySnapshot()),
      explorePages: testExploreRanking(pages: 1),
      exploreFailure: const OfflineFailure(),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    // The section keeps its own title, so the failure is not mistaken for the
    // season grid above it having broken.
    await _scrollTo(tester, find.text('探索'));
    await _scrollTo(tester, find.text('当前处于离线状态'));

    repository.exploreFailure = null;
    await tester.tap(find.text('重试'));
    await tester.pump();
    await _scrollTo(tester, find.text('探索1-20'));

    expect(tester.takeException(), isNull);
  });
}

/// Scrolls the home page until [target] is on screen, which is also what drives
/// the explore feed: its next page is only asked for once its tail is reached.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 400, scrollable: _homeScrollable);
  await tester.pump();
}

/// The page's own scrollable, ahead of the hero carousel nested inside it.
final Finder _homeScrollable = find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

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

/// The title of the card the strip is offering, which is the only fully lit one.
String _litHeroTitle(WidgetTester tester) {
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
