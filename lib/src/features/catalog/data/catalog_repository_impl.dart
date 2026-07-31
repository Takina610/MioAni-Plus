import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_repository.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_source.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';

typedef CatalogNow = DateTime Function();

final class CatalogCachePolicy {
  const CatalogCachePolicy({
    this.freshFor = const Duration(minutes: 30),
    this.usableFor = const Duration(days: 7),
  });

  final Duration freshFor;
  final Duration usableFor;

  CatalogCacheRecord<T> record<T>(T value, DateTime now) {
    return CatalogCacheRecord<T>(
      value: value,
      fetchedAt: now,
      staleAt: now.add(freshFor),
      expiresAt: now.add(usableFor),
    );
  }
}

final class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl({
    required this.source,
    required this.cache,
    required this.now,
    this.policy = const CatalogCachePolicy(),
  });

  final CatalogSource source;
  final CatalogCacheStore cache;
  final CatalogNow now;
  final CatalogCachePolicy policy;

  @override
  Stream<CatalogSnapshot<List<AnimeSummary>>> watchCatalog({
    bool forceRefresh = false,
  }) async* {
    final cached = await _readCache(cache.readCatalog);
    yield* _watch<List<AnimeSummary>>(
      cached: cached,
      forceRefresh: forceRefresh,
      fetch: () => source.fetchCatalog(forceNewGeneration: forceRefresh),
      write: cache.writeCatalog,
    );
  }

  @override
  Stream<CatalogSnapshot<AnimeDetail>> watchDetail(
    AnimeSourceId id, {
    bool forceRefresh = false,
  }) async* {
    final cached = await _readCache(() => cache.readDetail(id));
    yield* _watch<AnimeDetail>(
      cached: cached,
      forceRefresh: forceRefresh,
      fetch: () => source.fetchDetail(id, forceNewGeneration: forceRefresh),
      write: (record) => cache.writeDetail(id, record),
    );
  }

  Future<T?> _readCache<T>(Future<T?> Function() read) async {
    try {
      return await read();
    } on AppFailure {
      rethrow;
    } on Object {
      throw const UnknownFailure();
    }
  }

  Stream<CatalogSnapshot<T>> _watch<T>({
    required CatalogCacheRecord<T>? cached,
    required bool forceRefresh,
    required Future<T> Function() fetch,
    required Future<void> Function(CatalogCacheRecord<T>) write,
  }) async* {
    final currentTime = now();
    final usableCache =
        cached != null && currentTime.isBefore(cached.expiresAt);
    final freshCache = usableCache && currentTime.isBefore(cached.staleAt);

    if (usableCache) {
      yield CatalogSnapshot<T>(
        value: cached.value,
        fetchedAt: cached.fetchedAt,
        isStale: !freshCache,
      );
      if (freshCache && !forceRefresh) return;
    }

    try {
      final value = await fetch();
      final record = policy.record<T>(value, now());
      await write(record);
      yield CatalogSnapshot<T>(
        value: value,
        fetchedAt: record.fetchedAt,
        isStale: false,
      );
    } on AppFailure catch (failure) {
      if (!usableCache) rethrow;
      yield CatalogSnapshot<T>(
        value: cached.value,
        fetchedAt: cached.fetchedAt,
        isStale: true,
        refreshFailure: failure,
      );
    } on Object {
      if (!usableCache) throw const UnknownFailure();
      yield CatalogSnapshot<T>(
        value: cached.value,
        fetchedAt: cached.fetchedAt,
        isStale: true,
        refreshFailure: const UnknownFailure(),
      );
    }
  }
}
