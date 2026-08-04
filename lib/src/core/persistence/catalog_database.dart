import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/core/persistence/legacy_migration.dart';

part 'catalog_database.g.dart';

class StructuredCacheEntries extends Table {
  TextColumn get cacheKey => text()();

  TextColumn get payload => text()();

  IntColumn get fetchedAt => integer()();

  IntColumn get staleAt => integer()();

  IntColumn get expiresAt => integer()();

  TextColumn get category => text().withDefault(const Constant('catalog'))();

  IntColumn get byteSize => integer().withDefault(const Constant(0))();

  IntColumn get lastAccessedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{cacheKey};

  @override
  List<String> get customConstraints => const <String>[
    'CHECK (byte_size >= 0)',
    'CHECK (stale_at >= fetched_at)',
    'CHECK (expires_at >= stale_at)',
    'CHECK (last_accessed_at >= 0)',
  ];
}

class AnimeIdentities extends Table {
  TextColumn get identityId => text()();

  TextColumn get canonicalTitle => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{identityId};
}

class IdentityEvidenceRecords extends Table {
  TextColumn get evidenceId => text()();
  TextColumn get identityId => text().nullable()();
  TextColumn get sourceIds => text().withDefault(const Constant(''))();
  TextColumn get kind => text()();
  TextColumn get explanation => text()();
  IntColumn get score => integer().nullable()();
  IntColumn get createdAt => integer()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{evidenceId};
}

class IdentityReviews extends Table {
  TextColumn get reviewId => text()();
  TextColumn get leftSourceId => text()();
  TextColumn get rightSourceId => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get explanation => text().withDefault(const Constant(''))();
  IntColumn get baselineRevision => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{reviewId};
  @override
  List<String> get customConstraints => const <String>[
    "CHECK (status IN ('pending', 'confirmed', 'ignored', 'split'))",
    'CHECK (baseline_revision >= 0)',
  ];
}

class IdentityDecisions extends Table {
  TextColumn get decisionId => text()();
  TextColumn get reviewId => text()();
  TextColumn get kind => text()();
  TextColumn get explanation => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  IntColumn get undoneAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{decisionId};
}

class IdentityOperationLogs extends Table {
  TextColumn get operationId => text()();
  TextColumn get operationKind => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  IntColumn get createdAt => integer()();
  IntColumn get undoneAt => integer().nullable()();
  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{operationId};
}

class SourceEntities extends Table {
  TextColumn get source => text()();

  TextColumn get sourceId => text()();

  TextColumn get identityId => text().references(
    AnimeIdentities,
    #identityId,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get title => text().withDefault(const Constant(''))();

  TextColumn get originalTitle => text().withDefault(const Constant(''))();

  TextColumn get imageUrl => text().nullable()();

  IntColumn get year => integer().nullable()();

  IntColumn get episodes => integer().nullable()();

  IntColumn get observedAt => integer()();

  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{source, sourceId};

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (source IN ('bangumi', 'anilist', 'local'))",
    'CHECK (year IS NULL OR year >= 0)',
    'CHECK (episodes IS NULL OR episodes >= 0)',
  ];
}

