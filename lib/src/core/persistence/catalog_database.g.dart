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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('catalog'),
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<int> lastAccessedAt = GeneratedColumn<int>(
    'last_accessed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    payload,
    fetchedAt,
    staleAt,
    expiresAt,
    category,
    byteSize,
    lastAccessedAt,
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
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
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_accessed_at'],
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
  final String category;
  final int byteSize;
  final int lastAccessedAt;
  const StructuredCacheEntry({
    required this.cacheKey,
    required this.payload,
    required this.fetchedAt,
    required this.staleAt,
    required this.expiresAt,
    required this.category,
    required this.byteSize,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload'] = Variable<String>(payload);
    map['fetched_at'] = Variable<int>(fetchedAt);
    map['stale_at'] = Variable<int>(staleAt);
    map['expires_at'] = Variable<int>(expiresAt);
    map['category'] = Variable<String>(category);
    map['byte_size'] = Variable<int>(byteSize);
    map['last_accessed_at'] = Variable<int>(lastAccessedAt);
    return map;
  }

  StructuredCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return StructuredCacheEntriesCompanion(
      cacheKey: Value(cacheKey),
      payload: Value(payload),
      fetchedAt: Value(fetchedAt),
      staleAt: Value(staleAt),
      expiresAt: Value(expiresAt),
      category: Value(category),
      byteSize: Value(byteSize),
      lastAccessedAt: Value(lastAccessedAt),
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
      category: serializer.fromJson<String>(json['category']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      lastAccessedAt: serializer.fromJson<int>(json['lastAccessedAt']),
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
      'category': serializer.toJson<String>(category),
      'byteSize': serializer.toJson<int>(byteSize),
      'lastAccessedAt': serializer.toJson<int>(lastAccessedAt),
    };
  }

  StructuredCacheEntry copyWith({
    String? cacheKey,
    String? payload,
    int? fetchedAt,
    int? staleAt,
    int? expiresAt,
    String? category,
    int? byteSize,
    int? lastAccessedAt,
  }) => StructuredCacheEntry(
    cacheKey: cacheKey ?? this.cacheKey,
    payload: payload ?? this.payload,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    staleAt: staleAt ?? this.staleAt,
    expiresAt: expiresAt ?? this.expiresAt,
    category: category ?? this.category,
    byteSize: byteSize ?? this.byteSize,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  StructuredCacheEntry copyWithCompanion(StructuredCacheEntriesCompanion data) {
    return StructuredCacheEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payload: data.payload.present ? data.payload.value : this.payload,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      staleAt: data.staleAt.present ? data.staleAt.value : this.staleAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      category: data.category.present ? data.category.value : this.category,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StructuredCacheEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payload: $payload, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('category: $category, ')
          ..write('byteSize: $byteSize, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheKey,
    payload,
    fetchedAt,
    staleAt,
    expiresAt,
    category,
    byteSize,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StructuredCacheEntry &&
          other.cacheKey == this.cacheKey &&
          other.payload == this.payload &&
          other.fetchedAt == this.fetchedAt &&
          other.staleAt == this.staleAt &&
          other.expiresAt == this.expiresAt &&
          other.category == this.category &&
          other.byteSize == this.byteSize &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class StructuredCacheEntriesCompanion
    extends UpdateCompanion<StructuredCacheEntry> {
  final Value<String> cacheKey;
  final Value<String> payload;
  final Value<int> fetchedAt;
  final Value<int> staleAt;
  final Value<int> expiresAt;
  final Value<String> category;
  final Value<int> byteSize;
  final Value<int> lastAccessedAt;
  final Value<int> rowid;
  const StructuredCacheEntriesCompanion({
    this.cacheKey = const Value.absent(),
    this.payload = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.staleAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.category = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StructuredCacheEntriesCompanion.insert({
    required String cacheKey,
    required String payload,
    required int fetchedAt,
    required int staleAt,
    required int expiresAt,
    this.category = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
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
    Expression<String>? category,
    Expression<int>? byteSize,
    Expression<int>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payload != null) 'payload': payload,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (staleAt != null) 'stale_at': staleAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (category != null) 'category': category,
      if (byteSize != null) 'byte_size': byteSize,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StructuredCacheEntriesCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? payload,
    Value<int>? fetchedAt,
    Value<int>? staleAt,
    Value<int>? expiresAt,
    Value<String>? category,
    Value<int>? byteSize,
    Value<int>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return StructuredCacheEntriesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      payload: payload ?? this.payload,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      staleAt: staleAt ?? this.staleAt,
      expiresAt: expiresAt ?? this.expiresAt,
      category: category ?? this.category,
      byteSize: byteSize ?? this.byteSize,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<int>(lastAccessedAt.value);
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
          ..write('category: $category, ')
          ..write('byteSize: $byteSize, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnimeIdentitiesTable extends AnimeIdentities
    with TableInfo<$AnimeIdentitiesTable, AnimeIdentity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimeIdentitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalTitleMeta = const VerificationMeta(
    'canonicalTitle',
  );
  @override
  late final GeneratedColumn<String> canonicalTitle = GeneratedColumn<String>(
    'canonical_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    identityId,
    canonicalTitle,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anime_identities';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnimeIdentity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('canonical_title')) {
      context.handle(
        _canonicalTitleMeta,
        canonicalTitle.isAcceptableOrUnknown(
          data['canonical_title']!,
          _canonicalTitleMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {identityId};
  @override
  AnimeIdentity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimeIdentity(
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      )!,
      canonicalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_title'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AnimeIdentitiesTable createAlias(String alias) {
    return $AnimeIdentitiesTable(attachedDatabase, alias);
  }
}

class AnimeIdentity extends DataClass implements Insertable<AnimeIdentity> {
  final String identityId;
  final String canonicalTitle;
  final int createdAt;
  final int updatedAt;
  const AnimeIdentity({
    required this.identityId,
    required this.canonicalTitle,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['identity_id'] = Variable<String>(identityId);
    map['canonical_title'] = Variable<String>(canonicalTitle);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AnimeIdentitiesCompanion toCompanion(bool nullToAbsent) {
    return AnimeIdentitiesCompanion(
      identityId: Value(identityId),
      canonicalTitle: Value(canonicalTitle),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AnimeIdentity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimeIdentity(
      identityId: serializer.fromJson<String>(json['identityId']),
      canonicalTitle: serializer.fromJson<String>(json['canonicalTitle']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'identityId': serializer.toJson<String>(identityId),
      'canonicalTitle': serializer.toJson<String>(canonicalTitle),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AnimeIdentity copyWith({
    String? identityId,
    String? canonicalTitle,
    int? createdAt,
    int? updatedAt,
  }) => AnimeIdentity(
    identityId: identityId ?? this.identityId,
    canonicalTitle: canonicalTitle ?? this.canonicalTitle,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AnimeIdentity copyWithCompanion(AnimeIdentitiesCompanion data) {
    return AnimeIdentity(
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      canonicalTitle: data.canonicalTitle.present
          ? data.canonicalTitle.value
          : this.canonicalTitle,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimeIdentity(')
          ..write('identityId: $identityId, ')
          ..write('canonicalTitle: $canonicalTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(identityId, canonicalTitle, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimeIdentity &&
          other.identityId == this.identityId &&
          other.canonicalTitle == this.canonicalTitle &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AnimeIdentitiesCompanion extends UpdateCompanion<AnimeIdentity> {
  final Value<String> identityId;
  final Value<String> canonicalTitle;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AnimeIdentitiesCompanion({
    this.identityId = const Value.absent(),
    this.canonicalTitle = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnimeIdentitiesCompanion.insert({
    required String identityId,
    this.canonicalTitle = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : identityId = Value(identityId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AnimeIdentity> custom({
    Expression<String>? identityId,
    Expression<String>? canonicalTitle,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (identityId != null) 'identity_id': identityId,
      if (canonicalTitle != null) 'canonical_title': canonicalTitle,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnimeIdentitiesCompanion copyWith({
    Value<String>? identityId,
    Value<String>? canonicalTitle,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AnimeIdentitiesCompanion(
      identityId: identityId ?? this.identityId,
      canonicalTitle: canonicalTitle ?? this.canonicalTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (canonicalTitle.present) {
      map['canonical_title'] = Variable<String>(canonicalTitle.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimeIdentitiesCompanion(')
          ..write('identityId: $identityId, ')
          ..write('canonicalTitle: $canonicalTitle, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourceEntitiesTable extends SourceEntities
    with TableInfo<$SourceEntitiesTable, SourceEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceEntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_identities (identity_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta(
    'originalTitle',
  );
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodesMeta = const VerificationMeta(
    'episodes',
  );
  @override
  late final GeneratedColumn<int> episodes = GeneratedColumn<int>(
    'episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<int> observedAt = GeneratedColumn<int>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    source,
    sourceId,
    identityId,
    title,
    originalTitle,
    imageUrl,
    year,
    episodes,
    observedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(
          data['original_title']!,
          _originalTitleMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('episodes')) {
      context.handle(
        _episodesMeta,
        episodes.isAcceptableOrUnknown(data['episodes']!, _episodesMeta),
      );
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, sourceId};
  @override
  SourceEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceEntity(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      episodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episodes'],
      ),
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}observed_at'],
      )!,
    );
  }

  @override
  $SourceEntitiesTable createAlias(String alias) {
    return $SourceEntitiesTable(attachedDatabase, alias);
  }
}

class SourceEntity extends DataClass implements Insertable<SourceEntity> {
  final String source;
  final String sourceId;
  final String identityId;
  final String title;
  final String originalTitle;
  final String? imageUrl;
  final int? year;
  final int? episodes;
  final int observedAt;
  const SourceEntity({
    required this.source,
    required this.sourceId,
    required this.identityId,
    required this.title,
    required this.originalTitle,
    this.imageUrl,
    this.year,
    this.episodes,
    required this.observedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['source_id'] = Variable<String>(sourceId);
    map['identity_id'] = Variable<String>(identityId);
    map['title'] = Variable<String>(title);
    map['original_title'] = Variable<String>(originalTitle);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || episodes != null) {
      map['episodes'] = Variable<int>(episodes);
    }
    map['observed_at'] = Variable<int>(observedAt);
    return map;
  }

  SourceEntitiesCompanion toCompanion(bool nullToAbsent) {
    return SourceEntitiesCompanion(
      source: Value(source),
      sourceId: Value(sourceId),
      identityId: Value(identityId),
      title: Value(title),
      originalTitle: Value(originalTitle),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      episodes: episodes == null && nullToAbsent
          ? const Value.absent()
          : Value(episodes),
      observedAt: Value(observedAt),
    );
  }

  factory SourceEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceEntity(
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      identityId: serializer.fromJson<String>(json['identityId']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String>(json['originalTitle']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      year: serializer.fromJson<int?>(json['year']),
      episodes: serializer.fromJson<int?>(json['episodes']),
      observedAt: serializer.fromJson<int>(json['observedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String>(sourceId),
      'identityId': serializer.toJson<String>(identityId),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String>(originalTitle),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'year': serializer.toJson<int?>(year),
      'episodes': serializer.toJson<int?>(episodes),
      'observedAt': serializer.toJson<int>(observedAt),
    };
  }

  SourceEntity copyWith({
    String? source,
    String? sourceId,
    String? identityId,
    String? title,
    String? originalTitle,
    Value<String?> imageUrl = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<int?> episodes = const Value.absent(),
    int? observedAt,
  }) => SourceEntity(
    source: source ?? this.source,
    sourceId: sourceId ?? this.sourceId,
    identityId: identityId ?? this.identityId,
    title: title ?? this.title,
    originalTitle: originalTitle ?? this.originalTitle,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    year: year.present ? year.value : this.year,
    episodes: episodes.present ? episodes.value : this.episodes,
    observedAt: observedAt ?? this.observedAt,
  );
  SourceEntity copyWithCompanion(SourceEntitiesCompanion data) {
    return SourceEntity(
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      year: data.year.present ? data.year.value : this.year,
      episodes: data.episodes.present ? data.episodes.value : this.episodes,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceEntity(')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('identityId: $identityId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('year: $year, ')
          ..write('episodes: $episodes, ')
          ..write('observedAt: $observedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    source,
    sourceId,
    identityId,
    title,
    originalTitle,
    imageUrl,
    year,
    episodes,
    observedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceEntity &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.identityId == this.identityId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.imageUrl == this.imageUrl &&
          other.year == this.year &&
          other.episodes == this.episodes &&
          other.observedAt == this.observedAt);
}

class SourceEntitiesCompanion extends UpdateCompanion<SourceEntity> {
  final Value<String> source;
  final Value<String> sourceId;
  final Value<String> identityId;
  final Value<String> title;
  final Value<String> originalTitle;
  final Value<String?> imageUrl;
  final Value<int?> year;
  final Value<int?> episodes;
  final Value<int> observedAt;
  final Value<int> rowid;
  const SourceEntitiesCompanion({
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.identityId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.year = const Value.absent(),
    this.episodes = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceEntitiesCompanion.insert({
    required String source,
    required String sourceId,
    required String identityId,
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.year = const Value.absent(),
    this.episodes = const Value.absent(),
    required int observedAt,
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       sourceId = Value(sourceId),
       identityId = Value(identityId),
       observedAt = Value(observedAt);
  static Insertable<SourceEntity> custom({
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? identityId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<String>? imageUrl,
    Expression<int>? year,
    Expression<int>? episodes,
    Expression<int>? observedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (identityId != null) 'identity_id': identityId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (imageUrl != null) 'image_url': imageUrl,
      if (year != null) 'year': year,
      if (episodes != null) 'episodes': episodes,
      if (observedAt != null) 'observed_at': observedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceEntitiesCompanion copyWith({
    Value<String>? source,
    Value<String>? sourceId,
    Value<String>? identityId,
    Value<String>? title,
    Value<String>? originalTitle,
    Value<String?>? imageUrl,
    Value<int?>? year,
    Value<int?>? episodes,
    Value<int>? observedAt,
    Value<int>? rowid,
  }) {
    return SourceEntitiesCompanion(
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      identityId: identityId ?? this.identityId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      imageUrl: imageUrl ?? this.imageUrl,
      year: year ?? this.year,
      episodes: episodes ?? this.episodes,
      observedAt: observedAt ?? this.observedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (episodes.present) {
      map['episodes'] = Variable<int>(episodes.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<int>(observedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceEntitiesCompanion(')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('identityId: $identityId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('year: $year, ')
          ..write('episodes: $episodes, ')
          ..write('observedAt: $observedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LegacyIdentityLinksTable extends LegacyIdentityLinks
    with TableInfo<$LegacyIdentityLinksTable, LegacyIdentityLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LegacyIdentityLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_identities (identity_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _linkedSourceIdMeta = const VerificationMeta(
    'linkedSourceId',
  );
  @override
  late final GeneratedColumn<String> linkedSourceId = GeneratedColumn<String>(
    'linked_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceMeta = const VerificationMeta(
    'evidence',
  );
  @override
  late final GeneratedColumn<String> evidence = GeneratedColumn<String>(
    'evidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy_linked_ids'),
  );
  @override
  List<GeneratedColumn> get $columns => [identityId, linkedSourceId, evidence];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_identity_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyIdentityLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('linked_source_id')) {
      context.handle(
        _linkedSourceIdMeta,
        linkedSourceId.isAcceptableOrUnknown(
          data['linked_source_id']!,
          _linkedSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_linkedSourceIdMeta);
    }
    if (data.containsKey('evidence')) {
      context.handle(
        _evidenceMeta,
        evidence.isAcceptableOrUnknown(data['evidence']!, _evidenceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {identityId, linkedSourceId};
  @override
  LegacyIdentityLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyIdentityLink(
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      )!,
      linkedSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_source_id'],
      )!,
      evidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence'],
      )!,
    );
  }

  @override
  $LegacyIdentityLinksTable createAlias(String alias) {
    return $LegacyIdentityLinksTable(attachedDatabase, alias);
  }
}

class LegacyIdentityLink extends DataClass
    implements Insertable<LegacyIdentityLink> {
  final String identityId;
  final String linkedSourceId;
  final String evidence;
  const LegacyIdentityLink({
    required this.identityId,
    required this.linkedSourceId,
    required this.evidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['identity_id'] = Variable<String>(identityId);
    map['linked_source_id'] = Variable<String>(linkedSourceId);
    map['evidence'] = Variable<String>(evidence);
    return map;
  }

  LegacyIdentityLinksCompanion toCompanion(bool nullToAbsent) {
    return LegacyIdentityLinksCompanion(
      identityId: Value(identityId),
      linkedSourceId: Value(linkedSourceId),
      evidence: Value(evidence),
    );
  }

  factory LegacyIdentityLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyIdentityLink(
      identityId: serializer.fromJson<String>(json['identityId']),
      linkedSourceId: serializer.fromJson<String>(json['linkedSourceId']),
      evidence: serializer.fromJson<String>(json['evidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'identityId': serializer.toJson<String>(identityId),
      'linkedSourceId': serializer.toJson<String>(linkedSourceId),
      'evidence': serializer.toJson<String>(evidence),
    };
  }

  LegacyIdentityLink copyWith({
    String? identityId,
    String? linkedSourceId,
    String? evidence,
  }) => LegacyIdentityLink(
    identityId: identityId ?? this.identityId,
    linkedSourceId: linkedSourceId ?? this.linkedSourceId,
    evidence: evidence ?? this.evidence,
  );
  LegacyIdentityLink copyWithCompanion(LegacyIdentityLinksCompanion data) {
    return LegacyIdentityLink(
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      linkedSourceId: data.linkedSourceId.present
          ? data.linkedSourceId.value
          : this.linkedSourceId,
      evidence: data.evidence.present ? data.evidence.value : this.evidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyIdentityLink(')
          ..write('identityId: $identityId, ')
          ..write('linkedSourceId: $linkedSourceId, ')
          ..write('evidence: $evidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(identityId, linkedSourceId, evidence);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyIdentityLink &&
          other.identityId == this.identityId &&
          other.linkedSourceId == this.linkedSourceId &&
          other.evidence == this.evidence);
}

class LegacyIdentityLinksCompanion extends UpdateCompanion<LegacyIdentityLink> {
  final Value<String> identityId;
  final Value<String> linkedSourceId;
  final Value<String> evidence;
  final Value<int> rowid;
  const LegacyIdentityLinksCompanion({
    this.identityId = const Value.absent(),
    this.linkedSourceId = const Value.absent(),
    this.evidence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LegacyIdentityLinksCompanion.insert({
    required String identityId,
    required String linkedSourceId,
    this.evidence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : identityId = Value(identityId),
       linkedSourceId = Value(linkedSourceId);
  static Insertable<LegacyIdentityLink> custom({
    Expression<String>? identityId,
    Expression<String>? linkedSourceId,
    Expression<String>? evidence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (identityId != null) 'identity_id': identityId,
      if (linkedSourceId != null) 'linked_source_id': linkedSourceId,
      if (evidence != null) 'evidence': evidence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LegacyIdentityLinksCompanion copyWith({
    Value<String>? identityId,
    Value<String>? linkedSourceId,
    Value<String>? evidence,
    Value<int>? rowid,
  }) {
    return LegacyIdentityLinksCompanion(
      identityId: identityId ?? this.identityId,
      linkedSourceId: linkedSourceId ?? this.linkedSourceId,
      evidence: evidence ?? this.evidence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (linkedSourceId.present) {
      map['linked_source_id'] = Variable<String>(linkedSourceId.value);
    }
    if (evidence.present) {
      map['evidence'] = Variable<String>(evidence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyIdentityLinksCompanion(')
          ..write('identityId: $identityId, ')
          ..write('linkedSourceId: $linkedSourceId, ')
          ..write('evidence: $evidence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryEntriesTable extends LibraryEntries
    with TableInfo<$LibraryEntriesTable, LibraryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _identityIdMeta = const VerificationMeta(
    'identityId',
  );
  @override
  late final GeneratedColumn<String> identityId = GeneratedColumn<String>(
    'identity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_identities (identity_id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('planned'),
  );
  static const VerificationMeta _watchedMeta = const VerificationMeta(
    'watched',
  );
  @override
  late final GeneratedColumn<int> watched = GeneratedColumn<int>(
    'watched',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localRevisionMeta = const VerificationMeta(
    'localRevision',
  );
  @override
  late final GeneratedColumn<int> localRevision = GeneratedColumn<int>(
    'local_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    identityId,
    status,
    watched,
    localRevision,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('identity_id')) {
      context.handle(
        _identityIdMeta,
        identityId.isAcceptableOrUnknown(data['identity_id']!, _identityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_identityIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('watched')) {
      context.handle(
        _watchedMeta,
        watched.isAcceptableOrUnknown(data['watched']!, _watchedMeta),
      );
    }
    if (data.containsKey('local_revision')) {
      context.handle(
        _localRevisionMeta,
        localRevision.isAcceptableOrUnknown(
          data['local_revision']!,
          _localRevisionMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {identityId};
  @override
  LibraryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryEntry(
      identityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      watched: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}watched'],
      )!,
      localRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_revision'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LibraryEntriesTable createAlias(String alias) {
    return $LibraryEntriesTable(attachedDatabase, alias);
  }
}

class LibraryEntry extends DataClass implements Insertable<LibraryEntry> {
  final String identityId;
  final String status;
  final int watched;
  final int localRevision;
  final int updatedAt;
  const LibraryEntry({
    required this.identityId,
    required this.status,
    required this.watched,
    required this.localRevision,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['identity_id'] = Variable<String>(identityId);
    map['status'] = Variable<String>(status);
    map['watched'] = Variable<int>(watched);
    map['local_revision'] = Variable<int>(localRevision);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LibraryEntriesCompanion toCompanion(bool nullToAbsent) {
    return LibraryEntriesCompanion(
      identityId: Value(identityId),
      status: Value(status),
      watched: Value(watched),
      localRevision: Value(localRevision),
      updatedAt: Value(updatedAt),
    );
  }

  factory LibraryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryEntry(
      identityId: serializer.fromJson<String>(json['identityId']),
      status: serializer.fromJson<String>(json['status']),
      watched: serializer.fromJson<int>(json['watched']),
      localRevision: serializer.fromJson<int>(json['localRevision']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'identityId': serializer.toJson<String>(identityId),
      'status': serializer.toJson<String>(status),
      'watched': serializer.toJson<int>(watched),
      'localRevision': serializer.toJson<int>(localRevision),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LibraryEntry copyWith({
    String? identityId,
    String? status,
    int? watched,
    int? localRevision,
    int? updatedAt,
  }) => LibraryEntry(
    identityId: identityId ?? this.identityId,
    status: status ?? this.status,
    watched: watched ?? this.watched,
    localRevision: localRevision ?? this.localRevision,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LibraryEntry copyWithCompanion(LibraryEntriesCompanion data) {
    return LibraryEntry(
      identityId: data.identityId.present
          ? data.identityId.value
          : this.identityId,
      status: data.status.present ? data.status.value : this.status,
      watched: data.watched.present ? data.watched.value : this.watched,
      localRevision: data.localRevision.present
          ? data.localRevision.value
          : this.localRevision,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntry(')
          ..write('identityId: $identityId, ')
          ..write('status: $status, ')
          ..write('watched: $watched, ')
          ..write('localRevision: $localRevision, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(identityId, status, watched, localRevision, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryEntry &&
          other.identityId == this.identityId &&
          other.status == this.status &&
          other.watched == this.watched &&
          other.localRevision == this.localRevision &&
          other.updatedAt == this.updatedAt);
}

class LibraryEntriesCompanion extends UpdateCompanion<LibraryEntry> {
  final Value<String> identityId;
  final Value<String> status;
  final Value<int> watched;
  final Value<int> localRevision;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LibraryEntriesCompanion({
    this.identityId = const Value.absent(),
    this.status = const Value.absent(),
    this.watched = const Value.absent(),
    this.localRevision = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryEntriesCompanion.insert({
    required String identityId,
    this.status = const Value.absent(),
    this.watched = const Value.absent(),
    this.localRevision = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : identityId = Value(identityId),
       updatedAt = Value(updatedAt);
  static Insertable<LibraryEntry> custom({
    Expression<String>? identityId,
    Expression<String>? status,
    Expression<int>? watched,
    Expression<int>? localRevision,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (identityId != null) 'identity_id': identityId,
      if (status != null) 'status': status,
      if (watched != null) 'watched': watched,
      if (localRevision != null) 'local_revision': localRevision,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryEntriesCompanion copyWith({
    Value<String>? identityId,
    Value<String>? status,
    Value<int>? watched,
    Value<int>? localRevision,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return LibraryEntriesCompanion(
      identityId: identityId ?? this.identityId,
      status: status ?? this.status,
      watched: watched ?? this.watched,
      localRevision: localRevision ?? this.localRevision,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (identityId.present) {
      map['identity_id'] = Variable<String>(identityId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (watched.present) {
      map['watched'] = Variable<int>(watched.value);
    }
    if (localRevision.present) {
      map['local_revision'] = Variable<int>(localRevision.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntriesCompanion(')
          ..write('identityId: $identityId, ')
          ..write('status: $status, ')
          ..write('watched: $watched, ')
          ..write('localRevision: $localRevision, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PublicAccountsTable extends PublicAccounts
    with TableInfo<$PublicAccountsTable, PublicAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PublicAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stableUserIdMeta = const VerificationMeta(
    'stableUserId',
  );
  @override
  late final GeneratedColumn<String> stableUserId = GeneratedColumn<String>(
    'stable_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    source,
    stableUserId,
    displayName,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'public_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PublicAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('stable_user_id')) {
      context.handle(
        _stableUserIdMeta,
        stableUserId.isAcceptableOrUnknown(
          data['stable_user_id']!,
          _stableUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stableUserIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, stableUserId};
  @override
  PublicAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PublicAccount(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      stableUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stable_user_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PublicAccountsTable createAlias(String alias) {
    return $PublicAccountsTable(attachedDatabase, alias);
  }
}

class PublicAccount extends DataClass implements Insertable<PublicAccount> {
  final String source;
  final String stableUserId;
  final String displayName;
  final int createdAt;
  final int updatedAt;
  const PublicAccount({
    required this.source,
    required this.stableUserId,
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['stable_user_id'] = Variable<String>(stableUserId);
    map['display_name'] = Variable<String>(displayName);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PublicAccountsCompanion toCompanion(bool nullToAbsent) {
    return PublicAccountsCompanion(
      source: Value(source),
      stableUserId: Value(stableUserId),
      displayName: Value(displayName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PublicAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PublicAccount(
      source: serializer.fromJson<String>(json['source']),
      stableUserId: serializer.fromJson<String>(json['stableUserId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'stableUserId': serializer.toJson<String>(stableUserId),
      'displayName': serializer.toJson<String>(displayName),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PublicAccount copyWith({
    String? source,
    String? stableUserId,
    String? displayName,
    int? createdAt,
    int? updatedAt,
  }) => PublicAccount(
    source: source ?? this.source,
    stableUserId: stableUserId ?? this.stableUserId,
    displayName: displayName ?? this.displayName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PublicAccount copyWithCompanion(PublicAccountsCompanion data) {
    return PublicAccount(
      source: data.source.present ? data.source.value : this.source,
      stableUserId: data.stableUserId.present
          ? data.stableUserId.value
          : this.stableUserId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PublicAccount(')
          ..write('source: $source, ')
          ..write('stableUserId: $stableUserId, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(source, stableUserId, displayName, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PublicAccount &&
          other.source == this.source &&
          other.stableUserId == this.stableUserId &&
          other.displayName == this.displayName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PublicAccountsCompanion extends UpdateCompanion<PublicAccount> {
  final Value<String> source;
  final Value<String> stableUserId;
  final Value<String> displayName;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PublicAccountsCompanion({
    this.source = const Value.absent(),
    this.stableUserId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PublicAccountsCompanion.insert({
    required String source,
    required String stableUserId,
    required String displayName,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       stableUserId = Value(stableUserId),
       displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PublicAccount> custom({
    Expression<String>? source,
    Expression<String>? stableUserId,
    Expression<String>? displayName,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (stableUserId != null) 'stable_user_id': stableUserId,
      if (displayName != null) 'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PublicAccountsCompanion copyWith({
    Value<String>? source,
    Value<String>? stableUserId,
    Value<String>? displayName,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PublicAccountsCompanion(
      source: source ?? this.source,
      stableUserId: stableUserId ?? this.stableUserId,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (stableUserId.present) {
      map['stable_user_id'] = Variable<String>(stableUserId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PublicAccountsCompanion(')
          ..write('source: $source, ')
          ..write('stableUserId: $stableUserId, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  @override
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueTypeMeta = const VerificationMeta(
    'valueType',
  );
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
    'value_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonValueMeta = const VerificationMeta(
    'jsonValue',
  );
  @override
  late final GeneratedColumn<String> jsonValue = GeneratedColumn<String>(
    'json_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    settingKey,
    valueType,
    jsonValue,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('value_type')) {
      context.handle(
        _valueTypeMeta,
        valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('json_value')) {
      context.handle(
        _jsonValueMeta,
        jsonValue.isAcceptableOrUnknown(data['json_value']!, _jsonValueMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonValueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      valueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_type'],
      )!,
      jsonValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String settingKey;
  final String valueType;
  final String jsonValue;
  final int updatedAt;
  const AppSetting({
    required this.settingKey,
    required this.valueType,
    required this.jsonValue,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['value_type'] = Variable<String>(valueType);
    map['json_value'] = Variable<String>(jsonValue);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      settingKey: Value(settingKey),
      valueType: Value(valueType),
      jsonValue: Value(jsonValue),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      settingKey: serializer.fromJson<String>(json['settingKey']),
      valueType: serializer.fromJson<String>(json['valueType']),
      jsonValue: serializer.fromJson<String>(json['jsonValue']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingKey': serializer.toJson<String>(settingKey),
      'valueType': serializer.toJson<String>(valueType),
      'jsonValue': serializer.toJson<String>(jsonValue),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSetting copyWith({
    String? settingKey,
    String? valueType,
    String? jsonValue,
    int? updatedAt,
  }) => AppSetting(
    settingKey: settingKey ?? this.settingKey,
    valueType: valueType ?? this.valueType,
    jsonValue: jsonValue ?? this.jsonValue,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      jsonValue: data.jsonValue.present ? data.jsonValue.value : this.jsonValue,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('settingKey: $settingKey, ')
          ..write('valueType: $valueType, ')
          ..write('jsonValue: $jsonValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, valueType, jsonValue, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.settingKey == this.settingKey &&
          other.valueType == this.valueType &&
          other.jsonValue == this.jsonValue &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> settingKey;
  final Value<String> valueType;
  final Value<String> jsonValue;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.settingKey = const Value.absent(),
    this.valueType = const Value.absent(),
    this.jsonValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String settingKey,
    required String valueType,
    required String jsonValue,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : settingKey = Value(settingKey),
       valueType = Value(valueType),
       jsonValue = Value(jsonValue),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? settingKey,
    Expression<String>? valueType,
    Expression<String>? jsonValue,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (valueType != null) 'value_type': valueType,
      if (jsonValue != null) 'json_value': jsonValue,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? valueType,
    Value<String>? jsonValue,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      settingKey: settingKey ?? this.settingKey,
      valueType: valueType ?? this.valueType,
      jsonValue: jsonValue ?? this.jsonValue,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (jsonValue.present) {
      map['json_value'] = Variable<String>(jsonValue.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('valueType: $valueType, ')
          ..write('jsonValue: $jsonValue, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MigrationLedgerTable extends MigrationLedger
    with TableInfo<$MigrationLedgerTable, MigrationLedgerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _migrationKeyMeta = const VerificationMeta(
    'migrationKey',
  );
  @override
  late final GeneratedColumn<String> migrationKey = GeneratedColumn<String>(
    'migration_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFingerprintMeta = const VerificationMeta(
    'sourceFingerprint',
  );
  @override
  late final GeneratedColumn<String> sourceFingerprint =
      GeneratedColumn<String>(
        'source_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _migrationVersionMeta = const VerificationMeta(
    'migrationVersion',
  );
  @override
  late final GeneratedColumn<int> migrationVersion = GeneratedColumn<int>(
    'migration_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _migratedEntriesMeta = const VerificationMeta(
    'migratedEntries',
  );
  @override
  late final GeneratedColumn<int> migratedEntries = GeneratedColumn<int>(
    'migrated_entries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    migrationKey,
    sourceFingerprint,
    migrationVersion,
    status,
    migratedEntries,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationLedgerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('migration_key')) {
      context.handle(
        _migrationKeyMeta,
        migrationKey.isAcceptableOrUnknown(
          data['migration_key']!,
          _migrationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationKeyMeta);
    }
    if (data.containsKey('source_fingerprint')) {
      context.handle(
        _sourceFingerprintMeta,
        sourceFingerprint.isAcceptableOrUnknown(
          data['source_fingerprint']!,
          _sourceFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceFingerprintMeta);
    }
    if (data.containsKey('migration_version')) {
      context.handle(
        _migrationVersionMeta,
        migrationVersion.isAcceptableOrUnknown(
          data['migration_version']!,
          _migrationVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationVersionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('migrated_entries')) {
      context.handle(
        _migratedEntriesMeta,
        migratedEntries.isAcceptableOrUnknown(
          data['migrated_entries']!,
          _migratedEntriesMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {migrationKey, sourceFingerprint};
  @override
  MigrationLedgerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationLedgerData(
      migrationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migration_key'],
      )!,
      sourceFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_fingerprint'],
      )!,
      migrationVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}migration_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      migratedEntries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}migrated_entries'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      )!,
    );
  }

  @override
  $MigrationLedgerTable createAlias(String alias) {
    return $MigrationLedgerTable(attachedDatabase, alias);
  }
}

class MigrationLedgerData extends DataClass
    implements Insertable<MigrationLedgerData> {
  final String migrationKey;
  final String sourceFingerprint;
  final int migrationVersion;
  final String status;
  final int migratedEntries;
  final int completedAt;
  const MigrationLedgerData({
    required this.migrationKey,
    required this.sourceFingerprint,
    required this.migrationVersion,
    required this.status,
    required this.migratedEntries,
    required this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['migration_key'] = Variable<String>(migrationKey);
    map['source_fingerprint'] = Variable<String>(sourceFingerprint);
    map['migration_version'] = Variable<int>(migrationVersion);
    map['status'] = Variable<String>(status);
    map['migrated_entries'] = Variable<int>(migratedEntries);
    map['completed_at'] = Variable<int>(completedAt);
    return map;
  }

  MigrationLedgerCompanion toCompanion(bool nullToAbsent) {
    return MigrationLedgerCompanion(
      migrationKey: Value(migrationKey),
      sourceFingerprint: Value(sourceFingerprint),
      migrationVersion: Value(migrationVersion),
      status: Value(status),
      migratedEntries: Value(migratedEntries),
      completedAt: Value(completedAt),
    );
  }

  factory MigrationLedgerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationLedgerData(
      migrationKey: serializer.fromJson<String>(json['migrationKey']),
      sourceFingerprint: serializer.fromJson<String>(json['sourceFingerprint']),
      migrationVersion: serializer.fromJson<int>(json['migrationVersion']),
      status: serializer.fromJson<String>(json['status']),
      migratedEntries: serializer.fromJson<int>(json['migratedEntries']),
      completedAt: serializer.fromJson<int>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'migrationKey': serializer.toJson<String>(migrationKey),
      'sourceFingerprint': serializer.toJson<String>(sourceFingerprint),
      'migrationVersion': serializer.toJson<int>(migrationVersion),
      'status': serializer.toJson<String>(status),
      'migratedEntries': serializer.toJson<int>(migratedEntries),
      'completedAt': serializer.toJson<int>(completedAt),
    };
  }

  MigrationLedgerData copyWith({
    String? migrationKey,
    String? sourceFingerprint,
    int? migrationVersion,
    String? status,
    int? migratedEntries,
    int? completedAt,
  }) => MigrationLedgerData(
    migrationKey: migrationKey ?? this.migrationKey,
    sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
    migrationVersion: migrationVersion ?? this.migrationVersion,
    status: status ?? this.status,
    migratedEntries: migratedEntries ?? this.migratedEntries,
    completedAt: completedAt ?? this.completedAt,
  );
  MigrationLedgerData copyWithCompanion(MigrationLedgerCompanion data) {
    return MigrationLedgerData(
      migrationKey: data.migrationKey.present
          ? data.migrationKey.value
          : this.migrationKey,
      sourceFingerprint: data.sourceFingerprint.present
          ? data.sourceFingerprint.value
          : this.sourceFingerprint,
      migrationVersion: data.migrationVersion.present
          ? data.migrationVersion.value
          : this.migrationVersion,
      status: data.status.present ? data.status.value : this.status,
      migratedEntries: data.migratedEntries.present
          ? data.migratedEntries.value
          : this.migratedEntries,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationLedgerData(')
          ..write('migrationKey: $migrationKey, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('migrationVersion: $migrationVersion, ')
          ..write('status: $status, ')
          ..write('migratedEntries: $migratedEntries, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    migrationKey,
    sourceFingerprint,
    migrationVersion,
    status,
    migratedEntries,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationLedgerData &&
          other.migrationKey == this.migrationKey &&
          other.sourceFingerprint == this.sourceFingerprint &&
          other.migrationVersion == this.migrationVersion &&
          other.status == this.status &&
          other.migratedEntries == this.migratedEntries &&
          other.completedAt == this.completedAt);
}

class MigrationLedgerCompanion extends UpdateCompanion<MigrationLedgerData> {
  final Value<String> migrationKey;
  final Value<String> sourceFingerprint;
  final Value<int> migrationVersion;
  final Value<String> status;
  final Value<int> migratedEntries;
  final Value<int> completedAt;
  final Value<int> rowid;
  const MigrationLedgerCompanion({
    this.migrationKey = const Value.absent(),
    this.sourceFingerprint = const Value.absent(),
    this.migrationVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.migratedEntries = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationLedgerCompanion.insert({
    required String migrationKey,
    required String sourceFingerprint,
    required int migrationVersion,
    required String status,
    this.migratedEntries = const Value.absent(),
    required int completedAt,
    this.rowid = const Value.absent(),
  }) : migrationKey = Value(migrationKey),
       sourceFingerprint = Value(sourceFingerprint),
       migrationVersion = Value(migrationVersion),
       status = Value(status),
       completedAt = Value(completedAt);
  static Insertable<MigrationLedgerData> custom({
    Expression<String>? migrationKey,
    Expression<String>? sourceFingerprint,
    Expression<int>? migrationVersion,
    Expression<String>? status,
    Expression<int>? migratedEntries,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (migrationKey != null) 'migration_key': migrationKey,
      if (sourceFingerprint != null) 'source_fingerprint': sourceFingerprint,
      if (migrationVersion != null) 'migration_version': migrationVersion,
      if (status != null) 'status': status,
      if (migratedEntries != null) 'migrated_entries': migratedEntries,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationLedgerCompanion copyWith({
    Value<String>? migrationKey,
    Value<String>? sourceFingerprint,
    Value<int>? migrationVersion,
    Value<String>? status,
    Value<int>? migratedEntries,
    Value<int>? completedAt,
    Value<int>? rowid,
  }) {
    return MigrationLedgerCompanion(
      migrationKey: migrationKey ?? this.migrationKey,
      sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
      migrationVersion: migrationVersion ?? this.migrationVersion,
      status: status ?? this.status,
      migratedEntries: migratedEntries ?? this.migratedEntries,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (migrationKey.present) {
      map['migration_key'] = Variable<String>(migrationKey.value);
    }
    if (sourceFingerprint.present) {
      map['source_fingerprint'] = Variable<String>(sourceFingerprint.value);
    }
    if (migrationVersion.present) {
      map['migration_version'] = Variable<int>(migrationVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (migratedEntries.present) {
      map['migrated_entries'] = Variable<int>(migratedEntries.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationLedgerCompanion(')
          ..write('migrationKey: $migrationKey, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('migrationVersion: $migrationVersion, ')
          ..write('status: $status, ')
          ..write('migratedEntries: $migratedEntries, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImageCacheEntriesTable extends ImageCacheEntries
    with TableInfo<$ImageCacheEntriesTable, ImageCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImageCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageKeyMeta = const VerificationMeta(
    'storageKey',
  );
  @override
  late final GeneratedColumn<String> storageKey = GeneratedColumn<String>(
    'storage_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _backendMeta = const VerificationMeta(
    'backend',
  );
  @override
  late final GeneratedColumn<String> backend = GeneratedColumn<String>(
    'backend',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<String> lastModified = GeneratedColumn<String>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<int> lastAccessedAt = GeneratedColumn<int>(
    'last_accessed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    imageUrl,
    storageKey,
    backend,
    byteSize,
    etag,
    lastModified,
    fetchedAt,
    staleAt,
    expiresAt,
    lastAccessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'image_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_imageUrlMeta);
    }
    if (data.containsKey('storage_key')) {
      context.handle(
        _storageKeyMeta,
        storageKey.isAcceptableOrUnknown(data['storage_key']!, _storageKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_storageKeyMeta);
    }
    if (data.containsKey('backend')) {
      context.handle(
        _backendMeta,
        backend.isAcceptableOrUnknown(data['backend']!, _backendMeta),
      );
    } else if (isInserting) {
      context.missing(_backendMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
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
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {imageUrl};
  @override
  ImageCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageCacheEntry(
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      )!,
      storageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_key'],
      )!,
      backend: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backend'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified'],
      ),
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
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_accessed_at'],
      )!,
    );
  }

  @override
  $ImageCacheEntriesTable createAlias(String alias) {
    return $ImageCacheEntriesTable(attachedDatabase, alias);
  }
}

class ImageCacheEntry extends DataClass implements Insertable<ImageCacheEntry> {
  final String imageUrl;
  final String storageKey;
  final String backend;
  final int byteSize;
  final String? etag;
  final String? lastModified;
  final int fetchedAt;
  final int staleAt;
  final int expiresAt;
  final int lastAccessedAt;
  const ImageCacheEntry({
    required this.imageUrl,
    required this.storageKey,
    required this.backend,
    required this.byteSize,
    this.etag,
    this.lastModified,
    required this.fetchedAt,
    required this.staleAt,
    required this.expiresAt,
    required this.lastAccessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['image_url'] = Variable<String>(imageUrl);
    map['storage_key'] = Variable<String>(storageKey);
    map['backend'] = Variable<String>(backend);
    map['byte_size'] = Variable<int>(byteSize);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<String>(lastModified);
    }
    map['fetched_at'] = Variable<int>(fetchedAt);
    map['stale_at'] = Variable<int>(staleAt);
    map['expires_at'] = Variable<int>(expiresAt);
    map['last_accessed_at'] = Variable<int>(lastAccessedAt);
    return map;
  }

  ImageCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return ImageCacheEntriesCompanion(
      imageUrl: Value(imageUrl),
      storageKey: Value(storageKey),
      backend: Value(backend),
      byteSize: Value(byteSize),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      fetchedAt: Value(fetchedAt),
      staleAt: Value(staleAt),
      expiresAt: Value(expiresAt),
      lastAccessedAt: Value(lastAccessedAt),
    );
  }

  factory ImageCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageCacheEntry(
      imageUrl: serializer.fromJson<String>(json['imageUrl']),
      storageKey: serializer.fromJson<String>(json['storageKey']),
      backend: serializer.fromJson<String>(json['backend']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastModified: serializer.fromJson<String?>(json['lastModified']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
      staleAt: serializer.fromJson<int>(json['staleAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
      lastAccessedAt: serializer.fromJson<int>(json['lastAccessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'imageUrl': serializer.toJson<String>(imageUrl),
      'storageKey': serializer.toJson<String>(storageKey),
      'backend': serializer.toJson<String>(backend),
      'byteSize': serializer.toJson<int>(byteSize),
      'etag': serializer.toJson<String?>(etag),
      'lastModified': serializer.toJson<String?>(lastModified),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
      'staleAt': serializer.toJson<int>(staleAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
      'lastAccessedAt': serializer.toJson<int>(lastAccessedAt),
    };
  }

  ImageCacheEntry copyWith({
    String? imageUrl,
    String? storageKey,
    String? backend,
    int? byteSize,
    Value<String?> etag = const Value.absent(),
    Value<String?> lastModified = const Value.absent(),
    int? fetchedAt,
    int? staleAt,
    int? expiresAt,
    int? lastAccessedAt,
  }) => ImageCacheEntry(
    imageUrl: imageUrl ?? this.imageUrl,
    storageKey: storageKey ?? this.storageKey,
    backend: backend ?? this.backend,
    byteSize: byteSize ?? this.byteSize,
    etag: etag.present ? etag.value : this.etag,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    staleAt: staleAt ?? this.staleAt,
    expiresAt: expiresAt ?? this.expiresAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
  );
  ImageCacheEntry copyWithCompanion(ImageCacheEntriesCompanion data) {
    return ImageCacheEntry(
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      storageKey: data.storageKey.present
          ? data.storageKey.value
          : this.storageKey,
      backend: data.backend.present ? data.backend.value : this.backend,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      staleAt: data.staleAt.present ? data.staleAt.value : this.staleAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageCacheEntry(')
          ..write('imageUrl: $imageUrl, ')
          ..write('storageKey: $storageKey, ')
          ..write('backend: $backend, ')
          ..write('byteSize: $byteSize, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    imageUrl,
    storageKey,
    backend,
    byteSize,
    etag,
    lastModified,
    fetchedAt,
    staleAt,
    expiresAt,
    lastAccessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageCacheEntry &&
          other.imageUrl == this.imageUrl &&
          other.storageKey == this.storageKey &&
          other.backend == this.backend &&
          other.byteSize == this.byteSize &&
          other.etag == this.etag &&
          other.lastModified == this.lastModified &&
          other.fetchedAt == this.fetchedAt &&
          other.staleAt == this.staleAt &&
          other.expiresAt == this.expiresAt &&
          other.lastAccessedAt == this.lastAccessedAt);
}

class ImageCacheEntriesCompanion extends UpdateCompanion<ImageCacheEntry> {
  final Value<String> imageUrl;
  final Value<String> storageKey;
  final Value<String> backend;
  final Value<int> byteSize;
  final Value<String?> etag;
  final Value<String?> lastModified;
  final Value<int> fetchedAt;
  final Value<int> staleAt;
  final Value<int> expiresAt;
  final Value<int> lastAccessedAt;
  final Value<int> rowid;
  const ImageCacheEntriesCompanion({
    this.imageUrl = const Value.absent(),
    this.storageKey = const Value.absent(),
    this.backend = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.staleAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImageCacheEntriesCompanion.insert({
    required String imageUrl,
    required String storageKey,
    required String backend,
    required int byteSize,
    this.etag = const Value.absent(),
    this.lastModified = const Value.absent(),
    required int fetchedAt,
    required int staleAt,
    required int expiresAt,
    required int lastAccessedAt,
    this.rowid = const Value.absent(),
  }) : imageUrl = Value(imageUrl),
       storageKey = Value(storageKey),
       backend = Value(backend),
       byteSize = Value(byteSize),
       fetchedAt = Value(fetchedAt),
       staleAt = Value(staleAt),
       expiresAt = Value(expiresAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<ImageCacheEntry> custom({
    Expression<String>? imageUrl,
    Expression<String>? storageKey,
    Expression<String>? backend,
    Expression<int>? byteSize,
    Expression<String>? etag,
    Expression<String>? lastModified,
    Expression<int>? fetchedAt,
    Expression<int>? staleAt,
    Expression<int>? expiresAt,
    Expression<int>? lastAccessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (imageUrl != null) 'image_url': imageUrl,
      if (storageKey != null) 'storage_key': storageKey,
      if (backend != null) 'backend': backend,
      if (byteSize != null) 'byte_size': byteSize,
      if (etag != null) 'etag': etag,
      if (lastModified != null) 'last_modified': lastModified,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (staleAt != null) 'stale_at': staleAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImageCacheEntriesCompanion copyWith({
    Value<String>? imageUrl,
    Value<String>? storageKey,
    Value<String>? backend,
    Value<int>? byteSize,
    Value<String?>? etag,
    Value<String?>? lastModified,
    Value<int>? fetchedAt,
    Value<int>? staleAt,
    Value<int>? expiresAt,
    Value<int>? lastAccessedAt,
    Value<int>? rowid,
  }) {
    return ImageCacheEntriesCompanion(
      imageUrl: imageUrl ?? this.imageUrl,
      storageKey: storageKey ?? this.storageKey,
      backend: backend ?? this.backend,
      byteSize: byteSize ?? this.byteSize,
      etag: etag ?? this.etag,
      lastModified: lastModified ?? this.lastModified,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      staleAt: staleAt ?? this.staleAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (storageKey.present) {
      map['storage_key'] = Variable<String>(storageKey.value);
    }
    if (backend.present) {
      map['backend'] = Variable<String>(backend.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<String>(lastModified.value);
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
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<int>(lastAccessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImageCacheEntriesCompanion(')
          ..write('imageUrl: $imageUrl, ')
          ..write('storageKey: $storageKey, ')
          ..write('backend: $backend, ')
          ..write('byteSize: $byteSize, ')
          ..write('etag: $etag, ')
          ..write('lastModified: $lastModified, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('staleAt: $staleAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MioAniDatabase extends GeneratedDatabase {
  _$MioAniDatabase(QueryExecutor e) : super(e);
  $MioAniDatabaseManager get managers => $MioAniDatabaseManager(this);
  late final $StructuredCacheEntriesTable structuredCacheEntries =
      $StructuredCacheEntriesTable(this);
  late final $AnimeIdentitiesTable animeIdentities = $AnimeIdentitiesTable(
    this,
  );
  late final $SourceEntitiesTable sourceEntities = $SourceEntitiesTable(this);
  late final $LegacyIdentityLinksTable legacyIdentityLinks =
      $LegacyIdentityLinksTable(this);
  late final $LibraryEntriesTable libraryEntries = $LibraryEntriesTable(this);
  late final $PublicAccountsTable publicAccounts = $PublicAccountsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $MigrationLedgerTable migrationLedger = $MigrationLedgerTable(
    this,
  );
  late final $ImageCacheEntriesTable imageCacheEntries =
      $ImageCacheEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    structuredCacheEntries,
    animeIdentities,
    sourceEntities,
    legacyIdentityLinks,
    libraryEntries,
    publicAccounts,
    appSettings,
    migrationLedger,
    imageCacheEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime_identities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('source_entities', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime_identities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('legacy_identity_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'anime_identities',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('library_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$StructuredCacheEntriesTableCreateCompanionBuilder =
    StructuredCacheEntriesCompanion Function({
      required String cacheKey,
      required String payload,
      required int fetchedAt,
      required int staleAt,
      required int expiresAt,
      Value<String> category,
      Value<int> byteSize,
      Value<int> lastAccessedAt,
      Value<int> rowid,
    });
typedef $$StructuredCacheEntriesTableUpdateCompanionBuilder =
    StructuredCacheEntriesCompanion Function({
      Value<String> cacheKey,
      Value<String> payload,
      Value<int> fetchedAt,
      Value<int> staleAt,
      Value<int> expiresAt,
      Value<String> category,
      Value<int> byteSize,
      Value<int> lastAccessedAt,
      Value<int> rowid,
    });

class $$StructuredCacheEntriesTableFilterComposer
    extends Composer<_$MioAniDatabase, $StructuredCacheEntriesTable> {
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StructuredCacheEntriesTableOrderingComposer
    extends Composer<_$MioAniDatabase, $StructuredCacheEntriesTable> {
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StructuredCacheEntriesTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $StructuredCacheEntriesTable> {
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );
}

class $$StructuredCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
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
              _$MioAniDatabase,
              $StructuredCacheEntriesTable,
              StructuredCacheEntry
            >,
          ),
          StructuredCacheEntry,
          PrefetchHooks Function()
        > {
  $$StructuredCacheEntriesTableTableManager(
    _$MioAniDatabase db,
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
                Value<String> category = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StructuredCacheEntriesCompanion(
                cacheKey: cacheKey,
                payload: payload,
                fetchedAt: fetchedAt,
                staleAt: staleAt,
                expiresAt: expiresAt,
                category: category,
                byteSize: byteSize,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String payload,
                required int fetchedAt,
                required int staleAt,
                required int expiresAt,
                Value<String> category = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StructuredCacheEntriesCompanion.insert(
                cacheKey: cacheKey,
                payload: payload,
                fetchedAt: fetchedAt,
                staleAt: staleAt,
                expiresAt: expiresAt,
                category: category,
                byteSize: byteSize,
                lastAccessedAt: lastAccessedAt,
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
      _$MioAniDatabase,
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
          _$MioAniDatabase,
          $StructuredCacheEntriesTable,
          StructuredCacheEntry
        >,
      ),
      StructuredCacheEntry,
      PrefetchHooks Function()
    >;
typedef $$AnimeIdentitiesTableCreateCompanionBuilder =
    AnimeIdentitiesCompanion Function({
      required String identityId,
      Value<String> canonicalTitle,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AnimeIdentitiesTableUpdateCompanionBuilder =
    AnimeIdentitiesCompanion Function({
      Value<String> identityId,
      Value<String> canonicalTitle,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$AnimeIdentitiesTableReferences
    extends
        BaseReferences<_$MioAniDatabase, $AnimeIdentitiesTable, AnimeIdentity> {
  $$AnimeIdentitiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SourceEntitiesTable, List<SourceEntity>>
  _sourceEntitiesRefsTable(_$MioAniDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sourceEntities,
        aliasName:
            'anime_identities__identity_id__source_entities__identity_id',
      );

  $$SourceEntitiesTableProcessedTableManager get sourceEntitiesRefs {
    final manager = $$SourceEntitiesTableTableManager($_db, $_db.sourceEntities)
        .filter(
          (f) => f.identityId.identityId.sqlEquals(
            $_itemColumn<String>('identity_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_sourceEntitiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LegacyIdentityLinksTable,
    List<LegacyIdentityLink>
  >
  _legacyIdentityLinksRefsTable(_$MioAniDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.legacyIdentityLinks,
        aliasName:
            'anime_identities__identity_id__legacy_identity_links__identity_id',
      );

  $$LegacyIdentityLinksTableProcessedTableManager get legacyIdentityLinksRefs {
    final manager =
        $$LegacyIdentityLinksTableTableManager(
          $_db,
          $_db.legacyIdentityLinks,
        ).filter(
          (f) => f.identityId.identityId.sqlEquals(
            $_itemColumn<String>('identity_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _legacyIdentityLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LibraryEntriesTable, List<LibraryEntry>>
  _libraryEntriesRefsTable(_$MioAniDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.libraryEntries,
        aliasName:
            'anime_identities__identity_id__library_entries__identity_id',
      );

  $$LibraryEntriesTableProcessedTableManager get libraryEntriesRefs {
    final manager = $$LibraryEntriesTableTableManager($_db, $_db.libraryEntries)
        .filter(
          (f) => f.identityId.identityId.sqlEquals(
            $_itemColumn<String>('identity_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_libraryEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AnimeIdentitiesTableFilterComposer
    extends Composer<_$MioAniDatabase, $AnimeIdentitiesTable> {
  $$AnimeIdentitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalTitle => $composableBuilder(
    column: $table.canonicalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sourceEntitiesRefs(
    Expression<bool> Function($$SourceEntitiesTableFilterComposer f) f,
  ) {
    final $$SourceEntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.sourceEntities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceEntitiesTableFilterComposer(
            $db: $db,
            $table: $db.sourceEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> legacyIdentityLinksRefs(
    Expression<bool> Function($$LegacyIdentityLinksTableFilterComposer f) f,
  ) {
    final $$LegacyIdentityLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.legacyIdentityLinks,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LegacyIdentityLinksTableFilterComposer(
            $db: $db,
            $table: $db.legacyIdentityLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> libraryEntriesRefs(
    Expression<bool> Function($$LibraryEntriesTableFilterComposer f) f,
  ) {
    final $$LibraryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnimeIdentitiesTableOrderingComposer
    extends Composer<_$MioAniDatabase, $AnimeIdentitiesTable> {
  $$AnimeIdentitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalTitle => $composableBuilder(
    column: $table.canonicalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnimeIdentitiesTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $AnimeIdentitiesTable> {
  $$AnimeIdentitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get identityId => $composableBuilder(
    column: $table.identityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get canonicalTitle => $composableBuilder(
    column: $table.canonicalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> sourceEntitiesRefs<T extends Object>(
    Expression<T> Function($$SourceEntitiesTableAnnotationComposer a) f,
  ) {
    final $$SourceEntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.sourceEntities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceEntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.sourceEntities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> legacyIdentityLinksRefs<T extends Object>(
    Expression<T> Function($$LegacyIdentityLinksTableAnnotationComposer a) f,
  ) {
    final $$LegacyIdentityLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.identityId,
          referencedTable: $db.legacyIdentityLinks,
          getReferencedColumn: (t) => t.identityId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LegacyIdentityLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.legacyIdentityLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> libraryEntriesRefs<T extends Object>(
    Expression<T> Function($$LibraryEntriesTableAnnotationComposer a) f,
  ) {
    final $$LibraryEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.libraryEntries,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnimeIdentitiesTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
          $AnimeIdentitiesTable,
          AnimeIdentity,
          $$AnimeIdentitiesTableFilterComposer,
          $$AnimeIdentitiesTableOrderingComposer,
          $$AnimeIdentitiesTableAnnotationComposer,
          $$AnimeIdentitiesTableCreateCompanionBuilder,
          $$AnimeIdentitiesTableUpdateCompanionBuilder,
          (AnimeIdentity, $$AnimeIdentitiesTableReferences),
          AnimeIdentity,
          PrefetchHooks Function({
            bool sourceEntitiesRefs,
            bool legacyIdentityLinksRefs,
            bool libraryEntriesRefs,
          })
        > {
  $$AnimeIdentitiesTableTableManager(
    _$MioAniDatabase db,
    $AnimeIdentitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnimeIdentitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnimeIdentitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnimeIdentitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> identityId = const Value.absent(),
                Value<String> canonicalTitle = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnimeIdentitiesCompanion(
                identityId: identityId,
                canonicalTitle: canonicalTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String identityId,
                Value<String> canonicalTitle = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AnimeIdentitiesCompanion.insert(
                identityId: identityId,
                canonicalTitle: canonicalTitle,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnimeIdentitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourceEntitiesRefs = false,
                legacyIdentityLinksRefs = false,
                libraryEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sourceEntitiesRefs) db.sourceEntities,
                    if (legacyIdentityLinksRefs) db.legacyIdentityLinks,
                    if (libraryEntriesRefs) db.libraryEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sourceEntitiesRefs)
                        await $_getPrefetchedData<
                          AnimeIdentity,
                          $AnimeIdentitiesTable,
                          SourceEntity
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeIdentitiesTableReferences
                              ._sourceEntitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeIdentitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).sourceEntitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.identityId == item.identityId,
                              ),
                          typedResults: items,
                        ),
                      if (legacyIdentityLinksRefs)
                        await $_getPrefetchedData<
                          AnimeIdentity,
                          $AnimeIdentitiesTable,
                          LegacyIdentityLink
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeIdentitiesTableReferences
                              ._legacyIdentityLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeIdentitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).legacyIdentityLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.identityId == item.identityId,
                              ),
                          typedResults: items,
                        ),
                      if (libraryEntriesRefs)
                        await $_getPrefetchedData<
                          AnimeIdentity,
                          $AnimeIdentitiesTable,
                          LibraryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeIdentitiesTableReferences
                              ._libraryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeIdentitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).libraryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.identityId == item.identityId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AnimeIdentitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$MioAniDatabase,
      $AnimeIdentitiesTable,
      AnimeIdentity,
      $$AnimeIdentitiesTableFilterComposer,
      $$AnimeIdentitiesTableOrderingComposer,
      $$AnimeIdentitiesTableAnnotationComposer,
      $$AnimeIdentitiesTableCreateCompanionBuilder,
      $$AnimeIdentitiesTableUpdateCompanionBuilder,
      (AnimeIdentity, $$AnimeIdentitiesTableReferences),
      AnimeIdentity,
      PrefetchHooks Function({
        bool sourceEntitiesRefs,
        bool legacyIdentityLinksRefs,
        bool libraryEntriesRefs,
      })
    >;
typedef $$SourceEntitiesTableCreateCompanionBuilder =
    SourceEntitiesCompanion Function({
      required String source,
      required String sourceId,
      required String identityId,
      Value<String> title,
      Value<String> originalTitle,
      Value<String?> imageUrl,
      Value<int?> year,
      Value<int?> episodes,
      required int observedAt,
      Value<int> rowid,
    });
typedef $$SourceEntitiesTableUpdateCompanionBuilder =
    SourceEntitiesCompanion Function({
      Value<String> source,
      Value<String> sourceId,
      Value<String> identityId,
      Value<String> title,
      Value<String> originalTitle,
      Value<String?> imageUrl,
      Value<int?> year,
      Value<int?> episodes,
      Value<int> observedAt,
      Value<int> rowid,
    });

final class $$SourceEntitiesTableReferences
    extends
        BaseReferences<_$MioAniDatabase, $SourceEntitiesTable, SourceEntity> {
  $$SourceEntitiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnimeIdentitiesTable _identityIdTable(_$MioAniDatabase db) =>
      db.animeIdentities.createAlias(
        'source_entities__identity_id__anime_identities__identity_id',
      );

  $$AnimeIdentitiesTableProcessedTableManager get identityId {
    final $_column = $_itemColumn<String>('identity_id')!;

    final manager = $$AnimeIdentitiesTableTableManager(
      $_db,
      $_db.animeIdentities,
    ).filter((f) => f.identityId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_identityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SourceEntitiesTableFilterComposer
    extends Composer<_$MioAniDatabase, $SourceEntitiesTable> {
  $$SourceEntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodes => $composableBuilder(
    column: $table.episodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeIdentitiesTableFilterComposer get identityId {
    final $$AnimeIdentitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableFilterComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceEntitiesTableOrderingComposer
    extends Composer<_$MioAniDatabase, $SourceEntitiesTable> {
  $$SourceEntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodes => $composableBuilder(
    column: $table.episodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeIdentitiesTableOrderingComposer get identityId {
    final $$AnimeIdentitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableOrderingComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceEntitiesTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $SourceEntitiesTable> {
  $$SourceEntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get episodes =>
      $composableBuilder(column: $table.episodes, builder: (column) => column);

  GeneratedColumn<int> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  $$AnimeIdentitiesTableAnnotationComposer get identityId {
    final $$AnimeIdentitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceEntitiesTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
          $SourceEntitiesTable,
          SourceEntity,
          $$SourceEntitiesTableFilterComposer,
          $$SourceEntitiesTableOrderingComposer,
          $$SourceEntitiesTableAnnotationComposer,
          $$SourceEntitiesTableCreateCompanionBuilder,
          $$SourceEntitiesTableUpdateCompanionBuilder,
          (SourceEntity, $$SourceEntitiesTableReferences),
          SourceEntity,
          PrefetchHooks Function({bool identityId})
        > {
  $$SourceEntitiesTableTableManager(
    _$MioAniDatabase db,
    $SourceEntitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceEntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourceEntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourceEntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> source = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> identityId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> originalTitle = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int?> episodes = const Value.absent(),
                Value<int> observedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceEntitiesCompanion(
                source: source,
                sourceId: sourceId,
                identityId: identityId,
                title: title,
                originalTitle: originalTitle,
                imageUrl: imageUrl,
                year: year,
                episodes: episodes,
                observedAt: observedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String source,
                required String sourceId,
                required String identityId,
                Value<String> title = const Value.absent(),
                Value<String> originalTitle = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<int?> episodes = const Value.absent(),
                required int observedAt,
                Value<int> rowid = const Value.absent(),
              }) => SourceEntitiesCompanion.insert(
                source: source,
                sourceId: sourceId,
                identityId: identityId,
                title: title,
                originalTitle: originalTitle,
                imageUrl: imageUrl,
                year: year,
                episodes: episodes,
                observedAt: observedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SourceEntitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({identityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (identityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.identityId,
                                referencedTable: $$SourceEntitiesTableReferences
                                    ._identityIdTable(db),
                                referencedColumn:
                                    $$SourceEntitiesTableReferences
                                        ._identityIdTable(db)
                                        .identityId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SourceEntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$MioAniDatabase,
      $SourceEntitiesTable,
      SourceEntity,
      $$SourceEntitiesTableFilterComposer,
      $$SourceEntitiesTableOrderingComposer,
      $$SourceEntitiesTableAnnotationComposer,
      $$SourceEntitiesTableCreateCompanionBuilder,
      $$SourceEntitiesTableUpdateCompanionBuilder,
      (SourceEntity, $$SourceEntitiesTableReferences),
      SourceEntity,
      PrefetchHooks Function({bool identityId})
    >;
typedef $$LegacyIdentityLinksTableCreateCompanionBuilder =
    LegacyIdentityLinksCompanion Function({
      required String identityId,
      required String linkedSourceId,
      Value<String> evidence,
      Value<int> rowid,
    });
typedef $$LegacyIdentityLinksTableUpdateCompanionBuilder =
    LegacyIdentityLinksCompanion Function({
      Value<String> identityId,
      Value<String> linkedSourceId,
      Value<String> evidence,
      Value<int> rowid,
    });

final class $$LegacyIdentityLinksTableReferences
    extends
        BaseReferences<
          _$MioAniDatabase,
          $LegacyIdentityLinksTable,
          LegacyIdentityLink
        > {
  $$LegacyIdentityLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnimeIdentitiesTable _identityIdTable(_$MioAniDatabase db) =>
      db.animeIdentities.createAlias(
        'legacy_identity_links__identity_id__anime_identities__identity_id',
      );

  $$AnimeIdentitiesTableProcessedTableManager get identityId {
    final $_column = $_itemColumn<String>('identity_id')!;

    final manager = $$AnimeIdentitiesTableTableManager(
      $_db,
      $_db.animeIdentities,
    ).filter((f) => f.identityId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_identityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LegacyIdentityLinksTableFilterComposer
    extends Composer<_$MioAniDatabase, $LegacyIdentityLinksTable> {
  $$LegacyIdentityLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get linkedSourceId => $composableBuilder(
    column: $table.linkedSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidence => $composableBuilder(
    column: $table.evidence,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeIdentitiesTableFilterComposer get identityId {
    final $$AnimeIdentitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableFilterComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LegacyIdentityLinksTableOrderingComposer
    extends Composer<_$MioAniDatabase, $LegacyIdentityLinksTable> {
  $$LegacyIdentityLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get linkedSourceId => $composableBuilder(
    column: $table.linkedSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidence => $composableBuilder(
    column: $table.evidence,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeIdentitiesTableOrderingComposer get identityId {
    final $$AnimeIdentitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableOrderingComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LegacyIdentityLinksTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $LegacyIdentityLinksTable> {
  $$LegacyIdentityLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get linkedSourceId => $composableBuilder(
    column: $table.linkedSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidence =>
      $composableBuilder(column: $table.evidence, builder: (column) => column);

  $$AnimeIdentitiesTableAnnotationComposer get identityId {
    final $$AnimeIdentitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LegacyIdentityLinksTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
          $LegacyIdentityLinksTable,
          LegacyIdentityLink,
          $$LegacyIdentityLinksTableFilterComposer,
          $$LegacyIdentityLinksTableOrderingComposer,
          $$LegacyIdentityLinksTableAnnotationComposer,
          $$LegacyIdentityLinksTableCreateCompanionBuilder,
          $$LegacyIdentityLinksTableUpdateCompanionBuilder,
          (LegacyIdentityLink, $$LegacyIdentityLinksTableReferences),
          LegacyIdentityLink,
          PrefetchHooks Function({bool identityId})
        > {
  $$LegacyIdentityLinksTableTableManager(
    _$MioAniDatabase db,
    $LegacyIdentityLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LegacyIdentityLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LegacyIdentityLinksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LegacyIdentityLinksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> identityId = const Value.absent(),
                Value<String> linkedSourceId = const Value.absent(),
                Value<String> evidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LegacyIdentityLinksCompanion(
                identityId: identityId,
                linkedSourceId: linkedSourceId,
                evidence: evidence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String identityId,
                required String linkedSourceId,
                Value<String> evidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LegacyIdentityLinksCompanion.insert(
                identityId: identityId,
                linkedSourceId: linkedSourceId,
                evidence: evidence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LegacyIdentityLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({identityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (identityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.identityId,
                                referencedTable:
                                    $$LegacyIdentityLinksTableReferences
                                        ._identityIdTable(db),
                                referencedColumn:
                                    $$LegacyIdentityLinksTableReferences
                                        ._identityIdTable(db)
                                        .identityId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LegacyIdentityLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$MioAniDatabase,
      $LegacyIdentityLinksTable,
      LegacyIdentityLink,
      $$LegacyIdentityLinksTableFilterComposer,
      $$LegacyIdentityLinksTableOrderingComposer,
      $$LegacyIdentityLinksTableAnnotationComposer,
      $$LegacyIdentityLinksTableCreateCompanionBuilder,
      $$LegacyIdentityLinksTableUpdateCompanionBuilder,
      (LegacyIdentityLink, $$LegacyIdentityLinksTableReferences),
      LegacyIdentityLink,
      PrefetchHooks Function({bool identityId})
    >;
typedef $$LibraryEntriesTableCreateCompanionBuilder =
    LibraryEntriesCompanion Function({
      required String identityId,
      Value<String> status,
      Value<int> watched,
      Value<int> localRevision,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$LibraryEntriesTableUpdateCompanionBuilder =
    LibraryEntriesCompanion Function({
      Value<String> identityId,
      Value<String> status,
      Value<int> watched,
      Value<int> localRevision,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$LibraryEntriesTableReferences
    extends
        BaseReferences<_$MioAniDatabase, $LibraryEntriesTable, LibraryEntry> {
  $$LibraryEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnimeIdentitiesTable _identityIdTable(_$MioAniDatabase db) =>
      db.animeIdentities.createAlias(
        'library_entries__identity_id__anime_identities__identity_id',
      );

  $$AnimeIdentitiesTableProcessedTableManager get identityId {
    final $_column = $_itemColumn<String>('identity_id')!;

    final manager = $$AnimeIdentitiesTableTableManager(
      $_db,
      $_db.animeIdentities,
    ).filter((f) => f.identityId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_identityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LibraryEntriesTableFilterComposer
    extends Composer<_$MioAniDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get watched => $composableBuilder(
    column: $table.watched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localRevision => $composableBuilder(
    column: $table.localRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeIdentitiesTableFilterComposer get identityId {
    final $$AnimeIdentitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableFilterComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryEntriesTableOrderingComposer
    extends Composer<_$MioAniDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get watched => $composableBuilder(
    column: $table.watched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localRevision => $composableBuilder(
    column: $table.localRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeIdentitiesTableOrderingComposer get identityId {
    final $$AnimeIdentitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableOrderingComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryEntriesTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get watched =>
      $composableBuilder(column: $table.watched, builder: (column) => column);

  GeneratedColumn<int> get localRevision => $composableBuilder(
    column: $table.localRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AnimeIdentitiesTableAnnotationComposer get identityId {
    final $$AnimeIdentitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identityId,
      referencedTable: $db.animeIdentities,
      getReferencedColumn: (t) => t.identityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeIdentitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.animeIdentities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryEntriesTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
          $LibraryEntriesTable,
          LibraryEntry,
          $$LibraryEntriesTableFilterComposer,
          $$LibraryEntriesTableOrderingComposer,
          $$LibraryEntriesTableAnnotationComposer,
          $$LibraryEntriesTableCreateCompanionBuilder,
          $$LibraryEntriesTableUpdateCompanionBuilder,
          (LibraryEntry, $$LibraryEntriesTableReferences),
          LibraryEntry,
          PrefetchHooks Function({bool identityId})
        > {
  $$LibraryEntriesTableTableManager(
    _$MioAniDatabase db,
    $LibraryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> identityId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> watched = const Value.absent(),
                Value<int> localRevision = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryEntriesCompanion(
                identityId: identityId,
                status: status,
                watched: watched,
                localRevision: localRevision,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String identityId,
                Value<String> status = const Value.absent(),
                Value<int> watched = const Value.absent(),
                Value<int> localRevision = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LibraryEntriesCompanion.insert(
                identityId: identityId,
                status: status,
                watched: watched,
                localRevision: localRevision,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LibraryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({identityId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (identityId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.identityId,
                                referencedTable: $$LibraryEntriesTableReferences
                                    ._identityIdTable(db),
                                referencedColumn:
                                    $$LibraryEntriesTableReferences
                                        ._identityIdTable(db)
                                        .identityId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LibraryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$MioAniDatabase,
      $LibraryEntriesTable,
      LibraryEntry,
      $$LibraryEntriesTableFilterComposer,
      $$LibraryEntriesTableOrderingComposer,
      $$LibraryEntriesTableAnnotationComposer,
      $$LibraryEntriesTableCreateCompanionBuilder,
      $$LibraryEntriesTableUpdateCompanionBuilder,
      (LibraryEntry, $$LibraryEntriesTableReferences),
      LibraryEntry,
      PrefetchHooks Function({bool identityId})
    >;
typedef $$PublicAccountsTableCreateCompanionBuilder =
    PublicAccountsCompanion Function({
      required String source,
      required String stableUserId,
      required String displayName,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PublicAccountsTableUpdateCompanionBuilder =
    PublicAccountsCompanion Function({
      Value<String> source,
      Value<String> stableUserId,
      Value<String> displayName,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$PublicAccountsTableFilterComposer
    extends Composer<_$MioAniDatabase, $PublicAccountsTable> {
  $$PublicAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stableUserId => $composableBuilder(
    column: $table.stableUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PublicAccountsTableOrderingComposer
    extends Composer<_$MioAniDatabase, $PublicAccountsTable> {
  $$PublicAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stableUserId => $composableBuilder(
    column: $table.stableUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PublicAccountsTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $PublicAccountsTable> {
  $$PublicAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get stableUserId => $composableBuilder(
    column: $table.stableUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PublicAccountsTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
          $PublicAccountsTable,
          PublicAccount,
          $$PublicAccountsTableFilterComposer,
          $$PublicAccountsTableOrderingComposer,
          $$PublicAccountsTableAnnotationComposer,
          $$PublicAccountsTableCreateCompanionBuilder,
          $$PublicAccountsTableUpdateCompanionBuilder,
          (
            PublicAccount,
            BaseReferences<
              _$MioAniDatabase,
              $PublicAccountsTable,
              PublicAccount
            >,
          ),
          PublicAccount,
          PrefetchHooks Function()
        > {
  $$PublicAccountsTableTableManager(
    _$MioAniDatabase db,
    $PublicAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PublicAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PublicAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PublicAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> source = const Value.absent(),
                Value<String> stableUserId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PublicAccountsCompanion(
                source: source,
                stableUserId: stableUserId,
                displayName: displayName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String source,
                required String stableUserId,
                required String displayName,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PublicAccountsCompanion.insert(
                source: source,
                stableUserId: stableUserId,
                displayName: displayName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PublicAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$MioAniDatabase,
      $PublicAccountsTable,
      PublicAccount,
      $$PublicAccountsTableFilterComposer,
      $$PublicAccountsTableOrderingComposer,
      $$PublicAccountsTableAnnotationComposer,
      $$PublicAccountsTableCreateCompanionBuilder,
      $$PublicAccountsTableUpdateCompanionBuilder,
      (
        PublicAccount,
        BaseReferences<_$MioAniDatabase, $PublicAccountsTable, PublicAccount>,
      ),
      PublicAccount,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String settingKey,
      required String valueType,
      required String jsonValue,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> settingKey,
      Value<String> valueType,
      Value<String> jsonValue,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$MioAniDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonValue => $composableBuilder(
    column: $table.jsonValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$MioAniDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonValue => $composableBuilder(
    column: $table.jsonValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingKey => $composableBuilder(
    column: $table.settingKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<String> get jsonValue =>
      $composableBuilder(column: $table.jsonValue, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$MioAniDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$MioAniDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> settingKey = const Value.absent(),
                Value<String> valueType = const Value.absent(),
                Value<String> jsonValue = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                settingKey: settingKey,
                valueType: valueType,
                jsonValue: jsonValue,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String settingKey,
                required String valueType,
                required String jsonValue,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                settingKey: settingKey,
                valueType: valueType,
                jsonValue: jsonValue,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$MioAniDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$MioAniDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$MigrationLedgerTableCreateCompanionBuilder =
    MigrationLedgerCompanion Function({
      required String migrationKey,
      required String sourceFingerprint,
      required int migrationVersion,
      required String status,
      Value<int> migratedEntries,
      required int completedAt,
      Value<int> rowid,
    });
typedef $$MigrationLedgerTableUpdateCompanionBuilder =
    MigrationLedgerCompanion Function({
      Value<String> migrationKey,
      Value<String> sourceFingerprint,
      Value<int> migrationVersion,
      Value<String> status,
      Value<int> migratedEntries,
      Value<int> completedAt,
      Value<int> rowid,
    });

class $$MigrationLedgerTableFilterComposer
    extends Composer<_$MioAniDatabase, $MigrationLedgerTable> {
  $$MigrationLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get migrationVersion => $composableBuilder(
    column: $table.migrationVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get migratedEntries => $composableBuilder(
    column: $table.migratedEntries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationLedgerTableOrderingComposer
    extends Composer<_$MioAniDatabase, $MigrationLedgerTable> {
  $$MigrationLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get migrationVersion => $composableBuilder(
    column: $table.migrationVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get migratedEntries => $composableBuilder(
    column: $table.migratedEntries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationLedgerTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $MigrationLedgerTable> {
  $$MigrationLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get migrationKey => $composableBuilder(
    column: $table.migrationKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get migrationVersion => $composableBuilder(
    column: $table.migrationVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get migratedEntries => $composableBuilder(
    column: $table.migratedEntries,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$MigrationLedgerTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
          $MigrationLedgerTable,
          MigrationLedgerData,
          $$MigrationLedgerTableFilterComposer,
          $$MigrationLedgerTableOrderingComposer,
          $$MigrationLedgerTableAnnotationComposer,
          $$MigrationLedgerTableCreateCompanionBuilder,
          $$MigrationLedgerTableUpdateCompanionBuilder,
          (
            MigrationLedgerData,
            BaseReferences<
              _$MioAniDatabase,
              $MigrationLedgerTable,
              MigrationLedgerData
            >,
          ),
          MigrationLedgerData,
          PrefetchHooks Function()
        > {
  $$MigrationLedgerTableTableManager(
    _$MioAniDatabase db,
    $MigrationLedgerTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MigrationLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MigrationLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> migrationKey = const Value.absent(),
                Value<String> sourceFingerprint = const Value.absent(),
                Value<int> migrationVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> migratedEntries = const Value.absent(),
                Value<int> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MigrationLedgerCompanion(
                migrationKey: migrationKey,
                sourceFingerprint: sourceFingerprint,
                migrationVersion: migrationVersion,
                status: status,
                migratedEntries: migratedEntries,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String migrationKey,
                required String sourceFingerprint,
                required int migrationVersion,
                required String status,
                Value<int> migratedEntries = const Value.absent(),
                required int completedAt,
                Value<int> rowid = const Value.absent(),
              }) => MigrationLedgerCompanion.insert(
                migrationKey: migrationKey,
                sourceFingerprint: sourceFingerprint,
                migrationVersion: migrationVersion,
                status: status,
                migratedEntries: migratedEntries,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$MioAniDatabase,
      $MigrationLedgerTable,
      MigrationLedgerData,
      $$MigrationLedgerTableFilterComposer,
      $$MigrationLedgerTableOrderingComposer,
      $$MigrationLedgerTableAnnotationComposer,
      $$MigrationLedgerTableCreateCompanionBuilder,
      $$MigrationLedgerTableUpdateCompanionBuilder,
      (
        MigrationLedgerData,
        BaseReferences<
          _$MioAniDatabase,
          $MigrationLedgerTable,
          MigrationLedgerData
        >,
      ),
      MigrationLedgerData,
      PrefetchHooks Function()
    >;
typedef $$ImageCacheEntriesTableCreateCompanionBuilder =
    ImageCacheEntriesCompanion Function({
      required String imageUrl,
      required String storageKey,
      required String backend,
      required int byteSize,
      Value<String?> etag,
      Value<String?> lastModified,
      required int fetchedAt,
      required int staleAt,
      required int expiresAt,
      required int lastAccessedAt,
      Value<int> rowid,
    });
typedef $$ImageCacheEntriesTableUpdateCompanionBuilder =
    ImageCacheEntriesCompanion Function({
      Value<String> imageUrl,
      Value<String> storageKey,
      Value<String> backend,
      Value<int> byteSize,
      Value<String?> etag,
      Value<String?> lastModified,
      Value<int> fetchedAt,
      Value<int> staleAt,
      Value<int> expiresAt,
      Value<int> lastAccessedAt,
      Value<int> rowid,
    });

class $$ImageCacheEntriesTableFilterComposer
    extends Composer<_$MioAniDatabase, $ImageCacheEntriesTable> {
  $$ImageCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backend => $composableBuilder(
    column: $table.backend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
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

  ColumnFilters<int> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImageCacheEntriesTableOrderingComposer
    extends Composer<_$MioAniDatabase, $ImageCacheEntriesTable> {
  $$ImageCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backend => $composableBuilder(
    column: $table.backend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
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

  ColumnOrderings<int> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImageCacheEntriesTableAnnotationComposer
    extends Composer<_$MioAniDatabase, $ImageCacheEntriesTable> {
  $$ImageCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backend =>
      $composableBuilder(column: $table.backend, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get staleAt =>
      $composableBuilder(column: $table.staleAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );
}

class $$ImageCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$MioAniDatabase,
          $ImageCacheEntriesTable,
          ImageCacheEntry,
          $$ImageCacheEntriesTableFilterComposer,
          $$ImageCacheEntriesTableOrderingComposer,
          $$ImageCacheEntriesTableAnnotationComposer,
          $$ImageCacheEntriesTableCreateCompanionBuilder,
          $$ImageCacheEntriesTableUpdateCompanionBuilder,
          (
            ImageCacheEntry,
            BaseReferences<
              _$MioAniDatabase,
              $ImageCacheEntriesTable,
              ImageCacheEntry
            >,
          ),
          ImageCacheEntry,
          PrefetchHooks Function()
        > {
  $$ImageCacheEntriesTableTableManager(
    _$MioAniDatabase db,
    $ImageCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImageCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImageCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImageCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> imageUrl = const Value.absent(),
                Value<String> storageKey = const Value.absent(),
                Value<String> backend = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> staleAt = const Value.absent(),
                Value<int> expiresAt = const Value.absent(),
                Value<int> lastAccessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImageCacheEntriesCompanion(
                imageUrl: imageUrl,
                storageKey: storageKey,
                backend: backend,
                byteSize: byteSize,
                etag: etag,
                lastModified: lastModified,
                fetchedAt: fetchedAt,
                staleAt: staleAt,
                expiresAt: expiresAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String imageUrl,
                required String storageKey,
                required String backend,
                required int byteSize,
                Value<String?> etag = const Value.absent(),
                Value<String?> lastModified = const Value.absent(),
                required int fetchedAt,
                required int staleAt,
                required int expiresAt,
                required int lastAccessedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImageCacheEntriesCompanion.insert(
                imageUrl: imageUrl,
                storageKey: storageKey,
                backend: backend,
                byteSize: byteSize,
                etag: etag,
                lastModified: lastModified,
                fetchedAt: fetchedAt,
                staleAt: staleAt,
                expiresAt: expiresAt,
                lastAccessedAt: lastAccessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImageCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$MioAniDatabase,
      $ImageCacheEntriesTable,
      ImageCacheEntry,
      $$ImageCacheEntriesTableFilterComposer,
      $$ImageCacheEntriesTableOrderingComposer,
      $$ImageCacheEntriesTableAnnotationComposer,
      $$ImageCacheEntriesTableCreateCompanionBuilder,
      $$ImageCacheEntriesTableUpdateCompanionBuilder,
      (
        ImageCacheEntry,
        BaseReferences<
          _$MioAniDatabase,
          $ImageCacheEntriesTable,
          ImageCacheEntry
        >,
      ),
      ImageCacheEntry,
      PrefetchHooks Function()
    >;

class $MioAniDatabaseManager {
  final _$MioAniDatabase _db;
  $MioAniDatabaseManager(this._db);
  $$StructuredCacheEntriesTableTableManager get structuredCacheEntries =>
      $$StructuredCacheEntriesTableTableManager(
        _db,
        _db.structuredCacheEntries,
      );
  $$AnimeIdentitiesTableTableManager get animeIdentities =>
      $$AnimeIdentitiesTableTableManager(_db, _db.animeIdentities);
  $$SourceEntitiesTableTableManager get sourceEntities =>
      $$SourceEntitiesTableTableManager(_db, _db.sourceEntities);
  $$LegacyIdentityLinksTableTableManager get legacyIdentityLinks =>
      $$LegacyIdentityLinksTableTableManager(_db, _db.legacyIdentityLinks);
  $$LibraryEntriesTableTableManager get libraryEntries =>
      $$LibraryEntriesTableTableManager(_db, _db.libraryEntries);
  $$PublicAccountsTableTableManager get publicAccounts =>
      $$PublicAccountsTableTableManager(_db, _db.publicAccounts);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$MigrationLedgerTableTableManager get migrationLedger =>
      $$MigrationLedgerTableTableManager(_db, _db.migrationLedger);
  $$ImageCacheEntriesTableTableManager get imageCacheEntries =>
      $$ImageCacheEntriesTableTableManager(_db, _db.imageCacheEntries);
}
