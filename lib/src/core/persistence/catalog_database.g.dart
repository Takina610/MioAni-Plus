// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_database.dart';

// ignore_for_file: type=lint
class $StructuredCacheEntriesTable extends StructuredCacheEntries
    with TableInfo<$StructuredCacheEntriesTable, StructuredCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StructuredCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staleAtMeta = const VerificationMeta(
    'staleAt',
  );
  @override
  late final GeneratedColumn<int> staleAt = GeneratedColumn<int>(
    'stale_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    payload,
    fetchedAt,
    staleAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'structured_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<StructuredCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('stale_at')) {
      context.handle(
        _staleAtMeta,
        staleAt.isAcceptableOrUnknown(data['stale_at']!, _staleAtMeta),
      );
    } else if (isInserting) {
      context.missing(_staleAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  StructuredCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StructuredCacheEntry(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
      staleAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stale_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $StructuredCacheEntriesTable createAlias(String alias) {
    return $StructuredCacheEntriesTable(attachedDatabase, alias);
  }
}

class StructuredCacheEntry extends DataClass
    implements Insertable<StructuredCacheEntry> {
  final String cacheKey;
  final String payload;
  final int fetchedAt;
  final int staleAt;
  final int expiresAt;
  const StructuredCacheEntry({
    required this.cacheKey,
    required this.payload,
    required this.fetchedAt,
    required this.staleAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<int>(fetchedAt);
    map['stale_at'] = Variable<int>(staleAt);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  StructuredCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return StructuredCacheEntriesCompanion(
      cacheKey: Value(cacheKey),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
      staleAt: Value(staleAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory StructuredCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StructuredCacheEntry(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      payload: serializer.fromJson<String>(json['payload']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
      staleAt: serializer.fromJson<int>(json['staleAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'payload': serializer.toJson<String>(payload),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
      'staleAt': serializer.toJson<int>(staleAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  StructuredCacheEntry copyWith({
    String? cacheKey,
    String? payload,
    int? fetchedAt,
    int? staleAt,
    int? expiresAt,
  }) => StructuredCacheEntry(
    cacheKey: cacheKey ?? this.cacheKey,
    payload: payload ?? this.payload,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    staleAt: staleAt ?? this.staleAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  StructuredCacheEntry copyWithCompanion(StructuredCacheEntriesCompanion data) {
    return StructuredCacheEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      staleAt: data.staleAt.present ? data.staleAt.value : this.staleAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StructuredCacheEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(cacheKey, payload, fetchedAt, staleAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StructuredCacheEntry &&
          other.cacheKey == this.cacheKey &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt &&
          other.staleAt == this.staleAt &&
          other.expiresAt == this.expiresAt);
}

class StructuredCacheEntriesCompanion
    extends UpdateCompanion<StructuredCacheEntry> {
  final Value<String> cacheKey;
  final Value<String> payload;
  final Value<int> fetchedAt;
  final Value<int> staleAt;
  final Value<int> expiresAt;
  final Value<int> rowid;
  const StructuredCacheEntriesCompanion({
    this.cacheKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.staleAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StructuredCacheEntriesCompanion.insert({
    required String cacheKey,
    required String payload,
    required int fetchedAt,
    required int staleAt,
    required int expiresAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       payload = Value(payload),
       fetchedAt = Value(fetchedAt),
       staleAt = Value(staleAt),
       expiresAt = Value(expiresAt);
  static Insertable<StructuredCacheEntry> custom({
    Expression<String>? cacheKey,
    Expression<String>? payload,
    Expression<int>? fetchedAt,
    Expression<int>? staleAt,
    Expression<int>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (staleAt != null) 'stale_at': staleAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StructuredCacheEntriesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? payload,
    Value<int>? fetchedAt,
    Value<int>? staleAt,
    Value<int>? expiresAt,
    Value<int>? rowid,
  }) {
    return StructuredCacheEntriesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      staleAt: staleAt ?? this.staleAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (staleAt.present) {
      map['stale_at'] = Variable<int>(staleAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StructuredCacheEntriesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CatalogDatabase extends GeneratedDatabase {
  _$CatalogDatabase(QueryExecutor e) : super(e);
  $CatalogDatabaseManager get managers => $CatalogDatabaseManager(this);
  late final $StructuredCacheEntriesTable structuredCacheEntries =
      $StructuredCacheEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [structuredCacheEntries];
}

typedef $$StructuredCacheEntriesTableCreateCompanionBuilder =
    StructuredCacheEntriesCompanion Function({
      required String cacheKey,
      required String payload,
      required int fetchedAt,
      required int staleAt,
      required int expiresAt,
      Value<int> rowid,
    });
typedef $$StructuredCacheEntriesTableUpdateCompanionBuilder =
    StructuredCacheEntriesCompanion Function({
      Value<String> cacheKey,
      Value<String> payload,
      Value<int> fetchedAt,
      Value<int> staleAt,
      Value<int> expiresAt,
      Value<int> rowid,
    });

class $$StructuredCacheEntriesTableFilterComposer
    extends Composer<_$CatalogDatabase, $StructuredCacheEntriesTable> {
  $$StructuredCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get staleAt => $composableBuilder(
    column: $table.staleAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StructuredCacheEntriesTableOrderingComposer
    extends Composer<_$CatalogDatabase, $StructuredCacheEntriesTable> {
  $$StructuredCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get staleAt => $composableBuilder(
    column: $table.staleAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StructuredCacheEntriesTableAnnotationComposer
    extends Composer<_$CatalogDatabase, $StructuredCacheEntriesTable> {
  $$StructuredCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get staleAt =>
      $composableBuilder(column: $table.staleAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$StructuredCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$CatalogDatabase,
          $StructuredCacheEntriesTable,
          StructuredCacheEntry,
          $$StructuredCacheEntriesTableFilterComposer,
          $$StructuredCacheEntriesTableOrderingComposer,
          $$StructuredCacheEntriesTableAnnotationComposer,
          $$StructuredCacheEntriesTableCreateCompanionBuilder,
          $$StructuredCacheEntriesTableUpdateCompanionBuilder,
          (
            StructuredCacheEntry,
            BaseReferences<
              _$CatalogDatabase,
              $StructuredCacheEntriesTable,
              StructuredCacheEntry
            >,
          ),
          StructuredCacheEntry,
          PrefetchHooks Function()
        > {
  $$StructuredCacheEntriesTableTableManager(
    _$CatalogDatabase db,
    $StructuredCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StructuredCacheEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$StructuredCacheEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$StructuredCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> staleAt = const Value.absent(),
                Value<int> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StructuredCacheEntriesCompanion(
                cacheKey: cacheKey,
                payload: payload,
                fetchedAt: fetchedAt,
                staleAt: staleAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String payload,
                required int fetchedAt,
                required int staleAt,
                required int expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => StructuredCacheEntriesCompanion.insert(
                cacheKey: cacheKey,
                payload: payload,
                fetchedAt: fetchedAt,
                staleAt: staleAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StructuredCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$CatalogDatabase,
      $StructuredCacheEntriesTable,
      StructuredCacheEntry,
      $$StructuredCacheEntriesTableFilterComposer,
      $$StructuredCacheEntriesTableOrderingComposer,
      $$StructuredCacheEntriesTableAnnotationComposer,
      $$StructuredCacheEntriesTableCreateCompanionBuilder,
      $$StructuredCacheEntriesTableUpdateCompanionBuilder,
      (
        StructuredCacheEntry,
        BaseReferences<
          _$CatalogDatabase,
          $StructuredCacheEntriesTable,
          StructuredCacheEntry
        >,
      ),
      StructuredCacheEntry,
      PrefetchHooks Function()
    >;

class $CatalogDatabaseManager {
  final _$CatalogDatabase _db;
  $CatalogDatabaseManager(this._db);
  $$StructuredCacheEntriesTableTableManager get structuredCacheEntries =>
      $$StructuredCacheEntriesTableTableManager(
        _db,
        _db.structuredCacheEntries,
      );
}
