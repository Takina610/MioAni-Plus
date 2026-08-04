import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/discover/data/discover_cache_store.dart';
import 'package:mio_ani/src/features/discover/data/discover_source.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

abstract interface class DiscoverRepository {
  Future<DiscoverPageResult> fetchPage(
    DiscoverQuery query, {
    required int page,
    AnimeSource? lockedSource,
    bool forceRefresh = false,
  });

  Future<DiscoverFilterCatalog> fetchFilterCatalog(
    DiscoverQuery query, {
    AnimeSource? lockedSource,
    bool forceRefresh = false,
  });

  AnimeSource chooseSource(DiscoverQuery query, {AnimeSource? lockedSource});
}

typedef DiscoverNow = DateTime Function();

final class DiscoverCachePolicy {
  const DiscoverCachePolicy({
    this.freshFor = const Duration(minutes: 45),
    this.usableFor = const Duration(days: 7),
  });

  final Duration freshFor;
  final Duration usableFor;
}

final class DiscoverRepositoryImpl implements DiscoverRepository {
  const DiscoverRepositoryImpl({
    required this.bangumi,
    required this.anilist,
    required this.cache,
    required this.now,
    this.policy = const DiscoverCachePolicy(),
  });

  final DiscoverSource bangumi;
  final DiscoverSource anilist;
  final DiscoverCacheStore cache;
  final DiscoverNow now;
  final DiscoverCachePolicy policy;

  @override
  AnimeSource chooseSource(DiscoverQuery query, {AnimeSource? lockedSource}) {
    if (lockedSource != null) return lockedSource;
    return switch (query.sourcePreference) {
      DiscoverSourcePreference.bangumi => AnimeSource.bangumi,
      DiscoverSourcePreference.anilist => AnimeSource.anilist,
      DiscoverSourcePreference.auto =>
        query.keyword.trim().isEmpty
            ? AnimeSource.anilist
            : AnimeSource.bangumi,
    };
  }

  @override
  Future<DiscoverPageResult> fetchPage(
    DiscoverQuery query, {
    required int page,
    AnimeSource? lockedSource,
    bool forceRefresh = false,
  }) async {
    final normalized = query.normalized();
    final source = chooseSource(normalized, lockedSource: lockedSource);
    final key = '${normalized.cacheKey}|source=${source.name}|page=$page';
    final cached = forceRefresh ? null : await cache.read(key);
    final current = now();
    if (cached != null && current.isBefore(cached.staleAt)) {
      return cached.value;
    }

    try {
      final result = await _source(source).fetchPage(
        DiscoverPageRequest(query: normalized, page: page, source: source),
        forceNewGeneration: forceRefresh,
      );
      final fetchedAt = now();
      await cache.write(
        key,
        DiscoverCacheRecord(
          value: DiscoverPageResult(
            items: result.items,
            page: result.page,
            source: result.source,
            hasMore: result.hasMore,
            total: result.total,
            fetchedAt: fetchedAt,
          ),
          fetchedAt: fetchedAt,
          staleAt: fetchedAt.add(policy.freshFor),
          expiresAt: fetchedAt.add(policy.usableFor),
        ),
      );
      return result;
    } on AppFailure {
      if (cached != null && current.isBefore(cached.expiresAt)) {
        return cached.value;
      }
      rethrow;
    }
  }

  @override
  Future<DiscoverFilterCatalog> fetchFilterCatalog(
    DiscoverQuery query, {
    AnimeSource? lockedSource,
    bool forceRefresh = false,
  }) {
    final source = chooseSource(query.normalized(), lockedSource: lockedSource);
    return _source(source).fetchFilterCatalog(forceNewGeneration: forceRefresh);
  }

  DiscoverSource _source(AnimeSource source) => switch (source) {
    AnimeSource.bangumi => bangumi,
    AnimeSource.anilist => anilist,
  };
}
