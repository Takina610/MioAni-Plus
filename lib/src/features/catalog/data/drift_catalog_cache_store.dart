import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_codec.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

final class DriftCatalogCacheStore implements CatalogCacheStore {
  const DriftCatalogCacheStore({
    required this.database,
    this.codec = const CatalogCacheCodec(),
  });

  static const _catalogKey = 'catalog:bangumi:calendar:v1';

  final CatalogDatabase database;
  final CatalogCacheCodec codec;

  @override
  Future<void> deleteCatalog() => database.deleteCacheEntry(_catalogKey);

  @override
  Future<void> deleteDetail(AnimeSourceId id) {
    return database.deleteCacheEntry(_detailKey(id));
  }

  @override
  Future<CatalogCacheRecord<List<AnimeSummary>>?> readCatalog() async {
    final row = await database.readCacheEntry(_catalogKey);
    if (row == null) return null;
    try {
      return _record(row, codec.decodeCatalog(row.payload));
    } on FormatException {
      await deleteCatalog();
      return null;
    }
  }

  @override
  Future<CatalogCacheRecord<AnimeDetail>?> readDetail(AnimeSourceId id) async {
    final row = await database.readCacheEntry(_detailKey(id));
    if (row == null) return null;
    try {
      return _record(row, codec.decodeDetail(row.payload));
    } on FormatException {
      await deleteDetail(id);
      return null;
    }
  }

  @override
  Future<void> writeCatalog(CatalogCacheRecord<List<AnimeSummary>> record) {
    return _write(_catalogKey, codec.encodeCatalog(record.value), record);
  }

  @override
  Future<void> writeDetail(
    AnimeSourceId id,
    CatalogCacheRecord<AnimeDetail> record,
  ) {
    return _write(_detailKey(id), codec.encodeDetail(record.value), record);
  }

  CatalogCacheRecord<T> _record<T>(StructuredCacheEntry row, T value) {
    return CatalogCacheRecord<T>(
      value: value,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        row.fetchedAt,
        isUtc: true,
      ),
      staleAt: DateTime.fromMillisecondsSinceEpoch(row.staleAt, isUtc: true),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        row.expiresAt,
        isUtc: true,
      ),
    );
  }

  Future<void> _write<T>(
    String key,
    String payload,
    CatalogCacheRecord<T> record,
  ) {
    return database.writeCacheEntry(
      StructuredCacheEntriesCompanion.insert(
        cacheKey: key,
        payload: payload,
        fetchedAt: record.fetchedAt.millisecondsSinceEpoch,
        staleAt: record.staleAt.millisecondsSinceEpoch,
        expiresAt: record.expiresAt.millisecondsSinceEpoch,
      ),
    );
  }

  String _detailKey(AnimeSourceId id) => 'detail:${id.value}:v1';
}
