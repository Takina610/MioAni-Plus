import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/drift_home_cache_store.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

void main() {
  late MioAniDatabase database;
  late DriftHomeCacheStore store;
  final fetchedAt = DateTime.utc(2026, 8, 4, 12);

  setUp(() {
    database = MioAniDatabase(NativeDatabase.memory());
    store = DriftHomeCacheStore(database: database);
  });

  tearDown(() => database.close());

  test('round-trips the explore feed as far as it was scrolled', () async {
    await store.writeExplore(
      'home:explore:v2',
      CatalogCacheRecord<HomeExplorePage>(
        value: HomeExplorePage(
          items: <AnimeSummary>[_anime(11, '甲'), _anime(12, '乙')],
          page: 3,
          hasMore: true,
          source: AnimeSource.bangumi,
        ),
        fetchedAt: fetchedAt,
        staleAt: fetchedAt.add(const Duration(minutes: 45)),
        expiresAt: fetchedAt.add(const Duration(days: 7)),
      ),
    );

    final record = await store.readExplore('home:explore:v2');

    expect(record, isNotNull);
    expect(record!.value.page, 3);
    expect(record.value.hasMore, isTrue);
    expect(record.value.items.map((item) => item.title), <String>['甲', '乙']);
    expect(record.value.source, AnimeSource.bangumi);
    expect(record.value.items.first.id, AnimeSourceId.fromAniListId(11));
    expect(record.fetchedAt, fetchedAt);
  });

  test('round-trips the season sections', () async {
    await store.writeSections(
      'home:sections:2026-summer:v2',
      CatalogCacheRecord<HomeCatalogContent>(
        value: HomeCatalogContent(
          hero: <AnimeSummary>[_anime(1, '首推')],
          trending: <AnimeSummary>[_anime(2, '海报')],
        ),
        fetchedAt: fetchedAt,
        staleAt: fetchedAt.add(const Duration(minutes: 45)),
        expiresAt: fetchedAt.add(const Duration(days: 7)),
      ),
    );

    final record = await store.readSections('home:sections:2026-summer:v2');

    expect(record!.value.hero.single.title, '首推');
    expect(record.value.trending.single.title, '海报');
  });

  test(
    'drops a malformed explore record instead of failing the read',
    () async {
      await database.writeCacheEntry(
        StructuredCacheEntriesCompanion.insert(
          cacheKey: 'home:explore:v2',
          payload: '{"page": 1}',
          fetchedAt: fetchedAt.millisecondsSinceEpoch,
          staleAt: fetchedAt.millisecondsSinceEpoch,
          expiresAt: fetchedAt.millisecondsSinceEpoch,
          category: const Value('home'),
          byteSize: const Value(10),
          lastAccessedAt: Value(fetchedAt.millisecondsSinceEpoch),
        ),
      );

      expect(await store.readExplore('home:explore:v2'), isNull);
      expect(await database.readCacheEntry('home:explore:v1'), isNull);
    },
  );
}

AnimeSummary _anime(int id, String title) {
  return AnimeSummary(
    id: AnimeSourceId.fromAniListId(id),
    title: title,
    sourceTitle: '',
  );
}
