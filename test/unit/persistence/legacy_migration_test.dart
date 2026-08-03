import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/persistence/legacy_migration.dart';

void main() {
  const parser = LegacyMigrationParser();

  test('parses real-shaped Vue library and profile data into a plan', () {
    final plan = parser.parse(
      libraryJson: '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "  作品标题  ",
    "originalTitle": "Original Title",
    "year": 2026,
    "episodes": 12,
    "watched": 3,
    "status": "watching",
    "linkedIds": ["bgm-2", "anilist-100", "anilist-100"],
    "image": "https://lain.bgm.tv/pic/cover/example.jpg",
    "score": 8.1,
    "season": "TV",
    "tags": ["动画"],
    "summary": "不会作为原始 JSON 保存"
  }
]
''',
      profileJson: '''
{
  "name": " public-user ",
  "sources": ["bangumi", "anilist", "bangumi"]
}
''',
    );

    expect(plan.library, hasLength(1));
    final entry = plan.library.single;
    expect(entry.id, 'bgm-2');
    expect(entry.source, LegacyAnimeSource.bangumi);
    expect(entry.title, '作品标题');
    expect(entry.originalTitle, 'Original Title');
    expect(entry.year, 2026);
    expect(entry.episodes, 12);
    expect(entry.watched, 3);
    expect(entry.status, LegacyWatchStatus.watching);
    expect(entry.linkedIds, <String>['bgm-2', 'anilist-100']);
    expect(plan.profile?.name, 'public-user');
    expect(plan.profile?.sources, <LegacyPublicAccountSource>[
      LegacyPublicAccountSource.bangumi,
      LegacyPublicAccountSource.anilist,
    ]);
  });

  test('rejects the whole source when any Vue library entry is invalid', () {
    const libraryJson = '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "合法条目",
    "year": 2026,
    "episodes": 12,
    "watched": 3,
    "status": "watching",
    "linkedIds": ["bgm-2"]
  },
  {
    "id": "anilist-100",
    "source": "anilist",
    "title": "非法进度",
    "year": 2026,
    "episodes": 12,
    "watched": -1,
    "status": "planned",
    "linkedIds": ["anilist-100"]
  }
]
''';

    expect(
      () => parser.parse(libraryJson: libraryJson, profileJson: null),
      throwsA(
        isA<LegacyMigrationParseFailure>().having(
          (failure) => failure.issues.map((issue) => issue.path),
          'issue paths',
          contains(r'$[1].watched'),
        ),
      ),
    );
  });

  test(
    'fingerprints canonical approved fields without leaking source text',
    () {
      final first = parser.parse(
        libraryJson: '''
[
  {"id":"bgm-2","source":"bangumi","title":"私密标题","year":2026,"episodes":12,"watched":3,"status":"watching","linkedIds":["anilist-100","bgm-2","bgm-2"]},
  {"id":"anilist-100","source":"anilist","title":"Second","year":2025,"episodes":24,"watched":24,"status":"completed","linkedIds":["anilist-100"]}
]
''',
        profileJson: '{"name":"private-user","sources":["bangumi","anilist"]}',
      );
      final equivalent = parser.parse(
        libraryJson: '''
[
  {"status":"completed","watched":24,"episodes":24,"year":2025,"title":"Second","source":"anilist","id":"anilist-100","linkedIds":["anilist-100"]},
  {"linkedIds":["bgm-2","anilist-100"],"watched":3,"episodes":12,"year":2026,"title":"私密标题","source":"bangumi","id":"bgm-2","status":"watching"}
]
''',
        profileJson: '{"sources":["anilist","bangumi"],"name":"private-user"}',
      );
      final changed = parser.parse(
        libraryJson: '''
[
  {"id":"bgm-2","source":"bangumi","title":"私密标题","year":2026,"episodes":12,"watched":4,"status":"watching","linkedIds":["anilist-100","bgm-2"]},
  {"id":"anilist-100","source":"anilist","title":"Second","year":2025,"episodes":24,"watched":24,"status":"completed","linkedIds":["anilist-100"]}
]
''',
        profileJson: '{"name":"private-user","sources":["bangumi","anilist"]}',
      );

      expect(first.fingerprint, matches(r'^mioani-vue-v1:[0-9a-f]{32}$'));
      expect(equivalent.fingerprint, first.fingerprint);
      expect(changed.fingerprint, isNot(first.fingerprint));
      expect(first.fingerprint, isNot(contains('私密标题')));
      expect(first.fingerprint, isNot(contains('private-user')));
    },
  );

  test(
    'plans deterministic identities from primary ids and linkedIds evidence',
    () {
      final parsed = parser.parse(
        libraryJson: '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "Linked Work",
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
  },
  {
    "id": "bgm-9",
    "source": "bangumi",
    "title": "Unrelated",
    "year": 2024,
    "episodes": 24,
    "watched": 0,
    "status": "planned",
    "linkedIds": ["bgm-9"]
  }
]
''',
        profileJson: '{"name":"public-user","sources":["bangumi"]}',
      );

      final commit = const LegacyMigrationPlanner().plan(parsed);

      expect(commit.fingerprint, parsed.fingerprint);
      expect(commit.identities, hasLength(2));
      expect(commit.profile?.name, 'public-user');

      final linked = commit.identities.singleWhere(
        (identity) => identity.sourceEntities.any(
          (entity) => entity.sourceId == 'bgm-2',
        ),
      );
      expect(linked.identityKey, matches(r'^mioani-identity-v1:[0-9a-f]{32}$'));
      expect(
        linked.sourceEntities.map((entity) => entity.sourceId).toList()
          ..sort(),
        <String>['anilist-100', 'bgm-2'],
      );
      expect(linked.legacyLinkedIds, <String>['anilist-100', 'bgm-2']);
      expect(linked.status, LegacyWatchStatus.watching);
      expect(linked.watched, 5);
      expect(linked.canonicalTitle, 'Linked Work');

      final unrelated = commit.identities.singleWhere(
        (identity) => identity.sourceEntities.any(
          (entity) => entity.sourceId == 'bgm-9',
        ),
      );
      expect(unrelated.identityKey, isNot(linked.identityKey));
      expect(unrelated.sourceEntities, hasLength(1));
      expect(unrelated.watched, 0);
    },
  );

  test('rejects duplicate primary source ids without a partial plan', () {
    final parsed = parser.parse(
      libraryJson: '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "First",
    "year": 2026,
    "episodes": 12,
    "watched": 1,
    "status": "watching",
    "linkedIds": ["bgm-2"]
  },
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "Second",
    "year": 2026,
    "episodes": 12,
    "watched": 2,
    "status": "completed",
    "linkedIds": ["bgm-2"]
  }
]
''',
      profileJson: null,
    );

    expect(
      () => const LegacyMigrationPlanner().plan(parsed),
      throwsA(
        isA<LegacyMigrationConflictFailure>().having(
          (failure) => failure.conflicts.map((conflict) => conflict.kind),
          'conflict kinds',
          contains(LegacyMigrationConflictKind.duplicatePrimarySource),
        ),
      ),
    );
  });

  test(
    'rejects cross-linked records with contradictory watch status',
    () {
      final parsed = parser.parse(
        libraryJson: '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "A",
    "year": 2026,
    "episodes": 12,
    "watched": 3,
    "status": "watching",
    "linkedIds": ["bgm-2", "anilist-100"]
  },
  {
    "id": "anilist-100",
    "source": "anilist",
    "title": "B",
    "year": 2026,
    "episodes": 12,
    "watched": 12,
    "status": "completed",
    "linkedIds": ["anilist-100"]
  }
]
''',
        profileJson: null,
      );

      expect(
        () => const LegacyMigrationPlanner().plan(parsed),
        throwsA(
          isA<LegacyMigrationConflictFailure>().having(
            (failure) => failure.conflicts.map((conflict) => conflict.kind),
            'conflict kinds',
            contains(LegacyMigrationConflictKind.crossLinkedStateConflict),
          ),
        ),
      );
    },
  );

  test(
    'does not merge same-title records without explicit linkedIds',
    () {
      final parsed = parser.parse(
        libraryJson: '''
[
  {
    "id": "bgm-2",
    "source": "bangumi",
    "title": "Same Title",
    "year": 2026,
    "episodes": 12,
    "watched": 1,
    "status": "watching",
    "linkedIds": ["bgm-2"]
  },
  {
    "id": "anilist-100",
    "source": "anilist",
    "title": "Same Title",
    "year": 2026,
    "episodes": 12,
    "watched": 1,
    "status": "watching",
    "linkedIds": ["anilist-100"]
  }
]
''',
        profileJson: null,
      );

      final commit = const LegacyMigrationPlanner().plan(parsed);
      expect(commit.identities, hasLength(2));
      expect(
        commit.identities.map((identity) => identity.identityKey).toSet(),
        hasLength(2),
      );
    },
  );
}
