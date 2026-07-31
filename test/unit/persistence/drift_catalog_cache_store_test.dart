import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/data/drift_catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

import '../../support/fake_catalog_repository.dart';

void main() {
  late CatalogDatabase database;
  late DriftCatalogCacheStore store;
  final fetchedAt = DateTime.utc(2026, 7, 31, 8);
  final staleAt = DateTime.utc(2026, 7, 31, 8, 30);
  final expiresAt = DateTime.utc(2026, 8, 7, 8);

  setUp(() {
    database = CatalogDatabase(NativeDatabase.memory());
    store = DriftCatalogCacheStore(database: database);
  });

  tearDown(() => database.close());

  test('round-trips structured catalog and detail cache records', () async {
    await store.writeCatalog(
      CatalogCacheRecord(
        value: <AnimeSummary>[testAnimeSummary],
        fetchedAt: fetchedAt,
        staleAt: staleAt,
        expiresAt: expiresAt,
      ),
    );
    await store.writeDetail(
      testAnimeId,
      CatalogCacheRecord(
        value: testAnimeDetail,
        fetchedAt: fetchedAt,
        staleAt: staleAt,
        expiresAt: expiresAt,
      ),
    );

    final catalog = await store.readCatalog();
    final detail = await store.readDetail(testAnimeId);
    expect(catalog?.value, <AnimeSummary>[testAnimeSummary]);
    expect(catalog?.fetchedAt, fetchedAt);
    expect(catalog?.staleAt, staleAt);
    expect(catalog?.expiresAt, expiresAt);
    expect(detail?.value.id, testAnimeDetail.id);
    expect(detail?.value.title, testAnimeDetail.title);
    expect(detail?.value.episodes, testAnimeDetail.episodes);
    expect(detail?.value.tags, testAnimeDetail.tags);
  });

  test('removes only the corrupted cache key', () async {
    await store.writeDetail(
      testAnimeId,
      CatalogCacheRecord(
        value: testAnimeDetail,
        fetchedAt: fetchedAt,
        staleAt: staleAt,
        expiresAt: expiresAt,
      ),
    );
    await database.writeCacheEntry(
      StructuredCacheEntriesCompanion.insert(
        cacheKey: 'catalog:bangumi:calendar:v1',
        payload: '{broken',
        fetchedAt: fetchedAt.millisecondsSinceEpoch,
        staleAt: staleAt.millisecondsSinceEpoch,
        expiresAt: expiresAt.millisecondsSinceEpoch,
      ),
    );

    expect(await store.readCatalog(), isNull);
    expect(await store.readDetail(testAnimeId), isNotNull);
    expect(
      await database.readCacheEntry('catalog:bangumi:calendar:v1'),
      isNull,
    );
  });
}
