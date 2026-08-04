import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:mio_ani/src/core/persistence/catalog_database.dart'
    hide AnimeIdentity, IdentityDecision, LibraryEntry;
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/data/memory_library_repository.dart';
import 'package:mio_ani/src/features/library/domain/identity_planner.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';
import 'package:mio_ani/src/features/library/domain/library_query.dart';

/// Drift-backed repository facade. The planner and command semantics are shared
/// with the memory implementation; every successful mutation is mirrored into
/// the C3/C7 tables in one database transaction.
final class DriftLibraryRepository implements LibraryRepository {
  DriftLibraryRepository(
    this.database, {
    AnimeIdentityPlanner? planner,
    DateTime Function()? clock,
  }) : _memory = MemoryLibraryRepository(planner: planner, clock: clock);

  final MioAniDatabase database;
  final MemoryLibraryRepository _memory;
  bool _loaded = false;

  @override
  int get revision => _memory.revision;
  @override
  List<IdentityCandidate> get pendingCandidates => _memory.pendingCandidates;
  @override
  List<IdentityDecision> get decisions => _memory.decisions;

  @override
  Stream<List<LibraryRecord>> watchLibrary({
    LibraryQuery query = const LibraryQuery(),
  }) => _memory.watchLibrary(query: query);

  @override
  Future<List<LibraryRecord>> readLibrary({
    LibraryQuery query = const LibraryQuery(),
  }) async {
    await _ensureLoaded();
    return _memory.readLibrary(query: query);
  }

  @override
  IdentityPlan planObservation(SourceObservation observation) =>
      _memory.planObservation(observation);

  @override
  Future<LibraryRecord> addLocal(
    SourceObservation observation, {
    LibraryWatchStatus status = LibraryWatchStatus.planned,
    int watched = 0,
    int? expectedRevision,
  }) async {
    final record = await _memory.addLocal(
      observation,
      status: status,
      watched: watched,
      expectedRevision: expectedRevision,
    );
    await _upsertRecord(record);
    return record;
  }

  @override
  Future<void> remove(
    AnimeIdentityId identityId, {
    int? expectedRevision,
  }) async {
    await _memory.remove(identityId, expectedRevision: expectedRevision);
    await database.transaction(() async {
      await (database.delete(
        database.libraryEntries,
      )..where((row) => row.identityId.equals(identityId.value))).go();
      await (database.delete(
        database.sourceEntities,
      )..where((row) => row.identityId.equals(identityId.value))).go();
      await (database.delete(
        database.animeIdentities,
      )..where((row) => row.identityId.equals(identityId.value))).go();
    });
  }

  @override
  Future<LibraryEntry> setStatus(
    AnimeIdentityId identityId,
    LibraryWatchStatus status, {
    int? expectedRevision,
  }) async {
    final entry = await _memory.setStatus(
      identityId,
      status,
      expectedRevision: expectedRevision,
    );
    await _upsertEntry(entry);
    return entry;
  }

  @override
  Future<LibraryEntry> setProgress(
    AnimeIdentityId identityId,
    int watched, {
    int? expectedRevision,
  }) async {
    final entry = await _memory.setProgress(
      identityId,
      watched,
      expectedRevision: expectedRevision,
    );
    await _upsertEntry(entry);
    return entry;
  }

  @override
  Future<void> confirmCandidate(
    String candidateId, {
    int? expectedRevision,
  }) async {
    await _memory.confirmCandidate(
      candidateId,
      expectedRevision: expectedRevision,
    );
    await _mirrorAll();
  }

  @override
  Future<void> keepSeparate(String candidateId, {int? expectedRevision}) async {
    await _memory.keepSeparate(candidateId, expectedRevision: expectedRevision);
    await _recordDecision(candidateId, IdentityDecisionKind.keepSeparate);
  }

  @override
  Future<void> ignoreCandidate(
    String candidateId, {
    int? expectedRevision,
  }) async {
    await _memory.ignoreCandidate(
      candidateId,
      expectedRevision: expectedRevision,
    );
    await _recordDecision(candidateId, IdentityDecisionKind.ignore);
  }

  @override
  MergePreview previewMerge(
    AnimeIdentityId leftId,
    AnimeIdentityId rightId, {
    int? expectedRevision,
  }) =>
      _memory.previewMerge(leftId, rightId, expectedRevision: expectedRevision);

  @override
  Future<AnimeIdentityId> commitMerge(
    AnimeIdentityId leftId,
    AnimeIdentityId rightId, {
    int? expectedRevision,
    LibraryWatchStatus? resolvedStatus,
    int? resolvedWatched,
  }) async {
    final result = await _memory.commitMerge(
      leftId,
      rightId,
      expectedRevision: expectedRevision,
      resolvedStatus: resolvedStatus,
      resolvedWatched: resolvedWatched,
    );
    await _mirrorAll();
    return result;
  }

  @override
  SplitPreview previewSplit(
    AnimeIdentityId identityId,
    AnimeIdentityId inheritStateTo, {
    int? expectedRevision,
  }) => _memory.previewSplit(
    identityId,
    inheritStateTo,
    expectedRevision: expectedRevision,
  );

  @override
  Future<List<AnimeIdentityId>> commitSplit(
    AnimeIdentityId identityId,
    AnimeIdentityId inheritStateTo, {
    int? expectedRevision,
  }) async {
    final result = await _memory.commitSplit(
      identityId,
      inheritStateTo,
      expectedRevision: expectedRevision,
    );
    await _mirrorAll();
    return result;
  }

  @override
  Future<LibraryOperation?> undo(String operationId) async {
    final result = await _memory.undo(operationId);
    if (result != null) await _mirrorAll();
    return result;
  }

