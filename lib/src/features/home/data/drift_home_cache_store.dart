import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_cache_codec.dart';
import 'package:mio_ani/src/features/home/data/home_cache_store.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

final class DriftHomeCacheStore implements HomeCacheStore {
  const DriftHomeCacheStore({
    required this.database,
    this.codec = const HomeCacheCodec(),
  });

  final MioAniDatabase database;
  final HomeCacheCodec codec;

  @override
  Future<void> deleteSections(String key) {
    return database.deleteCacheEntry(key);
  }

  @override
  Future<CatalogCacheRecord<HomeCatalogContent>?> readSections(
    String key,
  ) async {
    final row = await database.readCacheEntry(key);
    if (row == null) return null;
    try {
      return _record(row, codec.decodeSections(row.payload));
    } on FormatException {
      await deleteSections(key);
      return null;
    }
  }

  @override
  Future<void> writeSections(
    String key,
    CatalogCacheRecord<HomeCatalogContent> record,
  ) {
    final payload = codec.encodeSections(record.value);
    return database.writeCacheEntry(
      StructuredCacheEntriesCompanion.insert(
        cacheKey: key,
        payload: payload,
        fetchedAt: record.fetchedAt.millisecondsSinceEpoch,
        staleAt: record.staleAt.millisecondsSinceEpoch,
        expiresAt: record.expiresAt.millisecondsSinceEpoch,
        category: const Value('home'),
        byteSize: Value(utf8.encode(payload).length),
        lastAccessedAt: Value(record.fetchedAt.millisecondsSinceEpoch),
      ),
    );
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
}
