import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'catalog_database.g.dart';

class StructuredCacheEntries extends Table {
  TextColumn get cacheKey => text()();

  TextColumn get payload => text()();

  IntColumn get fetchedAt => integer()();

  IntColumn get staleAt => integer()();

  IntColumn get expiresAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{cacheKey};
}

@DriftDatabase(tables: <Type>[StructuredCacheEntries])
final class CatalogDatabase extends _$CatalogDatabase {
  CatalogDatabase(super.executor);

  static const String databaseName = 'mio_ani';
  static final Uri sqliteWasmUri = Uri.parse('sqlite3.wasm');
  static final Uri driftWorkerUri = Uri.parse('drift_worker.js');

  CatalogDatabase.defaults()
    : super(
        driftDatabase(
          name: databaseName,
          web: DriftWebOptions(
            sqlite3Wasm: sqliteWasmUri,
            driftWorker: driftWorkerUri,
          ),
        ),
      );

  @override
  int get schemaVersion => 1;

  Future<StructuredCacheEntry?> readCacheEntry(String key) {
    return (select(
      structuredCacheEntries,
    )..where((row) => row.cacheKey.equals(key))).getSingleOrNull();
  }

  Future<void> writeCacheEntry(StructuredCacheEntriesCompanion entry) async {
    await into(structuredCacheEntries).insertOnConflictUpdate(entry);
  }

  Future<void> deleteCacheEntry(String key) async {
    await (delete(
      structuredCacheEntries,
    )..where((row) => row.cacheKey.equals(key))).go();
  }
}
