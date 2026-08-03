import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/data/drift_catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

import '../../support/fake_catalog_repository.dart';

void main() {
  late MioAniDatabase database;
  late DriftCatalogCacheStore store;
  final fetchedAt = DateTime.utc(2026, 7, 31, 8);
  final staleAt = DateTime.utc(2026, 7, 31, 8, 30);
  final expiresAt = DateTime.utc(2026, 8, 7, 8);

  setUp(() {
    database = MioAniDatabase(NativeDatabase.memory());
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

  test('migrates a version 1 cache row without rebuilding it', () async {
    await database.close();
    final legacyDatabase = MioAniDatabase(
      NativeDatabase.memory(
        setup: (rawDatabase) {
          rawDatabase
            ..execute('''
              CREATE TABLE structured_cache_entries (
                cache_key TEXT NOT NULL PRIMARY KEY,
                payload TEXT NOT NULL,
                fetched_at INTEGER NOT NULL,
                stale_at INTEGER NOT NULL,
                expires_at INTEGER NOT NULL
              )
            ''')
            ..execute(
              'INSERT INTO structured_cache_entries '
              '(cache_key, payload, fetched_at, stale_at, expires_at) '
              "VALUES ('legacy', '{\"value\":1}', 10, 20, 30)",
            )
            ..execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(legacyDatabase.close);

    final migrated = await legacyDatabase.readCacheEntry('legacy');

    expect(migrated, isNotNull);
    expect(migrated!.payload, '{"value":1}');
    expect(migrated.category, 'catalog');
    expect(migrated.byteSize, 11);
    expect(migrated.lastAccessedAt, 10);
    expect(legacyDatabase.schemaVersion, 2);
  });

  test(
    'rolls back a user transaction when a library invariant fails',
    () async {
      const identityId = 'identity:rollback';

      await expectLater(
        database.transaction(() async {
          await database
              .into(database.animeIdentities)
              .insert(
                AnimeIdentitiesCompanion.insert(
                  identityId: identityId,
                  createdAt: 10,
                  updatedAt: 10,
                ),
              );
          await database
              .into(database.libraryEntries)
              .insert(
                LibraryEntriesCompanion.insert(
                  identityId: identityId,
                  watched: const Value(-1),
                  updatedAt: 10,
                ),
              );
        }),
        throwsA(isA<Exception>()),
      );

      expect(await database.select(database.animeIdentities).get(), isEmpty);
      expect(await database.select(database.libraryEntries).get(), isEmpty);
    },
  );

  test('clears rebuildable cache without touching user data', () async {
    const identityId = 'identity:kept';
    await database
        .into(database.animeIdentities)
        .insert(
          AnimeIdentitiesCompanion.insert(
            identityId: identityId,
            createdAt: 10,
            updatedAt: 10,
          ),
        );
    await database.writeCacheEntry(
      StructuredCacheEntriesCompanion.insert(
        cacheKey: 'catalog:test',
        payload: '{}',
        fetchedAt: 10,
        staleAt: 20,
        expiresAt: 30,
        byteSize: const Value(2),
        lastAccessedAt: const Value(10),
      ),
    );
    await database
        .into(database.imageCacheEntries)
        .insert(
          ImageCacheEntriesCompanion.insert(
            imageUrl: 'https://lain.bgm.tv/pic/cover/test.jpg',
            storageKey: 'test-image',
            backend: 'native_file',
            byteSize: 100,
            fetchedAt: 10,
            staleAt: 20,
            expiresAt: 30,
            lastAccessedAt: 10,
          ),
        );

    await database.clearPublicCache();

    expect(
      await database.select(database.structuredCacheEntries).get(),
      isEmpty,
    );
    expect(await database.select(database.imageCacheEntries).get(), isEmpty);
    expect(
      await database.select(database.animeIdentities).getSingle(),
      isA<AnimeIdentity>().having(
        (row) => row.identityId,
        'identityId',
        identityId,
      ),
    );
  });

  test('persists image metadata through the domain store contract', () async {
    final metadataStore = database as ImageCacheMetadataStore;
    final uri = Uri.parse('https://lain.bgm.tv/pic/cover/metadata.jpg');

    await metadataStore.upsert(
      ImageCacheMetadata(
        uri: uri,
        storageKey: 'opaque-storage-key',
        backend: ImageCacheBackend.nativeFile,
        byteSize: 321,
        etag: '"image-v1"',
        lastModified: 'Wed, 30 Jul 2026 10:00:00 GMT',
        fetchedAt: DateTime.utc(2026, 7, 31, 8),
        staleAt: DateTime.utc(2026, 8, 30, 8),
        expiresAt: DateTime.utc(2026, 8, 30, 8),
        lastAccessedAt: DateTime.utc(2026, 7, 31, 8),
      ),
    );

    final row = await database.select(database.imageCacheEntries).getSingle();
    expect(row.imageUrl, uri.toString());
    expect(row.storageKey, 'opaque-storage-key');
    expect(row.backend, 'native_file');
    expect(row.byteSize, 321);
    expect(row.etag, '"image-v1"');
    expect(row.lastModified, 'Wed, 30 Jul 2026 10:00:00 GMT');
    expect(row.fetchedAt, 1785484800000);
    expect(row.staleAt, 1788076800000);
    expect(row.expiresAt, 1788076800000);
    expect(row.lastAccessedAt, 1785484800000);

    final readBack = await metadataStore.readImageMetadata(uri);
    expect(readBack?.backend, ImageCacheBackend.nativeFile);
    expect(readBack?.byteSize, 321);

    await metadataStore.touchImageMetadata(uri, DateTime.utc(2026, 7, 31, 9));
    expect(
      (await database.select(database.imageCacheEntries).getSingle())
          .lastAccessedAt,
      1785488400000,
    );

    await metadataStore.removeImageMetadata(uri);
    expect(await database.select(database.imageCacheEntries).get(), isEmpty);
  });

  test('keeps CatalogDatabase as a compatibility alias', () async {
    final CatalogDatabase compatibilityDatabase = database;

    expect(compatibilityDatabase, same(database));
    expect(compatibilityDatabase, isA<MioAniDatabase>());
  });

  test('evicts image metadata at 90% by expiry then LRU to 75%', () async {
    final metadataStore = database as ImageCacheMetadataStore;
    final now = DateTime.utc(2026, 7, 31, 8);

    ImageCacheMetadata metadata({
      required String name,
      required int byteSize,
      required DateTime expiresAt,
      required DateTime lastAccessedAt,
    }) {
      return ImageCacheMetadata(
        uri: Uri.parse('https://lain.bgm.tv/pic/cover/$name.jpg'),
        storageKey: '$name-key',
        backend: ImageCacheBackend.nativeFile,
        byteSize: byteSize,
        etag: null,
        lastModified: null,
        fetchedAt: DateTime.utc(2026, 7, 1),
        staleAt: expiresAt,
        expiresAt: expiresAt,
        lastAccessedAt: lastAccessedAt,
      );
    }

    final belowTrigger = metadata(
      name: 'below-trigger',
      byteSize: 89,
      expiresAt: DateTime.utc(2026, 8, 1),
      lastAccessedAt: DateTime.utc(2026, 7, 1),
    );
    await metadataStore.upsert(belowTrigger);
    expect(
      await metadataStore.enforceImageCacheBudget(maxBytes: 100, now: now),
      isEmpty,
    );
    await metadataStore.removeImageMetadata(belowTrigger.uri);

    final expired = metadata(
      name: 'expired-new',
      byteSize: 20,
      expiresAt: DateTime.utc(2026, 7, 30),
      lastAccessedAt: DateTime.utc(2026, 7, 30),
    );
    final freshOld = metadata(
      name: 'fresh-old',
      byteSize: 40,
      expiresAt: DateTime.utc(2026, 8, 1),
      lastAccessedAt: DateTime.utc(2026, 7, 1),
    );
    final freshNew = metadata(
      name: 'fresh-new',
      byteSize: 60,
      expiresAt: DateTime.utc(2026, 8, 1),
      lastAccessedAt: DateTime.utc(2026, 7, 2),
    );
    await metadataStore.upsert(expired);
    await metadataStore.upsert(freshOld);
    await metadataStore.upsert(freshNew);

    final evicted = await metadataStore.enforceImageCacheBudget(
      maxBytes: 100,
      now: now,
    );
    final remaining = await database.select(database.imageCacheEntries).get();

    expect(evicted.map((entry) => entry.uri), <Uri>[expired.uri, freshOld.uri]);
    expect(remaining.map((entry) => entry.imageUrl), <String>[
      freshNew.uri.toString(),
    ]);
  });

  test('records UTF-8 payload bytes and touches access time on read', () async {
    await store.writeCatalog(
      CatalogCacheRecord(
        value: <AnimeSummary>[testAnimeSummary],
        fetchedAt: fetchedAt,
        staleAt: staleAt,
        expiresAt: expiresAt,
      ),
    );
    final before = await database
        .select(database.structuredCacheEntries)
        .getSingle();

    await database.readCacheEntry(before.cacheKey, accessedAt: 12345);
    final after = await database
        .select(database.structuredCacheEntries)
        .getSingle();

    expect(before.category, 'catalog');
    expect(before.byteSize, utf8.encode(before.payload).length);
    expect(after.lastAccessedAt, 12345);
  });

  test(
    'evicts expired entries before least recently used fresh entries',
    () async {
      Future<void> insertEntry({
        required String key,
        required int expiresAt,
        required int lastAccessedAt,
      }) async {
        await database.writeCacheEntry(
          StructuredCacheEntriesCompanion.insert(
            cacheKey: key,
            payload: '{}',
            fetchedAt: 1,
            staleAt: 2,
            expiresAt: expiresAt,
            byteSize: const Value(40),
            lastAccessedAt: Value(lastAccessedAt),
          ),
          maxBytes: 1000,
          nowMillis: 50,
        );
      }

      await insertEntry(key: 'fresh-old', expiresAt: 200, lastAccessedAt: 10);
      await insertEntry(key: 'fresh-new', expiresAt: 200, lastAccessedAt: 20);
      await insertEntry(key: 'expired-new', expiresAt: 40, lastAccessedAt: 100);

      final evicted = await database.enforceStructuredCacheBudget(
        maxBytes: 100,
        nowMillis: 50,
      );
      final remaining = await database
          .select(database.structuredCacheEntries)
          .get();

      expect(evicted, <String>['expired-new', 'fresh-old']);
      expect(remaining.map((row) => row.cacheKey), <String>['fresh-new']);
    },
  );

  test('starts automatic eviction at 90% and returns to at most 75%', () async {
    Future<List<String>> writeSized(String key, int size, int access) {
      return database.writeCacheEntry(
        StructuredCacheEntriesCompanion.insert(
          cacheKey: key,
          payload: '{}',
          fetchedAt: 1,
          staleAt: 2,
          expiresAt: 200,
          byteSize: Value(size),
          lastAccessedAt: Value(access),
        ),
        maxBytes: 100,
        nowMillis: 50,
      );
    }

    expect(await writeSized('old', 40, 1), isEmpty);
    expect(await writeSized('new', 50, 2), <String>['old']);

    final remaining = await database
        .select(database.structuredCacheEntries)
        .getSingle();
    expect(remaining.cacheKey, 'new');
    expect(remaining.byteSize, 50);
  });
}
