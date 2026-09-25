import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_detail_providers.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_meta_board.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_page.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/translation/application/translation_providers.dart';
import 'package:mio_ani/src/features/translation/data/translation_cache_store.dart';
import 'package:mio_ani/src/features/translation/data/translation_source.dart';

import '../../support/fake_catalog_repository.dart';
import '../../support/test_viewport.dart';
import '../anime_detail/anime_detail_page_test.dart' show FakeSectionsSource;

void main() {
  testWidgets('a work the source named only in Japanese is offered', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    await _pump(tester, _japaneseAnime);
    await tester.pumpAndSettle();

    // The header carries the offer for the title, the overview for the
    // synopsis: both are on screen from the first frame, and both are in a
    // language this reader does not read.
    expect(find.text('翻译标题'), findsOneWidget);
    expect(find.text('翻译简介'), findsOneWidget);
  });

  testWidgets('translating a title lands under it, and hides again', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final source = _FakeSource(<String, String>{'ヤニねこ': '吸烟猫'});

    await _pump(tester, _japaneseAnime, source: source);
    await tester.pumpAndSettle();
    await tester.tap(find.text('翻译标题'));
    await tester.pumpAndSettle();

    expect(find.text('吸烟猫'), findsOneWidget);
    expect(find.text('隐藏翻译'), findsOneWidget);
    // The original stays on the page: the reader asked what it says, not for it
    // to be replaced.
    expect(find.text('ヤニねこ'), findsWidgets);
    expect(source.calls, <String>['ja:ヤニねこ']);

    await tester.tap(find.text('隐藏翻译'));
    await tester.pumpAndSettle();

    expect(find.text('吸烟猫'), findsNothing);
    expect(find.text('翻译标题'), findsOneWidget);
  });

  testWidgets('a page the source wrote in Chinese offers nothing', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    // The fixture's title, synopsis and tags are all Chinese: there is nothing
    // on this page a translation could add, so nothing is offered.
    await _pump(tester, testAnimeDetail);
    await tester.pumpAndSettle();

    expect(find.text('翻译标题'), findsNothing);
    expect(find.text('翻译简介'), findsNothing);
    expect(find.text('翻译标签'), findsNothing);
  });

  testWidgets('a Chinese work in shared characters offers nothing', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    // The case the characters alone cannot settle: `万古至尊：李云霄传` is
    // written in exactly the script a Japanese title is, and only the source
    // saying where the work is from tells them apart.
    await _pump(tester, _chineseAnime);
    await tester.pumpAndSettle();
    await tester.tap(find.text('作品资料'));
    await tester.pumpAndSettle();

    expect(find.text('翻译标题'), findsNothing);
    expect(find.text('翻译简介'), findsNothing);
    expect(find.text('翻译标签'), findsNothing);
    expect(find.textContaining('翻译'), findsNothing);
  });

  testWidgets('a Japanese work the source named in Chinese offers nothing', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    // 幼女戦記Ⅱ is a Japanese title in kanji alone, and the source published a
    // Chinese name for it. The page shows the Chinese name: there is nothing to
    // translate, and the original underneath is not offered either — the reader
    // has already been given the Chinese.
    await _pump(tester, _chineseNamedAnime);
    await tester.pumpAndSettle();

    expect(find.text('幼女战记 第二季'), findsOneWidget);
    expect(find.text('幼女戦記Ⅱ'), findsOneWidget);
    expect(find.text('翻译标题'), findsNothing);
    expect(find.text('翻译简介'), findsNothing);
  });

  testWidgets('a build with no key offers nothing at all', (tester) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    // No credentials in the build is not a broken feature, it is a feature that
    // was not asked for: the page draws exactly as it would without one.
    await _pump(
      tester,
      _japaneseAnime,
      source: _FakeSource(<String, String>{'ヤニねこ': '吸烟猫'}),
      configured: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('翻译标题'), findsNothing);
    expect(find.text('翻译简介'), findsNothing);
    expect(find.textContaining('翻译'), findsNothing);
  });

  testWidgets('a translation that failed says why and can be retried', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final source = _FakeSource(
      <String, String>{'ヤニねこ': '吸烟猫'},
      failures: <String, TranslationFailure>{
        'ヤニねこ': const TranslationFailure.rejectedKey(),
      },
    );

    await _pump(tester, _japaneseAnime, source: source);
    await tester.pumpAndSettle();
    await tester.tap(find.text('翻译标题'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SecretId'), findsOneWidget);
    expect(find.text('重试'), findsWidgets);

    // The service was only pretending to refuse: the second ask gets through.
    source.failures.clear();
    await tester.tap(find.text('重试').first);
    await tester.pumpAndSettle();

    expect(find.text('吸烟猫'), findsOneWidget);
    expect(find.textContaining('SecretId'), findsNothing);
  });

  testWidgets('the record and its offer hold together at 200% text scale', (
    tester,
  ) async {
    // A wide window puts the record in the rail beside the sections, where it
    // is about 200 logical pixels wide — the narrowest place the offer is ever
    // made — and the text scale is as large as the app is asked to draw it. The
    // label and the button have to share that column without either being
    // pushed out of it.
    await configureTestViewport(
      tester,
      size: const Size(900, 1400),
      textScaleFactor: 2,
    );

    await _pump(tester, _japaneseAnime);
    await tester.pumpAndSettle();

    expect(find.text('标签'), findsOneWidget);
    expect(find.text('翻译标签'), findsOneWidget);
    // Both are drawn *inside* the rail, not merely without an exception: an
    // overflowing row lays its children out past the edge of the box they were
    // given, and a reader sees the button half off the page.
    final rail = tester.getRect(find.byType(AnimeDetailMetaBoard));
    expect(
      tester.getRect(find.text('标签')).right,
      lessThanOrEqualTo(rail.right),
    );
    expect(
      tester.getRect(find.text('翻译标签')).right,
      lessThanOrEqualTo(rail.right),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a synopsis translates into the section that holds it', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final source = _FakeSource(<String, String>{
      '地球大好き！きっくんの日常。': '最喜欢地球！小鸡的日常。',
    });

    await _pump(tester, _japaneseAnime, source: source);
    await tester.pumpAndSettle();
    await tester.tap(find.text('翻译简介'));
    await tester.pumpAndSettle();

    expect(find.text('最喜欢地球！小鸡的日常。'), findsOneWidget);
    expect(source.calls, <String>['ja:地球大好き！きっくんの日常。']);
    expect(tester.takeException(), isNull);
  });
}

