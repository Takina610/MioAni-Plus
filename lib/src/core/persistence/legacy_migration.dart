import 'dart:convert';

import 'package:mio_ani/src/core/stable_hash.dart';

enum LegacyAnimeSource { bangumi, anilist, local }

enum LegacyPublicAccountSource { bangumi, anilist }

enum LegacyWatchStatus { watching, completed, planned, paused, dropped }

final class LegacyLibraryRecord {
  const LegacyLibraryRecord({
    required this.id,
    required this.source,
    required this.title,
    required this.originalTitle,
    required this.year,
    required this.episodes,
    required this.watched,
    required this.status,
    required this.linkedIds,
  });

  final String id;
  final LegacyAnimeSource source;
  final String title;
  final String? originalTitle;
  final int year;
  final int episodes;
  final int watched;
  final LegacyWatchStatus status;
  final List<String> linkedIds;
}

final class LegacyProfileRecord {
  const LegacyProfileRecord({required this.name, required this.sources});

  final String name;
  final List<LegacyPublicAccountSource> sources;
}

final class LegacyMigrationPlan {
  const LegacyMigrationPlan({required this.library, required this.profile});

  final List<LegacyLibraryRecord> library;
  final LegacyProfileRecord? profile;

  String get fingerprint =>
      'mioani-vue-v1:${createStableHash128(_canonicalJson)}';

  String get _canonicalJson {
    final canonicalLibrary =
        library.map((entry) {
          final linkedIds = entry.linkedIds.toList()..sort();
          return <String, Object?>{
            'id': entry.id,
            'source': entry.source.name,
            'title': entry.title,
            'originalTitle': entry.originalTitle,
            'year': entry.year,
            'episodes': entry.episodes,
            'watched': entry.watched,
            'status': entry.status.name,
            'linkedIds': linkedIds,
          };
        }).toList()..sort((left, right) {
          return jsonEncode(left).compareTo(jsonEncode(right));
        });
    final profileSources =
        profile?.sources.map((source) => source.name).toList()?..sort();
    return jsonEncode(<String, Object?>{
      'library': canonicalLibrary,
      'profile': profile == null
          ? null
          : <String, Object?>{'name': profile!.name, 'sources': profileSources},
    });
  }
}

final class LegacyMigrationIssue {
  const LegacyMigrationIssue({required this.path, required this.message});

  final String path;
  final String message;
}

final class LegacyMigrationParseFailure implements Exception {
  const LegacyMigrationParseFailure(this.issues);

  final List<LegacyMigrationIssue> issues;

  @override
  String toString() => 'LegacyMigrationParseFailure(${issues.length} issues)';
}

enum LegacyMigrationConflictKind {
  duplicatePrimarySource,
  crossLinkedStateConflict,
}

final class LegacyMigrationConflict {
  const LegacyMigrationConflict({
    required this.kind,
    required this.sourceIds,
    required this.message,
  });

  final LegacyMigrationConflictKind kind;
  final List<String> sourceIds;
  final String message;
}

final class LegacyMigrationConflictFailure implements Exception {
  const LegacyMigrationConflictFailure(this.conflicts);

  final List<LegacyMigrationConflict> conflicts;

  @override
  String toString() =>
      'LegacyMigrationConflictFailure(${conflicts.length} conflicts)';
}

final class LegacyPlannedSourceEntity {
  const LegacyPlannedSourceEntity({
    required this.source,
    required this.sourceId,
    required this.title,
    required this.originalTitle,
    required this.year,
    required this.episodes,
  });

  final LegacyAnimeSource source;
  final String sourceId;
  final String title;
  final String? originalTitle;
  final int year;
  final int episodes;
}

final class LegacyPlannedIdentity {
  const LegacyPlannedIdentity({
    required this.identityKey,
    required this.canonicalTitle,
    required this.status,
    required this.watched,
    required this.sourceEntities,
    required this.legacyLinkedIds,
  });

  final String identityKey;
  final String canonicalTitle;
  final LegacyWatchStatus status;
  final int watched;
  final List<LegacyPlannedSourceEntity> sourceEntities;
  final List<String> legacyLinkedIds;
}

