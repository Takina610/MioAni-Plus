import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_detail_providers.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_preview_store.dart';
import 'package:mio_ani/src/features/anime_detail/data/bangumi_anime_sections_source.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_page.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_sections.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';

import '../../support/fake_catalog_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('invalid IDs render not found without calling the repository', (
    tester,
  ) async {
    final repository = FakeCatalogRepository();

    await _pumpPage(tester, repository, 'invalid');
    await tester.pump();

    expect(find.text('页面不存在'), findsOneWidget);
    expect(find.textContaining('无法识别动画 ID'), findsOneWidget);
    expect(repository.detailCalls, 0);
  });

  testWidgets('AniList IDs show a placeholder without calling Bangumi', (
    tester,
  ) async {
    final repository = FakeCatalogRepository();

    await _pumpPage(tester, repository, 'anilist-12345');
    await tester.pump();

    expect(find.text('页面不存在'), findsOneWidget);
    expect(find.textContaining('后续版本提供'), findsOneWidget);
    expect(repository.detailCalls, 0);
  });

  testWidgets('renders a valid detail and stale state at 200% text scale', (
    tester,
  ) async {
    await configureTestViewport(
      tester,
      size: const Size(390, 844),
      textScaleFactor: 2,
    );
    final repository = FakeCatalogRepository(
      detailFactory: () =>
          Stream.value(testSnapshot(testAnimeDetail, isStale: true)),
    );

    await _pumpPage(tester, repository, 'bgm-1');
    await tester.pumpAndSettle();

    // The head: where the work came from, what it is called, and the opening of
    // its summary.
    expect(find.text('BANGUMI · 1'), findsOneWidget);
    expect(find.text('测试动画'), findsOneWidget);
    expect(find.text('Test Anime'), findsOneWidget);
    // The opening of the summary is in the head and the whole of it is in the
    // overview under it, which is how the reference draws the two.
    expect(find.textContaining('用于确定性测试的动画详情。'), findsWidgets);
    // The record: one line of it on a phone, holding the numbers worth knowing
    // without opening anything, and the board itself behind that line.
    expect(find.text('8.2'), findsWidgets);
    expect(find.text('作品资料'), findsOneWidget);
    expect(find.text('#100'), findsWidgets);
    // A stale cache is drawn exactly like a fresh one: the reader is not told
    // which they are looking at, because it changes nothing about the page.
    expect(find.textContaining('缓存'), findsNothing);

    await tester.tap(find.text('作品资料'));
    await tester.pumpAndSettle();

    // The facts that only the subject request carries, in the board they land
    // in, at the largest text this app is asked to draw.
    expect(find.text('测试制作'), findsOneWidget);
    expect(find.text('测试原作'), findsOneWidget);
    expect(find.text('24 分钟'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders loading and not-found source states', (tester) async {
    final controller = StreamController<CatalogSnapshot<AnimeDetail>>();
    addTearDown(controller.close);
    final loadingRepository = FakeCatalogRepository(detail: controller.stream);
    await _pumpPage(tester, loadingRepository, 'bgm-1');
    // Nothing has seen this anime yet, so the page draws its own shape: the
    // poster box, the text blocks and the section that will land under them,
    // and no word about it — content that is still coming says so by its shape,
    // not by a banner or a spinner.
    expect(find.byType(MioPlaceholder), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('正在加载'), findsNothing);

    final missingRepository = FakeCatalogRepository(
      detailFactory: () =>
          Stream<CatalogSnapshot<AnimeDetail>>.error(const NotFoundFailure()),
    );
    await _pumpPage(tester, missingRepository, 'bgm-1');
    await tester.pumpAndSettle();
    expect(find.textContaining('Bangumi 中不存在'), findsOneWidget);
  });

  testWidgets('draws the head a list left behind before the detail arrives', (
    tester,
  ) async {
    final controller = StreamController<CatalogSnapshot<AnimeDetail>>();
    addTearDown(controller.close);

    await _pumpPage(
      tester,
      FakeCatalogRepository(detail: controller.stream),
      'bgm-1',
      preview: testAnimeSummary,
    );

    // The tap back at the list is what fills this in: the cover, the title, the
    // opening of the summary and the score are on screen from the first frame,
    // and nothing claims the pieces the subject has not answered with yet.
    expect(find.text('测试动画'), findsWidgets);
    expect(find.text('8.2'), findsWidgets);
    expect(find.text('制作'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('正在加载'), findsNothing);

    controller.add(testSnapshot(testAnimeDetail));
    await tester.pumpAndSettle();

    // The studio and the adapted work are only ever in the subject's infobox,
    // so their arrival is the arrival of the whole detail.
    expect(find.text('制作'), findsOneWidget);
    expect(find.text('测试制作'), findsOneWidget);
    expect(find.text('24 分钟'), findsWidgets);
    // The record is a column on this window, so its score card is open.
    expect(find.text('#100 排名'), findsOneWidget);
    expect(find.byType(MioPlaceholder), findsNothing);
  });

  testWidgets('a stale detail whose refresh failed is still just the page', (
    tester,
  ) async {
    final repository = FakeCatalogRepository(
      detailFactory: () => Stream.value(
        testSnapshot(
          testAnimeDetail,
          isStale: true,
          refreshFailure: const OfflineFailure(),
        ),
      ),
    );

    await _pumpPage(tester, repository, 'bgm-1');
    await tester.pumpAndSettle();

    // The work is on screen and the page says nothing about the request that
    // could not be made. A reader who came for this anime has it; a banner
    // about a failed background refresh would only be something to worry about.
    expect(find.text('测试动画'), findsOneWidget);
    expect(find.textContaining('缓存'), findsNothing);
    expect(find.textContaining('当前处于离线状态'), findsNothing);
    expect(find.text('重试更新'), findsNothing);

    // And nothing asked again on its own: a page that offers a retry offers it
    // because the reader asked, not because the app decided to.
    expect(repository.detailCalls, 1);
  });

  testWidgets('the record opens on a phone and holds the work tags', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));

    await _pumpPage(tester, FakeCatalogRepository(), 'bgm-1');
    await tester.pumpAndSettle();

    // A phone gets one line of the record rather than the whole board: a board
    // a reader has to scroll past before reaching the sections is a board they
    // scroll past.
    expect(find.text('作品资料'), findsOneWidget);
    expect(find.text('测试制作'), findsNothing);

    await tester.tap(find.text('作品资料'));
    await tester.pumpAndSettle();

    expect(find.text('制作'), findsOneWidget);
    expect(find.text('测试制作'), findsOneWidget);
    expect(find.text('原作'), findsOneWidget);
    expect(find.text('日常'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the record is a rail beside the sections on a wide window', (
    tester,
  ) async {
    await configureTestViewport(
      tester,
      size: const Size(900, 1200),
      textScaleFactor: 2,
    );

    await _pumpPage(tester, FakeCatalogRepository(), 'bgm-1');
    await tester.pumpAndSettle();

    // Two columns: the record is a column of facts that is simply there, and
    // the tab bar stands beside it rather than over it.
    expect(find.text('作品资料'), findsNothing);
    expect(find.text('格式'), findsOneWidget);
    expect(find.text('测试制作'), findsOneWidget);
    final record = tester.getRect(find.text('格式'));
    final tabs = tester.getRect(find.text('概览'));
    expect(record.right, lessThan(tabs.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a section is read when its tab is opened, not before', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final sections = FakeSectionsSource();

    await _pumpPage(
      tester,
      FakeCatalogRepository(),
      'bgm-1',
      sections: sections,
    );
    await tester.pumpAndSettle();

    // The page is about a work: a reader who came for its summary is not made
    // to wait on its cast list, so nothing is read for the other three tabs.
    expect(sections.relationCalls, 0);
    expect(sections.characterCalls, 0);
    expect(sections.staffCalls, 0);
    expect(find.byType(AnimeDetailSections), findsOneWidget);
    expect(find.text('概览'), findsOneWidget);

    await tester.tap(find.text('关联作品'));
    await tester.pumpAndSettle();

    expect(sections.relationCalls, 1);
    expect(sections.characterCalls, 0);
    expect(find.text('前作'), findsOneWidget);

    await tester.tap(find.text('角色声优'));
    await tester.pumpAndSettle();

    expect(sections.characterCalls, 1);
    expect(find.text('主角'), findsOneWidget);
    expect(find.text('CV · 测试声优'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card grids hold together at 200% text scale', (
    tester,
  ) async {
    await configureTestViewport(
      tester,
      size: const Size(390, 844),
      textScaleFactor: 2,
    );
    final sections = FakeSectionsSource();

    await _pumpPage(
      tester,
      FakeCatalogRepository(),
      'bgm-1',
      sections: sections,
    );
    await tester.pumpAndSettle();

    // Cards are sized from the text they hold at the reader's own text size:
    // a card that measured its text at the default size and drew it at this
    // one would have its content hanging out of it.
    for (final tab in <String>['关联作品', '角色声优', '制作人员']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }

    expect(sections.relationCalls, 1);
    expect(sections.characterCalls, 1);
    expect(sections.staffCalls, 1);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  FakeCatalogRepository repository,
  String id, {
  AnimeSummary? preview,
  AnimeDetailSectionsSource? sections,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(repository),
        // Opening a tab is what reads its section; anything that reaches the
        // network in a test is a section that started reading on its own.
        animeDetailSectionsSourceProvider.overrideWithValue(
          sections ?? FakeSectionsSource(unreachable: true),
        ),
        // What a list leaves behind when a reader taps through it.
        if (preview != null)
          animePreviewStoreProvider.overrideWith((ref) {
            return AnimePreviewStore()..remember(preview);
          }),
      ],
      retry: disableProviderRetry,
      child: MaterialApp(home: AnimeDetailPage(sourceId: id)),
    ),
  );
}

/// The three sections the detail page reads, with each read counted: what a
/// test is checking is usually not the answer but who was asked for it, and
/// when.
final class FakeSectionsSource implements AnimeDetailSectionsSource {
  FakeSectionsSource({this.unreachable = false});

  /// Whether a read is a mistake: a page that reads a section nobody opened has
  /// no business reaching the source at all.
  final bool unreachable;

  int relationCalls = 0;
  int characterCalls = 0;
  int staffCalls = 0;

  @override
  Future<List<AnimeRelation>> fetchRelations(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  }) async {
    relationCalls += 1;
    if (unreachable) throw const OfflineFailure();
    return <AnimeRelation>[
      AnimeRelation(
        animeId: AnimeSourceId.fromBangumiId(9),
        title: '测试关联作品',
        relation: '前作',
      ),
    ];
  }

  @override
  Future<List<AnimeCharacterCredit>> fetchCharacters(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  }) async {
    characterCalls += 1;
    if (unreachable) throw const OfflineFailure();
    return <AnimeCharacterCredit>[
      AnimeCharacterCredit(
        characterId: PersonSourceId.fromBangumiCharacter(21),
        name: '测试角色',
        role: '主角',
        voiceActorName: '测试声优',
        voiceActorId: PersonSourceId.fromBangumiPerson(31),
      ),
    ];
  }

  @override
  Future<List<AnimeStaffCredit>> fetchStaff(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  }) async {
    staffCalls += 1;
    if (unreachable) throw const OfflineFailure();
    return <AnimeStaffCredit>[
      AnimeStaffCredit(
        personId: PersonSourceId.fromBangumiPerson(41),
        name: '测试人员',
        role: '导演',
      ),
    ];
  }
}
