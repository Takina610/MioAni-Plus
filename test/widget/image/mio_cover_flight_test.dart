import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/app/routing/app_router.dart';
import 'package:mio_ani/src/core/image/image_memory_cache.dart';
import 'package:mio_ani/src/core/image/mio_cover_flight.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_page.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/shared/design_system/mio_backdrop.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

import '../../support/fake_catalog_repository.dart';
import '../../support/fake_home_repository.dart';
import '../../support/test_viewport.dart';

/// A tap on a card is a hand-off: the picture the reader was looking at leaves
/// the list it was in and lands where the detail page puts it, and comes home
/// the same way. These tests hold the app to that — across the shell's own
/// navigator, which is where a picture is easiest to lose.
void main() {
  testWidgets('a tapped cover flies to the detail poster and back again', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(router: router, providerOverrides: _appOverrides()),
    );
    await tester.pumpAndSettle();

    final card = find.byType(AnimeCoverSource);
    expect(card, findsOneWidget);
    final cardRect = tester.getRect(card);

    await tester.tap(find.text(_anime.title).first);
    // The frame the page is pushed on: the flight is measured at the end of it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final early = tester.getRect(find.byKey(animeCoverFlightKey));
    await tester.pump(const Duration(milliseconds: 60));
    final later = tester.getRect(find.byKey(animeCoverFlightKey));

    // The picture is in the air — that is the whole point of it being a Hero
    // rather than a page transition, and it is the part the shell's navigator
    // is capable of swallowing — and it is on its way: bigger than the tile it
    // left, closer to the poster it is landing on than it was.
    expect(early.width, greaterThanOrEqualTo(cardRect.width));
    expect(later.width, greaterThan(early.width));

    await tester.pumpAndSettle();
    expect(find.byKey(animeCoverFlightKey), findsNothing);
    expect(find.byType(AnimeDetailPage), findsOneWidget);

    final poster = tester.getRect(find.byType(AnimeCoverDestination));
    expect(later.width, lessThan(poster.width));
    expect(
      (poster.width - later.width).abs(),
      lessThan((poster.width - early.width).abs()),
    );

    // The way back is the same picture, home: the app's own back button starts
    // it, and a back gesture would take the same road.
    await tester.tap(find.text('返回'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final homewardEarly = tester.getRect(find.byKey(animeCoverFlightKey));
    await tester.pump(const Duration(milliseconds: 60));
    final homewardLater = tester.getRect(find.byKey(animeCoverFlightKey));
    expect(homewardLater.width, lessThan(homewardEarly.width));

    await tester.pumpAndSettle();
    expect(find.byKey(animeCoverFlightKey), findsNothing);
    expect(find.byType(AnimeDetailPage), findsNothing);
    // Landed on the card it left, in the frame it left.
    expect(tester.getRect(find.byType(AnimeCoverSource)), cardRect);
  });

  testWidgets('the page leaves as one piece, with nothing left standing', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(router: router, providerOverrides: _appOverrides()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_anime.title).first);
    await tester.pumpAndSettle();

    final page = find.byType(AnimeDetailPage);
    final poster = find.byType(AnimeCoverDestination);
    final back = find.text('返回');
    final words = find.descendant(of: page, matching: find.text(_anime.title));
    final posterInPlace = tester.getRect(poster);
    final backInPlace = tester.getRect(back);
    final wordsInPlace = tester.getRect(words).top;

    await tester.tap(back);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    // The frame the picture was in, and the way out of the page, go down with
    // the page's own words. A piece that held its place here would be left
    // hanging over the list it was opened from — a poster frame with nothing in
    // it — and taken away in a single frame when the route is removed, which a
    // reader sees as the screen flashing.
    final drop = tester.getRect(poster).top - posterInPlace.top;
    expect(drop, greaterThan(0));
    expect(tester.getRect(back).top - backInPlace.top, closeTo(drop, 0.5));
    expect(tester.getRect(words).top - wordsInPlace, closeTo(drop, 0.5));

    await tester.pumpAndSettle();
    expect(find.byType(AnimeDetailPage), findsNothing);
  });

  testWidgets('the picture travels in a straight line, at one pace', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(router: router, providerOverrides: _appOverrides()),
    );
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byType(AnimeCoverSource)).center;
    await tester.tap(find.text(_anime.title).first);
    await tester.pump();

    // A quarter of the way through, a quarter of the way across: one pace, and
    // no leaning off the line between the two boxes — which is all a reader sees
    // of a picture they tapped crossing to the frame it belongs in. The first
    // frame of the flight belongs to the flight's own machinery, which measures
    // the frame it is landing in again on every tick, so the picture is read
    // from the frame after it.
    const tick = Duration(milliseconds: 30);
    await tester.pump(tick);
    await tester.pump(tick);
    final quarter = tester.getRect(find.byKey(animeCoverFlightKey)).center;
    await tester.pump(tick * 2);
    final half = tester.getRect(find.byKey(animeCoverFlightKey)).center;
    await tester.pump(tick * 2);
    final threeQuarters = tester
        .getRect(find.byKey(animeCoverFlightKey))
        .center;

    await tester.pumpAndSettle();
    final poster = tester.getRect(find.byType(AnimeCoverDestination)).center;
    final way = poster - card;

    expect(half.dx, closeTo(card.dx + way.dx / 2, 0.5));
    expect(half.dy, closeTo(card.dy + way.dy / 2, 0.5));
    for (final (part, point) in <(double, Offset)>[
      (0.25, quarter),
      (0.5, half),
      (0.75, threeQuarters),
    ]) {
      expect(
        (point - card).distance,
        closeTo(way.distance * part, 0.5),
        reason: 'the picture at $part of the way across',
      );
      expect(
        _offLine(point, from: card, to: poster).abs(),
        lessThan(0.5),
        reason: 'the picture at $part of the way across',
      );
    }
  });

  testWidgets('the page comes up from below, around the frame of the picture', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(router: router, providerOverrides: _appOverrides()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_anime.title).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final page = find.byType(AnimeDetailPage);
    final poster = find.byType(AnimeCoverDestination);
    final canvas = find.descendant(
      of: page,
      matching: find.byType(MioBackdrop),
    );
    final title = find.descendant(of: page, matching: find.text(_anime.title));
    final frameEarly = tester.getRect(poster);
    final canvasEarly = tester.getRect(canvas);
    final titleEarly = tester.getRect(title).top;

    // The page is still on its way up: nothing of it is on screen yet but the
    // frame the picture is heading for, and the list the reader tapped in is
    // what they are looking at.
    expect(canvasEarly.top, greaterThan(0));
    expect(
      titleEarly,
      greaterThan(MediaQuery.sizeOf(tester.element(page)).height / 2),
    );

    await tester.pump(const Duration(milliseconds: 60));
    expect(
      tester.getRect(canvas).top,
      lessThan(canvasEarly.top),
      reason: 'the canvas keeps coming up',
    );
    expect(
      tester.getRect(title).top,
      lessThan(titleEarly),
      reason: 'the words come up with it',
    );
    expect(
      tester.getRect(poster),
      frameEarly,
      reason: 'the frame the picture lands in does not move',
    );

    await tester.pumpAndSettle();
    expect(tester.getRect(poster), frameEarly);
    expect(tester.getRect(canvas).top, 0);
    expect(tester.getRect(title).top, lessThan(titleEarly));
  });

  testWidgets('the page does not arrive by fading', (tester) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(router: router, providerOverrides: _appOverrides()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_anime.title).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // A page that came in at half strength would be a list and a page drawn over
    // each other, and a reader is owed one picture at a time: the work they
    // tapped stays whole while the page about it comes up under it.
    final page = find.byType(AnimeDetailPage);
    expect(
      find.ancestor(of: page, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(
      find.ancestor(of: page, matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('the card stands in for the copy while it is away', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(router: router, providerOverrides: _appOverrides()),
    );
    await tester.pumpAndSettle();
    expect(_cardPictureHidden(tester), isFalse);

    await tester.tap(find.text(_anime.title).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // One picture on screen, not two: the card's own is held back for as long
    // as the copy is in the air, which is what makes the flight read as the
    // same picture moving rather than a second one appearing.
    expect(_cardPictureHidden(tester), isTrue);

    // A settled page is opaque, and the list it was opened over leaves the
    // stage behind it — so the way back is the only place the card has to be
    // whole again, and the picture has to be gone from here by then.
    await tester.pumpAndSettle();
    expect(find.byType(AnimeDetailPage), findsOneWidget);
    expect(find.byType(AnimeCoverSource), findsNothing);

    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(find.byType(AnimeCoverSource), findsOneWidget);
    expect(_cardPictureHidden(tester), isFalse);
  });

  testWidgets('a reader who turned animations off still gets the page whole', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final router = createMioAniRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MioAniRoot(router: router, providerOverrides: _appOverrides()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(_anime.title).first);
    await tester.pumpAndSettle();

    // The transition is over before it starts, so there is no flight to hand a
    // picture to: the poster is the poster, rather than standing in for a copy
    // that is never coming.
    expect(find.byType(AnimeDetailPage), findsOneWidget);
    expect(find.byKey(animeCoverFlightKey), findsNothing);
    expect(_posterHidden(tester), isFalse);
  });

  testWidgets('a Hero tag says which list the picture left', (tester) async {
    final id = AnimeSourceId.fromBangumiId(7);
    final home = animeCoverTag(place: AnimeCoverPlace.homeSeason, id: id);
    final feed = animeCoverTag(place: AnimeCoverPlace.homeExplore, id: id);

    // The same work in two lists is two pictures on screen, and only the one
    // the reader tapped may fly.
    expect(home, isNot(feed));
    expect(animeCoverTag(place: AnimeCoverPlace.homeSeason, id: id), home);
  });

  testWidgets('the poster keeps the cover its page was built with', (
    tester,
  ) async {
    final first = AnimeCoverFlight.tile(
      anime: _anime,
      place: AnimeCoverPlace.homeSeason,
    );
    final second = AnimeCoverFlight.tile(
      anime: _anime,
      place: AnimeCoverPlace.homeExplore,
    );

    await tester.pumpWidget(_posterHost(first, label: 'a'));
    expect(_posterTag(tester), first.tag);

    // A reader opening a related work from this page leaves a cover for that
    // work behind: this page's poster must not move to it.
    await tester.pumpWidget(_posterHost(second, label: 'b'));
    expect(_posterTag(tester), first.tag);
  });

  testWidgets('a work with no cover has nothing to fly', (tester) async {
    final coverless = AnimeCoverFlight.tile(
      anime: AnimeSummary(
        id: AnimeSourceId.fromBangumiId(9),
        title: '没有封面的动画',
        sourceTitle: '',
      ),
      place: AnimeCoverPlace.homeSeason,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                SizedBox(
                  width: 100,
                  height: 150,
                  child: AnimeCoverSource(
                    flight: coverless,
                    semanticLabel: '没有封面的动画 海报',
                  ),
                ),
                AnimeCoverDestination(
                  animeId: coverless.animeId,
                  child: const SizedBox(width: 180, height: 270),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Hero), findsNothing);
    expect(find.byType(AnimeCoverSource), findsOneWidget);
  });
}

/// Whether the card's own picture is standing in for the copy in the air.
bool _cardPictureHidden(WidgetTester tester) {
  return _offstageWithin(tester, find.byType(AnimeCoverSource));
}

/// Whether the poster is standing in for a copy in the air.
bool _posterHidden(WidgetTester tester) {
  return _offstageWithin(tester, find.byType(AnimeCoverDestination));
}

/// The picture a hero is holding back, read out of the placeholder [Hero]
/// leaves in its place while the copy is flying.
bool _offstageWithin(WidgetTester tester, Finder hero) {
  final offstage = find.descendant(of: hero, matching: find.byType(Offstage));
  return tester.widget<Offstage>(offstage).offstage;
}

Object _posterTag(WidgetTester tester) {
  return tester.widget<Hero>(find.byType(Hero)).tag;
}

/// How far [point] stands off the line from [from] to [to], in logical pixels:
/// zero is on the line, and the sign says which side.
double _offLine(Offset point, {required Offset from, required Offset to}) {
  final way = to - from;
  final length = way.distance;
  if (length == 0) return 0;
  final off = point - from;
  return (way.dx * off.dy - way.dy * off.dx) / length;
}

Widget _posterHost(AnimeCoverFlight flight, {required String label}) {
  return ProviderScope(
    overrides: [
      animeCoverFlightStoreProvider.overrideWithValue(
        AnimeCoverFlightStore()..begin(flight),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AnimeCoverDestination(
          animeId: flight.animeId,
          radius: MioRadii.md,
          child: SizedBox(width: 180, height: 270, child: Text(label)),
        ),
      ),
    ),
  );
}

final _anime = AnimeSummary(
  id: AnimeSourceId.fromBangumiId(1),
  title: '测试动画',
  sourceTitle: 'Test Anime',
  imageUrl: Uri.parse('https://lain.bgm.tv/pic/cover/l/test.jpg'),
  thumbnailUrl: Uri.parse('https://lain.bgm.tv/pic/cover/m/test.jpg'),
  score: 8.2,
);

final _detail = AnimeDetail(
  id: _anime.id,
  title: _anime.title,
  sourceTitle: _anime.sourceTitle,
  imageUrl: _anime.imageUrl,
  thumbnailUrl: _anime.thumbnailUrl,
  score: _anime.score,
  summary: '用于确定性测试的动画详情。',
);

final _posterBytes = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
);

/// The app as a reader meets it: the shell's branch navigator, the detail page
/// opened over it on the root navigator, and a cover with bytes on hand.
///
/// Fresh per test: a stream can only be listened to once, and a second test
/// sharing one with the first would be reading a page that failed rather than
/// the page it tapped.
List<Override> _appOverrides() {
  return <Override>[
    homeRepositoryProvider.overrideWithValue(
      FakeHomeRepository(
        watchFactory: () => Stream.value(
          testHomeSnapshot(
            catalog: HomeSection<HomeCatalogContent>.ready(
              value: HomeCatalogContent(
                hero: const <AnimeSummary>[],
                trending: <AnimeSummary>[_anime],
              ),
            ),
          ),
        ),
      ),
    ),
    catalogRepositoryProvider.overrideWithValue(
      FakeCatalogRepository(detail: Stream.value(testSnapshot(_detail))),
    ),
    imageMemoryCacheProvider.overrideWithValue(
      ImageMemoryCache()
        ..store(_anime.imageUrl!, _posterBytes)
        ..store(_anime.thumbnailUrl!, _posterBytes),
    ),
    imageBytesProvider(
      _anime.imageUrl!,
    ).overrideWith((ref) async => _posterBytes),
    imageBytesProvider(
      _anime.thumbnailUrl!,
    ).overrideWith((ref) async => _posterBytes),
  ];
}