final class LegacyMigrationCommitPlan {
  const LegacyMigrationCommitPlan({
    required this.fingerprint,
    required this.identities,
    required this.profile,
  });

  final String fingerprint;
  final List<LegacyPlannedIdentity> identities;
  final LegacyProfileRecord? profile;
}

final class LegacyMigrationPlanner {
  const LegacyMigrationPlanner();

  LegacyMigrationCommitPlan plan(LegacyMigrationPlan parsed) {
    final conflicts = <LegacyMigrationConflict>[];
    final recordsByPrimaryId = <String, LegacyLibraryRecord>{};

    for (final record in parsed.library) {
      final existing = recordsByPrimaryId[record.id];
      if (existing != null) {
        conflicts.add(
          LegacyMigrationConflict(
            kind: LegacyMigrationConflictKind.duplicatePrimarySource,
            sourceIds: <String>[record.id],
            message: 'duplicate primary source id ${record.id}',
          ),
        );
        continue;
      }
      recordsByPrimaryId[record.id] = record;
    }

    if (conflicts.isNotEmpty) {
      throw LegacyMigrationConflictFailure(List.unmodifiable(conflicts));
    }

    final parent = <String, String>{
      for (final id in recordsByPrimaryId.keys) id: id,
    };

    String find(String id) {
      var current = id;
      while (parent[current] != current) {
        parent[current] = parent[parent[current]!]!;
        current = parent[current]!;
      }
      return current;
    }

    void union(String left, String right) {
      final leftRoot = find(left);
      final rightRoot = find(right);
      if (leftRoot == rightRoot) return;
      if (leftRoot.compareTo(rightRoot) <= 0) {
        parent[rightRoot] = leftRoot;
      } else {
        parent[leftRoot] = rightRoot;
      }
    }

    for (final record in recordsByPrimaryId.values) {
      for (final linkedId in record.linkedIds) {
        final target = recordsByPrimaryId[linkedId];
        if (target == null) continue;
        union(record.id, target.id);
      }
    }

    final groups = <String, List<LegacyLibraryRecord>>{};
    for (final record in recordsByPrimaryId.values) {
      groups.putIfAbsent(find(record.id), () => <LegacyLibraryRecord>[]).add(
        record,
      );
    }

    final identities = <LegacyPlannedIdentity>[];
    final sortedRoots = groups.keys.toList()..sort();
    for (final root in sortedRoots) {
      final members = groups[root]!
        ..sort((left, right) => left.id.compareTo(right.id));
      final statuses = members.map((member) => member.status).toSet();
      if (statuses.length > 1) {
        conflicts.add(
          LegacyMigrationConflict(
            kind: LegacyMigrationConflictKind.crossLinkedStateConflict,
            sourceIds: members.map((member) => member.id).toList(),
            message:
                'cross-linked records disagree on watch status for ${members.map((member) => member.id).join(', ')}',
          ),
        );
        continue;
      }

      final sourceEntities = members
          .map(
            (member) => LegacyPlannedSourceEntity(
              source: member.source,
              sourceId: member.id,
              title: member.title,
              originalTitle: member.originalTitle,
              year: member.year,
              episodes: member.episodes,
            ),
          )
          .toList(growable: false);

      final legacyLinkedIds = <String>{
        for (final member in members) ...member.linkedIds,
        for (final member in members) member.id,
      }.toList()
        ..sort();

      final memberIds = members.map((member) => member.id).toList()..sort();
      final identityKey =
          'mioani-identity-v1:${createStableHash128(memberIds.join('\u001f'))}';
      final canonicalTitle = members
          .map((member) => member.title)
          .reduce((best, title) => title.compareTo(best) < 0 ? title : best);
      final watched = members
          .map((member) => member.watched)
          .reduce((left, right) => left > right ? left : right);

      identities.add(
        LegacyPlannedIdentity(
          identityKey: identityKey,
          canonicalTitle: canonicalTitle,
          status: members.first.status,
          watched: watched,
          sourceEntities: List.unmodifiable(sourceEntities),
          legacyLinkedIds: List.unmodifiable(legacyLinkedIds),
        ),
      );
    }

    if (conflicts.isNotEmpty) {
      throw LegacyMigrationConflictFailure(List.unmodifiable(conflicts));
    }

    identities.sort(
      (left, right) => left.identityKey.compareTo(right.identityKey),
    );
    return LegacyMigrationCommitPlan(
      fingerprint: parsed.fingerprint,
      identities: List.unmodifiable(identities),
      profile: parsed.profile,
    );
  }
}

