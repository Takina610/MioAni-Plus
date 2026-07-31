import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

final class CatalogCacheRecord<T> {
  const CatalogCacheRecord({
    required this.value,
    required this.fetchedAt,
    required this.staleAt,
    required this.expiresAt,
  });

  final T value;
  final DateTime fetchedAt;
  final DateTime staleAt;
  final DateTime expiresAt;
}

abstract interface class CatalogCacheStore {
  Future<CatalogCacheRecord<List<AnimeSummary>>?> readCatalog();

  Future<void> writeCatalog(CatalogCacheRecord<List<AnimeSummary>> record);

  Future<CatalogCacheRecord<AnimeDetail>?> readDetail(AnimeSourceId id);

  Future<void> writeDetail(
    AnimeSourceId id,
    CatalogCacheRecord<AnimeDetail> record,
  );

  Future<void> deleteCatalog();

  Future<void> deleteDetail(AnimeSourceId id);
}

final class MemoryCatalogCacheStore implements CatalogCacheStore {
  factory MemoryCatalogCacheStore({
    CatalogCacheRecord<List<AnimeSummary>>? catalog,
    Map<AnimeSourceId, CatalogCacheRecord<AnimeDetail>>? details,
  }) {
    return MemoryCatalogCacheStore._(
      catalog,
      details ?? <AnimeSourceId, CatalogCacheRecord<AnimeDetail>>{},
    );
  }

  MemoryCatalogCacheStore._(this._catalog, this._details);

  CatalogCacheRecord<List<AnimeSummary>>? _catalog;
  final Map<AnimeSourceId, CatalogCacheRecord<AnimeDetail>> _details;

  @override
  Future<void> deleteCatalog() async => _catalog = null;

  @override
  Future<void> deleteDetail(AnimeSourceId id) async => _details.remove(id);

  @override
  Future<CatalogCacheRecord<List<AnimeSummary>>?> readCatalog() async {
    return _catalog;
  }

  @override
  Future<CatalogCacheRecord<AnimeDetail>?> readDetail(AnimeSourceId id) async {
    return _details[id];
  }

  @override
  Future<void> writeCatalog(
    CatalogCacheRecord<List<AnimeSummary>> record,
  ) async {
    _catalog = record;
  }

  @override
  Future<void> writeDetail(
    AnimeSourceId id,
    CatalogCacheRecord<AnimeDetail> record,
  ) async {
    _details[id] = record;
  }
}
