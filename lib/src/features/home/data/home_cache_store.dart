import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

/// Structured cache boundary for home content, keyed by cache key. Sections
/// follow `home:sections:<season>:v<n>`; the schedule preview itself lives in
/// the schedule cache (6h freshness) so the two never fight over one record.
///
/// The version is part of the key rather than a field on the record: a build
/// that changes what a partition means (which shows are in it, how they are
/// ordered) must not serve a record written under the old meaning. Bump it
/// whenever the derivation changes, so an install with a warm cache refetches
/// instead of showing the previous answer until the record ages out.
abstract interface class HomeCacheStore {
  Future<CatalogCacheRecord<HomeCatalogContent>?> readSections(String key);

  Future<void> writeSections(
    String key,
    CatalogCacheRecord<HomeCatalogContent> record,
  );

  /// The explore feed as far as it was scrolled. It is cached as one growing
  /// record per install rather than one per page, because the feed is what the
  /// user sees: restoring the first page alone would drop the rest.
  Future<CatalogCacheRecord<HomeExplorePage>?> readExplore(String key);

  Future<void> writeExplore(
    String key,
    CatalogCacheRecord<HomeExplorePage> record,
  );

  Future<void> deleteEntry(String key);
}

final class MemoryHomeCacheStore implements HomeCacheStore {
  MemoryHomeCacheStore({
    Map<String, CatalogCacheRecord<HomeCatalogContent>>? sections,
    Map<String, CatalogCacheRecord<HomeExplorePage>>? explore,
  }) : _sections =
           sections ?? <String, CatalogCacheRecord<HomeCatalogContent>>{},
       _explore = explore ?? <String, CatalogCacheRecord<HomeExplorePage>>{};

  final Map<String, CatalogCacheRecord<HomeCatalogContent>> _sections;
  final Map<String, CatalogCacheRecord<HomeExplorePage>> _explore;

  @override
  Future<void> deleteEntry(String key) async {
    _sections.remove(key);
    _explore.remove(key);
  }

  @override
  Future<CatalogCacheRecord<HomeExplorePage>?> readExplore(String key) async {
    return _explore[key];
  }

  @override
  Future<CatalogCacheRecord<HomeCatalogContent>?> readSections(
    String key,
  ) async {
    return _sections[key];
  }

  @override
  Future<void> writeExplore(
    String key,
    CatalogCacheRecord<HomeExplorePage> record,
  ) async {
    _explore[key] = record;
  }

  @override
  Future<void> writeSections(
    String key,
    CatalogCacheRecord<HomeCatalogContent> record,
  ) async {
    _sections[key] = record;
  }
}
