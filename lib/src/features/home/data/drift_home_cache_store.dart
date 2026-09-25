import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_cache_codec.dart';
import 'package:mio_ani/src/features/home/data/home_cache_store.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

final class DriftHomeCacheStore implements HomeCacheStore {
  const DriftHomeCacheStore({
    required this.database,
    this.codec = const HomeCacheCodec(),
  });

  final MioAniDatabase database;
  final HomeCacheCodec codec;

  @override
  Future<void> deleteEntry(String key) {
    return database.deleteCacheEntry(key);
  }

  @override
  Future<CatalogCacheRecord<HomeExplorePage>?> readExplore(String key) async {
    final row = await database.readCacheEntry(key);
    if (row == null) return null;
    try {
      return _record(row, codec.decodeExplore(row.payload));
    } on FormatException {
      await deleteEntry(key);
      return null;
    }
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
      await deleteEntry(key);
      return null;
    }
  }

  @override
  Future<void> writeExplore(
    String key,
    CatalogCacheRecord<HomeExplorePage> record,
  ) {
    return _write(key, codec.encodeExplore(record.value), record);
  }

  @override
  Future<void> writeSections(
    String key,
    CatalogCacheRecord<HomeCatalogContent> record,
  ) {
    return _write(key, codec.encodeSections(record.value), record);
  }

  Future<void> _write(
    String key,
    String payload,
    CatalogCacheRecord<Object?> record,
  ) {
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