class LegacyIdentityLinks extends Table {
  TextColumn get identityId => text().references(
    AnimeIdentities,
    #identityId,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get linkedSourceId => text()();

  TextColumn get evidence =>
      text().withDefault(const Constant('legacy_linked_ids'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    identityId,
    linkedSourceId,
  };
}

class LibraryEntries extends Table {
  TextColumn get identityId => text().references(
    AnimeIdentities,
    #identityId,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get status => text().withDefault(const Constant('planned'))();

  IntColumn get watched => integer().withDefault(const Constant(0))();

  IntColumn get localRevision => integer().withDefault(const Constant(0))();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{identityId};

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (status IN ('watching', 'completed', 'planned', 'paused', "
        "'dropped'))",
    'CHECK (watched >= 0)',
    'CHECK (local_revision >= 0)',
  ];
}

class PublicAccounts extends Table {
  TextColumn get source => text()();

  TextColumn get stableUserId => text()();

  TextColumn get displayName => text()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{source, stableUserId};

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (source IN ('bangumi', 'anilist'))",
  ];
}

class ImportBatchRecords extends Table {
  TextColumn get batchId => text()();
  TextColumn get source => text()();
  TextColumn get stableUserId => text()();
  TextColumn get displayName => text()();
  TextColumn get fingerprint => text()();
  IntColumn get createdAt => integer()();
  IntColumn get pagesFetched => integer()();
  IntColumn get declaredTotal => integer().nullable()();
  IntColumn get itemCount => integer()();
  TextColumn get countsJson => text().withDefault(const Constant('{}'))();
  TextColumn get previousBatchId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('succeeded'))();
  IntColumn get undoneAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{batchId};

  @override
  String get tableName => 'import_batches';

  @override
  List<String> get customConstraints => const <String>[
    'CHECK (pages_fetched >= 0)',
    'CHECK (declared_total IS NULL OR declared_total >= 0)',
    'CHECK (item_count >= 0)',
  ];
}

class ImportContributionRecords extends Table {
  TextColumn get batchId => text().references(
    ImportBatchRecords,
    #batchId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get sourceId => text()();
  TextColumn get identityId => text().nullable().references(
    AnimeIdentities,
    #identityId,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get disposition => text()();
  IntColumn get observedAt => integer()();
  TextColumn get reason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{batchId, sourceId};

  @override
  String get tableName => 'import_contributions';
}

class ImportSnapshotRecords extends Table {
  TextColumn get batchId => text().references(
    ImportBatchRecords,
    #batchId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get source => text()();
  TextColumn get stableUserId => text()();
  TextColumn get fingerprint => text()();
  TextColumn get itemsJson => text().withDefault(const Constant('[]'))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{batchId};

  @override
  String get tableName => 'import_snapshots';
}

class AppSettings extends Table {
  TextColumn get settingKey => text()();

  TextColumn get valueType => text()();

  TextColumn get jsonValue => text()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{settingKey};
}

class MigrationLedger extends Table {
  TextColumn get migrationKey => text()();

  TextColumn get sourceFingerprint => text()();

  IntColumn get migrationVersion => integer()();

  TextColumn get status => text()();

  IntColumn get migratedEntries => integer().withDefault(const Constant(0))();

  IntColumn get completedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    migrationKey,
    sourceFingerprint,
  };

  @override
  List<String> get customConstraints => const <String>[
    'CHECK (migration_version > 0)',
    "CHECK (status IN ('completed', 'failed'))",
    'CHECK (migrated_entries >= 0)',
  ];
}

class ImageCacheEntries extends Table {
  TextColumn get imageUrl => text()();

  TextColumn get storageKey => text().unique()();

  TextColumn get backend => text()();

  IntColumn get byteSize => integer()();

  TextColumn get etag => text().nullable()();

  TextColumn get lastModified => text().nullable()();

  IntColumn get fetchedAt => integer()();

  IntColumn get staleAt => integer()();

  IntColumn get expiresAt => integer()();

  IntColumn get lastAccessedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{imageUrl};

  @override
  List<String> get customConstraints => const <String>[
    "CHECK (backend IN ('native_file', 'web_cache'))",
    'CHECK (byte_size >= 0)',
    'CHECK (stale_at >= fetched_at)',
    'CHECK (expires_at >= stale_at)',
    'CHECK (last_accessed_at >= 0)',
  ];
}

@DriftDatabase(
  tables: <Type>[
    StructuredCacheEntries,
    AnimeIdentities,
    SourceEntities,
    LegacyIdentityLinks,
    LibraryEntries,
    PublicAccounts,
    AppSettings,
    MigrationLedger,
    ImageCacheEntries,
    IdentityEvidenceRecords,
    IdentityReviews,
    IdentityDecisions,
    IdentityOperationLogs,
    ImportBatchRecords,
    ImportContributionRecords,
    ImportSnapshotRecords,
  ],
)
final class MioAniDatabase extends _$MioAniDatabase
    implements ImageCacheMetadataStore, LegacyMigrationCommitter {
  MioAniDatabase(super.executor);

  static const String databaseName = 'mio_ani';
  static const String vueMigrationKey = 'vue-web-v1';
  static const int vueMigrationVersion = 1;
  static const int structuredCacheCapacityBytes = 64 * 1024 * 1024;
  static const double cacheHighWatermark = 0.90;
  static const double cacheLowWatermark = 0.75;
  static final Uri sqliteWasmUri = Uri.parse('sqlite3.wasm');
  static final Uri driftWorkerUri = Uri.parse('drift_worker.js');

  MioAniDatabase.defaults()
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(animeIdentities);
        await migrator.createTable(sourceEntities);
        await migrator.createTable(legacyIdentityLinks);
        await migrator.createTable(libraryEntries);
        await migrator.createTable(publicAccounts);
        await migrator.createTable(appSettings);
        await migrator.createTable(migrationLedger);
        await migrator.createTable(imageCacheEntries);
        await migrator.addColumn(
          structuredCacheEntries,
          structuredCacheEntries.category,
        );
        await migrator.addColumn(
          structuredCacheEntries,
          structuredCacheEntries.byteSize,
        );
        await migrator.addColumn(
          structuredCacheEntries,
          structuredCacheEntries.lastAccessedAt,
        );
        await customStatement('''
          UPDATE structured_cache_entries
          SET byte_size = length(CAST(payload AS BLOB)),
              last_accessed_at = fetched_at
        ''');
        await migrator.alterTable(TableMigration(structuredCacheEntries));
      }
      if (from < 3) {
        if (from >= 2) {
          await migrator.addColumn(animeIdentities, animeIdentities.revision);
          await migrator.addColumn(sourceEntities, sourceEntities.revision);
        }
        await migrator.createTable(identityEvidenceRecords);
        await migrator.createTable(identityReviews);
        await migrator.createTable(identityDecisions);
        await migrator.createTable(identityOperationLogs);
      }
      if (from < 4) {
        await migrator.createTable(importBatchRecords);
        await migrator.createTable(importContributionRecords);
        await migrator.createTable(importSnapshotRecords);
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<StructuredCacheEntry?> readCacheEntry(
    String key, {
    int? accessedAt,
  }) async {
    final row = await (select(
      structuredCacheEntries,
    )..where((row) => row.cacheKey.equals(key))).getSingleOrNull();
    if (row == null) return null;

    final accessTime =
        accessedAt ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    await (update(
      structuredCacheEntries,
    )..where((entry) => entry.cacheKey.equals(key))).write(
      StructuredCacheEntriesCompanion(lastAccessedAt: Value(accessTime)),
    );
    return row;
  }

  Future<List<String>> writeCacheEntry(
    StructuredCacheEntriesCompanion entry, {
    int maxBytes = structuredCacheCapacityBytes,
    int? nowMillis,
  }) {
    return transaction(() async {
      await into(structuredCacheEntries).insertOnConflictUpdate(entry);
      return _enforceStructuredCacheBudget(
        maxBytes: maxBytes,
        nowMillis: nowMillis ?? DateTime.now().toUtc().millisecondsSinceEpoch,
      );
    });
  }

  Future<void> deleteCacheEntry(String key) async {
    await (delete(
      structuredCacheEntries,
    )..where((row) => row.cacheKey.equals(key))).go();
  }

  @override
  Future<void> upsert(ImageCacheMetadata entry) async {
    await into(imageCacheEntries).insertOnConflictUpdate(
      ImageCacheEntriesCompanion.insert(
        imageUrl: entry.uri.toString(),
        storageKey: entry.storageKey,
        backend: entry.backend.storageValue,
        byteSize: entry.byteSize,
        etag: Value(entry.etag),
        lastModified: Value(entry.lastModified),
        fetchedAt: entry.fetchedAt.toUtc().millisecondsSinceEpoch,
        staleAt: entry.staleAt.toUtc().millisecondsSinceEpoch,
        expiresAt: entry.expiresAt.toUtc().millisecondsSinceEpoch,
        lastAccessedAt: entry.lastAccessedAt.toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<ImageCacheMetadata?> readImageMetadata(Uri uri) async {
    final row =
        await (select(imageCacheEntries)
              ..where((entry) => entry.imageUrl.equals(uri.toString())))
            .getSingleOrNull();
    if (row == null) return null;
    return _imageMetadataFromRow(row);
  }

  ImageCacheMetadata _imageMetadataFromRow(ImageCacheEntry row) {
    return ImageCacheMetadata(
      uri: Uri.parse(row.imageUrl),
      storageKey: row.storageKey,
      backend: ImageCacheBackend.fromStorageValue(row.backend),
      byteSize: row.byteSize,
      etag: row.etag,
      lastModified: row.lastModified,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        row.fetchedAt,
        isUtc: true,
      ),
      staleAt: DateTime.fromMillisecondsSinceEpoch(row.staleAt, isUtc: true),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        row.expiresAt,
        isUtc: true,
      ),
      lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(
        row.lastAccessedAt,
        isUtc: true,
      ),
    );
  }

  @override
  Future<void> touchImageMetadata(Uri uri, DateTime accessedAt) async {
    await (update(
      imageCacheEntries,
    )..where((entry) => entry.imageUrl.equals(uri.toString()))).write(
      ImageCacheEntriesCompanion(
        lastAccessedAt: Value(accessedAt.toUtc().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<void> removeImageMetadata(Uri uri) async {
    await (delete(
      imageCacheEntries,
    )..where((entry) => entry.imageUrl.equals(uri.toString()))).go();
  }

  @override
  Future<List<ImageCacheMetadata>> enforceImageCacheBudget({
    required int maxBytes,
    required DateTime now,
  }) {
    return transaction(() async {
      if (maxBytes < 0) {
        throw ArgumentError.value(maxBytes, 'maxBytes', 'must not be negative');
      }

      final entries = await select(imageCacheEntries).get();
      var totalBytes = entries.fold<int>(0, (sum, row) => sum + row.byteSize);
      final highWatermark = (maxBytes * cacheHighWatermark).ceil();
      if (totalBytes < highWatermark) {
        return const <ImageCacheMetadata>[];
      }

      final nowMillis = now.toUtc().millisecondsSinceEpoch;
      final targetBytes = (maxBytes * cacheLowWatermark).floor();
      entries.sort((left, right) {
        final leftExpired = left.expiresAt <= nowMillis;
        final rightExpired = right.expiresAt <= nowMillis;
        if (leftExpired != rightExpired) return leftExpired ? -1 : 1;
        final byAccess = left.lastAccessedAt.compareTo(right.lastAccessedAt);
        if (byAccess != 0) return byAccess;
        return left.imageUrl.compareTo(right.imageUrl);
      });

      final evicted = <ImageCacheMetadata>[];
      for (final entry in entries) {
        if (totalBytes <= targetBytes) break;
        await (delete(
          imageCacheEntries,
        )..where((row) => row.imageUrl.equals(entry.imageUrl))).go();
        totalBytes -= entry.byteSize;
        evicted.add(_imageMetadataFromRow(entry));
      }
      return evicted;
    });
  }

  Future<void> clearPublicCache() async {
    await transaction(() async {
      await delete(structuredCacheEntries).go();
      await delete(imageCacheEntries).go();
    });
  }

  @override
  Future<LegacyMigrationCommitResult> commitLegacyMigrationPlan(
    LegacyMigrationCommitPlan plan, {
    required DateTime now,
  }) {
    final nowMillis = now.toUtc().millisecondsSinceEpoch;
    return transaction(() async {
      final existingLedger =
          await (select(migrationLedger)..where(
                (row) =>
                    row.migrationKey.equals(vueMigrationKey) &
                    row.sourceFingerprint.equals(plan.fingerprint) &
                    row.status.equals('completed'),
              ))
              .getSingleOrNull();
      if (existingLedger != null) {
        return LegacyMigrationCommitResult(
          status: LegacyMigrationCommitStatus.alreadyMigrated,
          fingerprint: plan.fingerprint,
          migratedEntries: existingLedger.migratedEntries,
        );
      }

      for (final identity in plan.identities) {
        await _upsertMigratedIdentity(identity, nowMillis: nowMillis);
      }
      await _upsertMigratedProfile(plan.profile, nowMillis: nowMillis);

      await into(migrationLedger).insert(
        MigrationLedgerCompanion.insert(
          migrationKey: vueMigrationKey,
          sourceFingerprint: plan.fingerprint,
          migrationVersion: vueMigrationVersion,
          status: 'completed',
          migratedEntries: Value(plan.identities.length),
          completedAt: nowMillis,
        ),
      );

      return LegacyMigrationCommitResult(
        status: LegacyMigrationCommitStatus.committed,
        fingerprint: plan.fingerprint,
        migratedEntries: plan.identities.length,
      );
    });
  }

  Future<void> _upsertMigratedIdentity(
    LegacyPlannedIdentity identity, {
    required int nowMillis,
  }) async {
    final existingIdentity =
        await (select(animeIdentities)
              ..where((row) => row.identityId.equals(identity.identityKey)))
            .getSingleOrNull();
    if (existingIdentity == null) {
      await into(animeIdentities).insert(
        AnimeIdentitiesCompanion.insert(
          identityId: identity.identityKey,
          canonicalTitle: Value(identity.canonicalTitle),
          createdAt: nowMillis,
          updatedAt: nowMillis,
        ),
      );
    }

    for (final entity in identity.sourceEntities) {
      final existingSource =
          await (select(sourceEntities)..where(
                (row) =>
                    row.source.equals(entity.source.name) &
                    row.sourceId.equals(entity.sourceId),
              ))
              .getSingleOrNull();
      if (existingSource == null) {
        await into(sourceEntities).insert(
          SourceEntitiesCompanion.insert(
            source: entity.source.name,
            sourceId: entity.sourceId,
            identityId: identity.identityKey,
            title: Value(entity.title),
            originalTitle: Value(entity.originalTitle ?? ''),
            year: Value(entity.year),
            episodes: Value(entity.episodes),
            observedAt: nowMillis,
          ),
        );
      }
    }

    for (final linkedId in identity.legacyLinkedIds) {
      final existingLink =
          await (select(legacyIdentityLinks)..where(
                (row) =>
                    row.identityId.equals(identity.identityKey) &
                    row.linkedSourceId.equals(linkedId),
              ))
              .getSingleOrNull();
      if (existingLink == null) {
        await into(legacyIdentityLinks).insert(
          LegacyIdentityLinksCompanion.insert(
            identityId: identity.identityKey,
            linkedSourceId: linkedId,
          ),
        );
      }
    }

    final existingLibrary =
        await (select(libraryEntries)
              ..where((row) => row.identityId.equals(identity.identityKey)))
            .getSingleOrNull();
    if (existingLibrary != null) {
      // Existing Flutter library rows always win; later legacy retries may only
      // enrich missing source/link evidence above and never replace status or
      // reduce watched progress.
      return;
    }

    await into(libraryEntries).insert(
      LibraryEntriesCompanion.insert(
        identityId: identity.identityKey,
        status: Value(identity.status.name),
        watched: Value(identity.watched),
        updatedAt: nowMillis,
      ),
    );
  }

  Future<void> _upsertMigratedProfile(
    LegacyProfileRecord? profile, {
    required int nowMillis,
  }) async {
    if (profile == null) return;
    for (final source in profile.sources) {
      final existing =
          await (select(publicAccounts)..where(
                (row) =>
                    row.source.equals(source.name) &
                    row.stableUserId.equals(profile.name),
              ))
              .getSingleOrNull();
      if (existing != null) continue;
      await into(publicAccounts).insert(
        PublicAccountsCompanion.insert(
          source: source.name,
          stableUserId: profile.name,
          displayName: profile.name,
          createdAt: nowMillis,
          updatedAt: nowMillis,
        ),
      );
    }
  }

  Future<List<String>> enforceStructuredCacheBudget({
    int maxBytes = structuredCacheCapacityBytes,
    int? nowMillis,
  }) {
    return transaction(
      () => _enforceStructuredCacheBudget(
        maxBytes: maxBytes,
        nowMillis: nowMillis ?? DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<String>> _enforceStructuredCacheBudget({
    required int maxBytes,
    required int nowMillis,
  }) async {
    if (maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be positive');
    }

    final entries = await select(structuredCacheEntries).get();
    var totalBytes = entries.fold<int>(0, (sum, row) => sum + row.byteSize);
    final highWatermark = (maxBytes * cacheHighWatermark).ceil();
    if (totalBytes < highWatermark) return const <String>[];

    final targetBytes = (maxBytes * cacheLowWatermark).floor();
    entries.sort((left, right) {
      final leftExpired = left.expiresAt <= nowMillis;
      final rightExpired = right.expiresAt <= nowMillis;
      if (leftExpired != rightExpired) return leftExpired ? -1 : 1;
      final byAccess = left.lastAccessedAt.compareTo(right.lastAccessedAt);
      if (byAccess != 0) return byAccess;
      return left.cacheKey.compareTo(right.cacheKey);
    });

    final evictedKeys = <String>[];
    for (final entry in entries) {
      if (totalBytes <= targetBytes) break;
      await (delete(
        structuredCacheEntries,
      )..where((row) => row.cacheKey.equals(entry.cacheKey))).go();
      totalBytes -= entry.byteSize;
      evictedKeys.add(entry.cacheKey);
    }
    return evictedKeys;
  }
}

typedef CatalogDatabase = MioAniDatabase;
