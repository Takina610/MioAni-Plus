import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_repository_impl.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_source.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

void main() {
  final anime = AnimeSummary(
    id: AnimeSourceId.tryParse('bgm-2')!,
    title: '初音岛 S.S.',
    sourceTitle: 'D.C.S.S.',
  );

  test('fresh cache is emitted without a network request', () async {
    final now = DateTime.utc(2026, 7, 31, 12);
    final cache = MemoryCatalogCacheStore(
      catalog: CatalogCacheRecord<List<AnimeSummary>>(
        value: <AnimeSummary>[anime],
        fetchedAt: now,
        staleAt: now.add(const Duration(minutes: 30)),
        expiresAt: now.add(const Duration(days: 7)),
      ),
    );
    final source = FakeCatalogSource(catalog: <AnimeSummary>[]);
    final repository = CatalogRepositoryImpl(
      source: source,
      cache: cache,
      now: () => now,
    );

    final snapshots = await repository.watchCatalog().toList();

    expect(snapshots.single.value, <AnimeSummary>[anime]);
    expect(snapshots.single.isStale, isFalse);
    expect(source.catalogCalls, 0);
  });

  test(
    'manual refresh bypasses fresh cache with a new request generation',
    () async {
      final now = DateTime.utc(2026, 7, 31, 12);
      final refreshed = AnimeSummary(
        id: AnimeSourceId.fromBangumiId(3),
        title: '手动刷新的动画',
        sourceTitle: 'Refreshed Anime',
      );
      final cache = MemoryCatalogCacheStore(
        catalog: CatalogCacheRecord<List<AnimeSummary>>(
          value: <AnimeSummary>[anime],
          fetchedAt: now,
          staleAt: now.add(const Duration(minutes: 30)),
          expiresAt: now.add(const Duration(days: 7)),
        ),
      );
      final source = FakeCatalogSource(catalog: <AnimeSummary>[refreshed]);
      final repository = CatalogRepositoryImpl(
        source: source,
        cache: cache,
        now: () => now,
      );

      final snapshots = await repository
          .watchCatalog(forceRefresh: true)
          .toList();

      expect(snapshots, hasLength(2));
      expect(snapshots.first.value, <AnimeSummary>[anime]);
      expect(snapshots.last.value, <AnimeSummary>[refreshed]);
      expect(source.lastForceNewGeneration, isTrue);
    },
  );

  test('stale cache survives a failed background refresh', () async {
    final now = DateTime.utc(2026, 7, 31, 12);
    final cache = MemoryCatalogCacheStore(
      catalog: CatalogCacheRecord<List<AnimeSummary>>(
        value: <AnimeSummary>[anime],
        fetchedAt: now.subtract(const Duration(hours: 1)),
        staleAt: now.subtract(const Duration(minutes: 30)),
        expiresAt: now.add(const Duration(days: 6)),
      ),
    );
    final repository = CatalogRepositoryImpl(
      source: FakeCatalogSource(failure: const OfflineFailure()),
      cache: cache,
      now: () => now,
    );

    final snapshots = await repository.watchCatalog().toList();

    expect(snapshots, hasLength(2));
    expect(snapshots.first.isStale, isTrue);
    expect(snapshots.last.refreshFailure, isA<OfflineFailure>());
    expect(snapshots.last.value, <AnimeSummary>[anime]);
  });

  test('stale cache is followed by a fresh network snapshot', () async {
    final now = DateTime.utc(2026, 7, 31, 12);
    final refreshed = AnimeSummary(
      id: AnimeSourceId.fromBangumiId(3),
      title: '刷新后的动画',
      sourceTitle: 'Refreshed Anime',
    );
    final cache = MemoryCatalogCacheStore(
      catalog: CatalogCacheRecord<List<AnimeSummary>>(
        value: <AnimeSummary>[anime],
        fetchedAt: now.subtract(const Duration(hours: 1)),
        staleAt: now.subtract(const Duration(minutes: 30)),
        expiresAt: now.add(const Duration(days: 6)),
      ),
    );
    final repository = CatalogRepositoryImpl(
      source: FakeCatalogSource(catalog: <AnimeSummary>[refreshed]),
      cache: cache,
      now: () => now,
    );

    final snapshots = await repository.watchCatalog().toList();

    expect(snapshots, hasLength(2));
    expect(snapshots.first.value, <AnimeSummary>[anime]);
    expect(snapshots.first.isStale, isTrue);
    expect(snapshots.last.value, <AnimeSummary>[refreshed]);
    expect(snapshots.last.isStale, isFalse);
    expect((await cache.readCatalog())?.value, <AnimeSummary>[refreshed]);
  });

  test('without usable cache preserves platform failures', () async {
    final repository = CatalogRepositoryImpl(
      source: FakeCatalogSource(failure: const OfflineFailure()),
      cache: MemoryCatalogCacheStore(),
      now: () => DateTime.utc(2026, 7, 31, 12),
    );

    await expectLater(
      repository.watchCatalog(),
      emitsError(isA<OfflineFailure>()),
    );
  });

  test('maps cache platform exceptions to an application failure', () async {
    final repository = CatalogRepositoryImpl(
      source: FakeCatalogSource(catalog: <AnimeSummary>[anime]),
      cache: ThrowingCatalogCacheStore(),
      now: () => DateTime.utc(2026, 7, 31, 12),
    );

    await expectLater(
      repository.watchCatalog(),
      emitsError(isA<UnknownFailure>()),
    );
  });
}

final class ThrowingCatalogCacheStore implements CatalogCacheStore {
  @override
  Future<void> deleteCatalog() async {}

  @override
  Future<void> deleteDetail(AnimeSourceId id) async {}

  @override
  Future<CatalogCacheRecord<List<AnimeSummary>>?> readCatalog() {
    throw StateError('database unavailable');
  }

  @override
  Future<CatalogCacheRecord<AnimeDetail>?> readDetail(AnimeSourceId id) {
    throw StateError('database unavailable');
  }

  @override
  Future<void> writeCatalog(
    CatalogCacheRecord<List<AnimeSummary>> record,
  ) async {}

  @override
  Future<void> writeDetail(
    AnimeSourceId id,
    CatalogCacheRecord<AnimeDetail> record,
  ) async {}
}

final class FakeCatalogSource implements CatalogSource {
  FakeCatalogSource({this.catalog = const <AnimeSummary>[], this.failure});

  final List<AnimeSummary> catalog;
  final AppFailure? failure;
  int catalogCalls = 0;
  bool? lastForceNewGeneration;

  @override
  Future<List<AnimeSummary>> fetchCatalog({
    bool forceNewGeneration = false,
  }) async {
    catalogCalls += 1;
    lastForceNewGeneration = forceNewGeneration;
    if (failure case final failure?) throw failure;
    return catalog;
  }

  @override
  Future<Never> fetchDetail(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  }) {
    throw UnimplementedError();
  }
}
