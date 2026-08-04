import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

/// Structured cache boundary for home catalog sections. Keys follow
/// `home:sections:<season>:v1`; the schedule preview itself lives in the
/// schedule cache (6h freshness) so the two never fight over one record.
abstract interface class HomeCacheStore {
  Future<CatalogCacheRecord<HomeCatalogContent>?> readSections(String key);

  Future<void> writeSections(
    String key,
    CatalogCacheRecord<HomeCatalogContent> record,
  );

  Future<void> deleteSections(String key);
}

final class MemoryHomeCacheStore implements HomeCacheStore {
  MemoryHomeCacheStore({
    Map<String, CatalogCacheRecord<HomeCatalogContent>>? sections,
  }) : _sections =
           sections ?? <String, CatalogCacheRecord<HomeCatalogContent>>{};

  final Map<String, CatalogCacheRecord<HomeCatalogContent>> _sections;

  @override
  Future<void> deleteSections(String key) async {
    _sections.remove(key);
  }

  @override
  Future<CatalogCacheRecord<HomeCatalogContent>?> readSections(
    String key,
  ) async {
    return _sections[key];
  }

  @override
  Future<void> writeSections(
    String key,
    CatalogCacheRecord<HomeCatalogContent> record,
  ) async {
    _sections[key] = record;
  }
}