/// A work of the shape this feature exists for: the source never filled in a
/// Chinese name for it, so its title and its synopsis are the Japanese it
/// published.
final _japaneseAnime = AnimeDetail(
  id: testAnimeId,
  title: 'ヤニねこ',
  sourceTitle: 'ヤニねこ',
  score: 7.3,
  airDate: DateTime.utc(2026, 7, 2),
  summary: '地球大好き！きっくんの日常。',
  episodes: 12,
  rank: 1319,
  format: 'TV',
  origin: WorkOrigin.japan,
  tags: const <String>['ギャグ', '日常'],
);

/// A Japanese work the source did give a Chinese name to: the page shows the
/// Chinese name, so there is nothing on it to translate.
final _chineseNamedAnime = AnimeDetail(
  id: testAnimeId,
  title: '幼女战记 第二季',
  sourceTitle: '幼女戦記Ⅱ',
  score: 7.5,
  airDate: DateTime.utc(2026, 7, 1),
  summary: '在战场上驰骋的少女的故事。',
  episodes: 12,
  format: 'TV',
  origin: WorkOrigin.japan,
  tags: const <String>['战斗', '军事'],
);

/// A work the source files under China, written in characters Japanese shares.
/// Nothing on this page needs translating and the characters cannot say so.
final _chineseAnime = AnimeDetail(
  id: testAnimeId,
  title: '万古至尊：李云霄传',
  sourceTitle: '万古至尊：李云霄传',
  score: 6.1,
  airDate: DateTime.utc(2026, 7, 1),
  summary: '少年李云霄踏上修炼之路的故事。',
  episodes: 24,
  format: 'WEB',
  origin: WorkOrigin.china,
  tags: const <String>['玄幻', '小说改'],
);

Future<void> _pump(
  WidgetTester tester,
  AnimeDetail detail, {
  TranslationSource? source,
  bool configured = true,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          FakeCatalogRepository(
            detailFactory: () => Stream.value(testSnapshot(detail)),
          ),
        ),
        animeDetailSectionsSourceProvider.overrideWithValue(
          FakeSectionsSource(unreachable: true),
        ),
        translationSourceProvider.overrideWithValue(
          configured ? (source ?? _FakeSource(const <String, String>{})) : null,
        ),
        translationConfiguredProvider.overrideWithValue(configured),
        translationCacheStoreProvider.overrideWithValue(
          MemoryTranslationCacheStore(),
        ),
      ],
      retry: disableProviderRetry,
      child: MaterialApp(home: AnimeDetailPage(sourceId: detail.id.value)),
    ),
  );
}

final class _FakeSource implements TranslationSource {
  _FakeSource(this.translations, {Map<String, TranslationFailure>? failures})
    : failures = failures ?? <String, TranslationFailure>{};

  final Map<String, String> translations;
  final Map<String, TranslationFailure> failures;
  final List<String> calls = <String>[];

  @override
  Future<String> translate(
    String text, {
    required TranslationLanguage from,
  }) async {
    calls.add('${from.code}:$text');
    final failure = failures[text];
    if (failure != null) throw failure;
    return translations[text] ?? '译文：$text';
  }
}