final class LegacyMigrationParser {
  const LegacyMigrationParser();

  LegacyMigrationPlan parse({String? libraryJson, String? profileJson}) {
    final issues = <LegacyMigrationIssue>[];
    final library = _parseLibrary(libraryJson, issues);
    final profile = _parseProfile(profileJson, issues);
    if (issues.isNotEmpty) {
      throw LegacyMigrationParseFailure(List.unmodifiable(issues));
    }
    return LegacyMigrationPlan(
      library: List.unmodifiable(library),
      profile: profile,
    );
  }

  List<LegacyLibraryRecord> _parseLibrary(
    String? raw,
    List<LegacyMigrationIssue> issues,
  ) {
    if (raw == null) return const <LegacyLibraryRecord>[];
    final decoded = _decode(raw, r'$', issues);
    if (decoded is! List<Object?>) {
      if (decoded != null) _issue(issues, r'$', 'must be a JSON list');
      return const <LegacyLibraryRecord>[];
    }

    final records = <LegacyLibraryRecord>[];
    for (var index = 0; index < decoded.length; index += 1) {
      final path = '\$[$index]';
      final value = decoded[index];
      if (value is! Map<String, Object?>) {
        _issue(issues, path, 'must be a JSON object');
        continue;
      }
      final issueCount = issues.length;
      final id = _requiredString(value, 'id', path, issues);
      final source = _animeSource(value['source'], '$path.source', issues);
      final title = _requiredString(value, 'title', path, issues);
      final originalTitle = _optionalString(
        value,
        'originalTitle',
        path,
        issues,
      );
      final year = _nonNegativeInt(value, 'year', path, issues);
      final episodes = _nonNegativeInt(value, 'episodes', path, issues);
      final watched = _nonNegativeInt(value, 'watched', path, issues);
      final status = _watchStatus(value['status'], '$path.status', issues);
      final linkedIds = _linkedIds(
        value['linkedIds'],
        '$path.linkedIds',
        issues,
      );
      if (id != null && source != null && !_matchesSource(id, source)) {
        _issue(issues, '$path.id', 'does not match the declared source');
      }
      if (issues.length != issueCount) continue;
      records.add(
        LegacyLibraryRecord(
          id: id!,
          source: source!,
          title: title!,
          originalTitle: originalTitle,
          year: year!,
          episodes: episodes!,
          watched: watched!,
          status: status!,
          linkedIds: List.unmodifiable(linkedIds),
        ),
      );
    }
    return records;
  }

  LegacyProfileRecord? _parseProfile(
    String? raw,
    List<LegacyMigrationIssue> issues,
  ) {
    if (raw == null) return null;
    final decoded = _decode(raw, r'$', issues);
    if (decoded is! Map<String, Object?>) {
      if (decoded != null) _issue(issues, r'$', 'must be a JSON object');
      return null;
    }
    final issueCount = issues.length;
    final name = _requiredString(decoded, 'name', r'$', issues);
    final sources = _profileSources(decoded['sources'], r'$.sources', issues);
    if (issues.length != issueCount) return null;
    return LegacyProfileRecord(
      name: name!,
      sources: List.unmodifiable(sources),
    );
  }

  Object? _decode(String raw, String path, List<LegacyMigrationIssue> issues) {
    try {
      return jsonDecode(raw);
    } on FormatException {
      _issue(issues, path, 'contains invalid JSON');
      return null;
    }
  }

