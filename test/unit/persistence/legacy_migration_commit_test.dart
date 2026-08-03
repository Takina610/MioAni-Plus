import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/core/persistence/legacy_migration.dart';

void main() {
  late MioAniDatabase database;
  const parser = LegacyMigrationParser();
  const planner = LegacyMigrationPlanner();
  final now = DateTime.utc(2026, 7, 31, 12);

  setUp(() {
    database = MioAniDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  LegacyMigrationCommitPlan planFrom({
    required String libraryJson,
    String? profileJson,
  }) {
    return planner.plan(
      parser.parse(libraryJson: libraryJson, profileJson: profileJson),
    );
  }

  test(
    'commits a valid plan into user tables and the migration ledger once',
    () async {
      final plan = planFrom(
        libraryJson: '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "Linked Work",
    "originalTitle": "Original",
    "year": 2026,
    "episodes": 12,
    "watched": 3,
    "status": "watching",
    "linkedIds": ["bgm-2", "anilist-100"]
  },
  {
    "id": "anilist-100",
    "source": "anilist",
    "title": "Linked Work AL",
    "year": 2026,
    "episodes": 12,
    "watched": 5,
    "status": "watching",
    "linkedIds": ["anilist-100"]
  }
]
''',
        profileJson: '{"name":"public-user","sources":["bangumi","anilist"]}',
      );

      final result = await database.commitLegacyMigrationPlan(plan, now: now);

      expect(result.status, LegacyMigrationCommitStatus.committed);
      expect(result.fingerprint, plan.fingerprint);
      expect(result.migratedEntries, 1);

      final identities = await database.select(database.animeIdentities).get();
      expect(identities, hasLength(1));
      expect(identities.single.identityId, plan.identities.single.identityKey);
      expect(identities.single.canonicalTitle, 'Linked Work');

      final sources = await database.select(database.sourceEntities).get();
      expect(
        sources.map((row) => row.sourceId).toList()..sort(),
        <String>['anilist-100', 'bgm-2'],
      );
      expect(
        sources.map((row) => row.identityId).toSet(),
        <String>{plan.identities.single.identityKey},
      );

      final library = await database.select(database.libraryEntries).get();
      expect(library, hasLength(1));
      expect(library.single.status, 'watching');
      expect(library.single.watched, 5);
      expect(library.single.updatedAt, now.millisecondsSinceEpoch);

      final links = await database.select(database.legacyIdentityLinks).get();
      expect(
        links.map((row) => row.linkedSourceId).toList()..sort(),
        <String>['anilist-100', 'bgm-2'],
      );
      expect(links.every((row) => row.evidence == 'legacy_linked_ids'), isTrue);

      final accounts = await database.select(database.publicAccounts).get();
      expect(accounts, hasLength(2));
      expect(
        accounts.map((row) => '${row.source}:${row.stableUserId}').toList()
          ..sort(),
        <String>['anilist:public-user', 'bangumi:public-user'],
      );

      final ledger = await database.select(database.migrationLedger).get();
      expect(ledger, hasLength(1));
      expect(ledger.single.migrationKey, MioAniDatabase.vueMigrationKey);
      expect(ledger.single.sourceFingerprint, plan.fingerprint);
      expect(ledger.single.status, 'completed');
      expect(ledger.single.migratedEntries, 1);
      expect(ledger.single.completedAt, now.millisecondsSinceEpoch);
      expect(ledger.single.sourceFingerprint, isNot(contains('Linked Work')));
    },
  );

  test(
    'same fingerprint returns alreadyMigrated without duplicating rows',
    () async {
      final plan = planFrom(
        libraryJson: '''
[
  {
    "id": "bgm-9",
    "source": "bangumi",
    "title": "Solo",
    "year": 2024,
    "episodes": 24,
    "watched": 0,
    "status": "planned",
    "linkedIds": ["bgm-9"]
  }
]
''',
      );

      final first = await database.commitLegacyMigrationPlan(plan, now: now);
      final second = await database.commitLegacyMigrationPlan(
        plan,
        now: now.add(const Duration(hours: 1)),
      );

      expect(first.status, LegacyMigrationCommitStatus.committed);
      expect(second.status, LegacyMigrationCommitStatus.alreadyMigrated);
      expect(second.fingerprint, plan.fingerprint);
      expect(second.migratedEntries, 1);
      expect(await database.select(database.animeIdentities).get(), hasLength(1));
      expect(await database.select(database.libraryEntries).get(), hasLength(1));
      expect(await database.select(database.migrationLedger).get(), hasLength(1));
    },
  );

  test(
    'changed fingerprint only inserts missing records and never overwrites newer Flutter library state',
    () async {
      final firstPlan = planFrom(
        libraryJson: '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "Work",
    "year": 2026,
    "episodes": 12,
    "watched": 3,
    "status": "watching",
    "linkedIds": ["bgm-2"]
  }
]
''',
      );
      await database.commitLegacyMigrationPlan(firstPlan, now: now);

      final identityId = firstPlan.identities.single.identityKey;
      final later = now.add(const Duration(days: 1));
      await (database.update(database.libraryEntries)
            ..where((row) => row.identityId.equals(identityId)))
          .write(
            LibraryEntriesCompanion(
              status: const Value('completed'),
              watched: const Value(12),
              localRevision: const Value(1),
              updatedAt: Value(later.millisecondsSinceEpoch),
            ),
          );

      final secondPlan = planFrom(
        libraryJson: '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "Work",
    "year": 2026,
    "episodes": 12,
    "watched": 1,
    "status": "watching",
    "linkedIds": ["bgm-2"]
  },
  {
    "id": "bgm-9",
    "source": "bangumi",
    "title": "New Work",
    "year": 2025,
    "episodes": 13,
    "watched": 2,
    "status": "planned",
    "linkedIds": ["bgm-9"]
  }
]
''',
      );
      expect(secondPlan.fingerprint, isNot(firstPlan.fingerprint));

      final result = await database.commitLegacyMigrationPlan(
        secondPlan,
        now: later.add(const Duration(hours: 1)),
      );

      expect(result.status, LegacyMigrationCommitStatus.committed);
      expect(result.migratedEntries, 2);

      final library = await database.select(database.libraryEntries).get();
      expect(library, hasLength(2));
      final preserved = library.singleWhere(
        (row) => row.identityId == identityId,
      );
      expect(preserved.status, 'completed');
      expect(preserved.watched, 12);
      expect(preserved.localRevision, 1);
      expect(preserved.updatedAt, later.millisecondsSinceEpoch);

      final added = library.singleWhere((row) => row.identityId != identityId);
      expect(added.status, 'planned');
      expect(added.watched, 2);

      final ledger = await database.select(database.migrationLedger).get();
      expect(ledger, hasLength(2));
      expect(
        ledger.map((row) => row.sourceFingerprint).toSet(),
        <String>{firstPlan.fingerprint, secondPlan.fingerprint},
      );
    },
  );

  test(
    'rolls back the whole migration transaction when a constraint fails mid-commit',
    () async {
      // Bypass the parser so the commit path can hit a CHECK failure after the
      // identity row is written, proving the ledger and user tables roll back.
      const plan = LegacyMigrationCommitPlan(
        fingerprint: 'mioani-vue-v1:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        identities: <LegacyPlannedIdentity>[
          LegacyPlannedIdentity(
            identityKey: 'mioani-identity-v1:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
            canonicalTitle: 'Work',
            status: LegacyWatchStatus.watching,
            watched: -1,
            sourceEntities: <LegacyPlannedSourceEntity>[
              LegacyPlannedSourceEntity(
                source: LegacyAnimeSource.bangumi,
                sourceId: 'bgm-2',
                title: 'Work',
                originalTitle: null,
                year: 2026,
                episodes: 12,
              ),
            ],
            legacyLinkedIds: <String>['bgm-2'],
          ),
        ],
        profile: null,
      );

      await expectLater(
        database.commitLegacyMigrationPlan(plan, now: now),
        throwsA(isA<Object>()),
      );

      expect(await database.select(database.animeIdentities).get(), isEmpty);
      expect(await database.select(database.sourceEntities).get(), isEmpty);
      expect(await database.select(database.libraryEntries).get(), isEmpty);
      expect(await database.select(database.legacyIdentityLinks).get(), isEmpty);
      expect(await database.select(database.migrationLedger).get(), isEmpty);
    },
  );

  test(
    'LegacyMigrationRunner reports notNeeded when storage is empty',
    () async {
      final outcome = await LegacyMigrationRunner(
        database: database,
        reader: const EmptyLegacyStorageReader(),
        now: () => now,
      ).run();

      expect(outcome.kind, LegacyMigrationOutcomeKind.notNeeded);
      expect(outcome.fingerprint, isNull);
      expect(await database.select(database.migrationLedger).get(), isEmpty);
    },
  );

  test(
    'LegacyMigrationRunner migrates valid storage and is idempotent',
    () async {
      const libraryJson = '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "Work",
    "year": 2026,
    "episodes": 12,
    "watched": 3,
    "status": "watching",
    "linkedIds": ["bgm-2"]
  }
]
''';
      final reader = _FakeLegacyStorageReader(
        libraryJson: libraryJson,
        profileJson: null,
      );
      final runner = LegacyMigrationRunner(
        database: database,
        reader: reader,
        now: () => now,
      );

      final first = await runner.run();
      final second = await runner.run();

      expect(first.kind, LegacyMigrationOutcomeKind.migrated);
      expect(first.migratedEntries, 1);
      expect(first.fingerprint, matches(r'^mioani-vue-v1:[0-9a-f]{32}$'));
      expect(second.kind, LegacyMigrationOutcomeKind.alreadyMigrated);
      expect(second.fingerprint, first.fingerprint);
      expect(await database.select(database.libraryEntries).get(), hasLength(1));
      expect(reader.readCount, 2);
    },
  );

  test(
    'LegacyMigrationRunner reports parse failures without writing user rows',
    () async {
      final outcome = await LegacyMigrationRunner(
        database: database,
        reader: _FakeLegacyStorageReader(
          libraryJson:
              '[{"id":"bgm-2","source":"bangumi","title":"x","year":2026,"episodes":12,"watched":-1,"status":"watching"}]',
          profileJson: null,
        ),
        now: () => now,
      ).run();

      expect(outcome.kind, LegacyMigrationOutcomeKind.failed);
      expect(outcome.diagnosticMessage, contains('parse'));
      expect(await database.select(database.libraryEntries).get(), isEmpty);
      expect(await database.select(database.migrationLedger).get(), isEmpty);
    },
  );

  test('EmptyLegacyStorageReader never invents Vue keys', () async {
    final snapshot = await const EmptyLegacyStorageReader().read();
    expect(snapshot.libraryJson, isNull);
    expect(snapshot.profileJson, isNull);
    expect(snapshot.isEmpty, isTrue);
  });
}

final class _FakeLegacyStorageReader implements LegacyStorageReader {
  _FakeLegacyStorageReader({
    required this.libraryJson,
    required this.profileJson,
  });

  final String? libraryJson;
  final String? profileJson;
  int readCount = 0;

  @override
  Future<LegacyStorageSnapshot> read() async {
    readCount += 1;
    return LegacyStorageSnapshot(
      libraryJson: libraryJson,
      profileJson: profileJson,
    );
  }
}