  @override
  Future<void> clearPublicCache() => database.clearPublicCache();

  @override
  Future<void> clearFlutterUserData() async {
    await database.transaction(() async {
      await database.delete(database.libraryEntries).go();
      await database.delete(database.sourceEntities).go();
      await database.delete(database.animeIdentities).go();
      await database.delete(database.identityEvidenceRecords).go();
      await database.delete(database.identityReviews).go();
      await database.delete(database.identityDecisions).go();
      await database.delete(database.identityOperationLogs).go();
      await database.delete(database.publicAccounts).go();
      await database.delete(database.appSettings).go();
    });
    await _memory.clearFlutterUserData();
  }

  @override
  Future<void> deleteVueLegacyKeys() async {
    if (!kIsWeb) {
      throw const LibraryRepositoryException('删除 Vue 旧键仅可在 Web 平台执行。');
    }
    await _memory.deleteVueLegacyKeys();
  }

  Future<void> _upsertRecord(LibraryRecord record) async {
    final now = record.entry.updatedAt.toUtc().millisecondsSinceEpoch;
    await database.transaction(() async {
      await database
          .into(database.animeIdentities)
          .insertOnConflictUpdate(
            AnimeIdentitiesCompanion.insert(
              identityId: record.identity.id.value,
              canonicalTitle: Value(record.identity.canonicalTitle),
              createdAt: now,
              updatedAt: now,
              revision: Value(record.identity.revision),
            ),
          );
      for (final source in record.identity.sources) {
        await database
            .into(database.sourceEntities)
            .insertOnConflictUpdate(
              SourceEntitiesCompanion.insert(
                source: source.sourceId.source.name,
                sourceId: source.sourceId.rawId.toString(),
                identityId: record.identity.id.value,
                title: Value(source.title),
                originalTitle: Value(
                  source.aliases.isEmpty ? '' : source.aliases.first,
                ),
                imageUrl: Value(source.imageUrl?.toString()),
                year: Value(source.year),
                episodes: Value(source.episodes),
                observedAt:
                    source.observedAt?.toUtc().millisecondsSinceEpoch ?? now,
                revision: const Value(0),
              ),
            );
      }
      await _upsertEntry(record.entry);
    });
  }

  Future<void> _upsertEntry(LibraryEntry entry) async {
    await database
        .into(database.libraryEntries)
        .insertOnConflictUpdate(
          LibraryEntriesCompanion.insert(
            identityId: entry.identityId.value,
            status: Value(entry.status.name),
            watched: Value(entry.watched),
            localRevision: Value(entry.localRevision),
            updatedAt: entry.updatedAt.toUtc().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> _mirrorAll() async {
    final records = await _memory.readLibrary();
    for (final record in records) {
      await _upsertRecord(record);
    }
  }

  Future<void> _recordDecision(
    String reviewId,
    IdentityDecisionKind kind,
  ) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await database
        .into(database.identityDecisions)
        .insertOnConflictUpdate(
          IdentityDecisionsCompanion.insert(
            decisionId: 'decision:$reviewId:$now',
            reviewId: reviewId,
            kind: kind.name,
            createdAt: now,
          ),
        );
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final identityRows = await database.select(database.animeIdentities).get();
    final sourceRows = await database.select(database.sourceEntities).get();
    final entryRows = await database.select(database.libraryEntries).get();
    final observations = <String, List<SourceObservation>>{};
    for (final row in sourceRows) {
      final prefix = switch (row.source) {
        'bangumi' => 'bgm',
        'anilist' => 'anilist',
        _ => null,
      };
      final sourceId = prefix == null
          ? null
          : AnimeSourceId.tryParse('$prefix-${row.sourceId}');
      if (sourceId == null) continue;
      (observations[row.identityId] ??= <SourceObservation>[]).add(
        SourceObservation(
          sourceId: sourceId,
          title: row.title,
          aliases: row.originalTitle.isEmpty
              ? const <String>[]
              : <String>[row.originalTitle],
          year: row.year,
          episodes: row.episodes,
          imageUrl: row.imageUrl == null ? null : Uri.tryParse(row.imageUrl!),
          observedAt: DateTime.fromMillisecondsSinceEpoch(
            row.observedAt,
            isUtc: true,
          ),
        ),
      );
    }
    final identityById = <String, AnimeIdentity>{};
    for (final row in identityRows) {
      final id = AnimeIdentityId.tryParse(row.identityId);
      if (id == null) continue;
      identityById[row.identityId] = AnimeIdentity(
        id: id,
        sources: List<SourceObservation>.unmodifiable(
          observations[row.identityId] ?? const <SourceObservation>[],
        ),
        canonicalTitle: row.canonicalTitle,
        revision: row.revision,
      );
    }
    for (final row in entryRows) {
      final identity = identityById[row.identityId];
      if (identity == null) continue;
      final status = LibraryWatchStatus.values.firstWhere(
        (item) => item.name == row.status,
        orElse: () => LibraryWatchStatus.planned,
      );
      final total = identity.sources
          .map((item) => item.episodes)
          .whereType<int>()
          .fold<int?>(
            null,
            (int? value, int item) =>
                value == null || item > value ? item : value,
          );
      _memory.seedRecord(
        LibraryRecord(
          identity: identity,
          entry: LibraryEntry(
            identityId: identity.id,
            status: status,
            watched: row.watched,
            totalEpisodes: total,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              row.updatedAt,
              isUtc: true,
            ),
            localRevision: row.localRevision,
            modifiedLocally: row.localRevision > 0,
          ),
        ),
      );
    }
  }

  void dispose() {
    _memory.dispose();
  }
}