  String? _requiredString(
    Map<String, Object?> object,
    String key,
    String path,
    List<LegacyMigrationIssue> issues,
  ) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      _issue(issues, '$path.$key', 'must be a non-empty string');
      return null;
    }
    return value.trim();
  }

  String? _optionalString(
    Map<String, Object?> object,
    String key,
    String path,
    List<LegacyMigrationIssue> issues,
  ) {
    final value = object[key];
    if (value == null) return null;
    if (value is! String) {
      _issue(issues, '$path.$key', 'must be a string when present');
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  int? _nonNegativeInt(
    Map<String, Object?> object,
    String key,
    String path,
    List<LegacyMigrationIssue> issues,
  ) {
    final value = object[key];
    if (value is! num || !value.isFinite || value < 0 || value % 1 != 0) {
      _issue(issues, '$path.$key', 'must be a non-negative integer');
      return null;
    }
    return value.toInt();
  }

  LegacyAnimeSource? _animeSource(
    Object? value,
    String path,
    List<LegacyMigrationIssue> issues,
  ) {
    final source = switch (value) {
      'bangumi' => LegacyAnimeSource.bangumi,
      'anilist' => LegacyAnimeSource.anilist,
      'local' => LegacyAnimeSource.local,
      _ => null,
    };
    if (source == null) _issue(issues, path, 'has an unsupported source');
    return source;
  }

  LegacyWatchStatus? _watchStatus(
    Object? value,
    String path,
    List<LegacyMigrationIssue> issues,
  ) {
    final status = switch (value) {
      'watching' => LegacyWatchStatus.watching,
      'completed' => LegacyWatchStatus.completed,
      'planned' => LegacyWatchStatus.planned,
      'paused' => LegacyWatchStatus.paused,
      'dropped' => LegacyWatchStatus.dropped,
      _ => null,
    };
    if (status == null) _issue(issues, path, 'has an unsupported status');
    return status;
  }

  List<String> _linkedIds(
    Object? value,
    String path,
    List<LegacyMigrationIssue> issues,
  ) {
    if (value == null) return const <String>[];
    if (value is! List<Object?>) {
      _issue(issues, path, 'must be a list when present');
      return const <String>[];
    }
    final result = <String>[];
    for (var index = 0; index < value.length; index += 1) {
      final linkedId = value[index];
      if (linkedId is! String || !_isKnownSourceId(linkedId.trim())) {
        _issue(issues, '$path[$index]', 'must be a recognized source id');
        continue;
      }
      final normalized = linkedId.trim();
      if (!result.contains(normalized)) result.add(normalized);
    }
    return result;
  }

  List<LegacyPublicAccountSource> _profileSources(
    Object? value,
    String path,
    List<LegacyMigrationIssue> issues,
  ) {
    if (value is! List<Object?>) {
      _issue(issues, path, 'must be a list');
      return const <LegacyPublicAccountSource>[];
    }
    final result = <LegacyPublicAccountSource>[];
    for (var index = 0; index < value.length; index += 1) {
      final source = switch (value[index]) {
        'bangumi' => LegacyPublicAccountSource.bangumi,
        'anilist' => LegacyPublicAccountSource.anilist,
        _ => null,
      };
      if (source == null) {
        _issue(issues, '$path[$index]', 'has an unsupported source');
      } else if (!result.contains(source)) {
        result.add(source);
      }
    }
    return result;
  }

  bool _matchesSource(String id, LegacyAnimeSource source) {
    return switch (source) {
      LegacyAnimeSource.bangumi => RegExp(r'^bgm-[1-9][0-9]*$').hasMatch(id),
      LegacyAnimeSource.anilist => RegExp(
        r'^anilist-[1-9][0-9]*$',
      ).hasMatch(id),
      LegacyAnimeSource.local => RegExp(r'^local-.+$').hasMatch(id),
    };
  }

  bool _isKnownSourceId(String id) {
    return RegExp(
      r'^(bgm-[1-9][0-9]*|anilist-[1-9][0-9]*|local-.+)$',
    ).hasMatch(id);
  }

  void _issue(List<LegacyMigrationIssue> issues, String path, String message) {
    issues.add(LegacyMigrationIssue(path: path, message: message));
  }
}
