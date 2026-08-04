import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/domain/identity_planner.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';
import 'package:mio_ani/src/features/library/domain/library_query.dart';

final class MemoryLibraryRepository implements LibraryRepository {
  MemoryLibraryRepository({
    AnimeIdentityPlanner? planner,
    DateTime Function()? clock,
  }) : _planner = planner ?? const AnimeIdentityPlanner(),
       _clock = clock ?? (() => DateTime.now().toUtc());

  final AnimeIdentityPlanner _planner;
  final DateTime Function() _clock;
  final Map<AnimeIdentityId, AnimeIdentity> _identities =
      <AnimeIdentityId, AnimeIdentity>{};
  final Map<AnimeIdentityId, LibraryEntry> _entries =
      <AnimeIdentityId, LibraryEntry>{};
  final Map<String, IdentityCandidate> _candidates =
      <String, IdentityCandidate>{};
  final List<IdentityDecision> _decisions = <IdentityDecision>[];
  final Map<String, LibraryOperation> _operations =
      <String, LibraryOperation>{};
  final Map<String, void Function()> _inverse = <String, void Function()>{};
  final Set<String> _suppressedPairs = <String>{};
  final StreamController<List<LibraryRecord>> _changes =
      StreamController<List<LibraryRecord>>.broadcast();
  int _revision = 0;
  bool _publicCacheCleared = false;
  bool _flutterUserDataCleared = false;
  bool _vueLegacyKeysDeleted = false;

  @override
  int get revision => _revision;
  bool get publicCacheCleared => _publicCacheCleared;
  bool get flutterUserDataCleared => _flutterUserDataCleared;
  bool get vueLegacyKeysDeleted => _vueLegacyKeysDeleted;

  /// Seeds records loaded from Drift without creating a user operation.
  void seedRecord(LibraryRecord record) {
    _identities[record.identity.id] = record.identity;
    _entries[record.entry.identityId] = record.entry;
    if (record.identity.revision > _revision) {
      _revision = record.identity.revision;
    }
    if (record.entry.localRevision > _revision) {
      _revision = record.entry.localRevision;
    }
  }

  @override
  List<IdentityCandidate> get pendingCandidates => _candidates.values
      .where((item) => item.status == IdentityReviewStatus.pending)
      .toList(growable: false);
  @override
  List<IdentityDecision> get decisions =>
      List<IdentityDecision>.unmodifiable(_decisions);

  @override
  Stream<List<LibraryRecord>> watchLibrary({
    LibraryQuery query = const LibraryQuery(),
  }) async* {
    yield await readLibrary(query: query);
    yield* _changes.stream.asyncMap((_) => readLibrary(query: query));
  }

  @override
  Future<List<LibraryRecord>> readLibrary({
    LibraryQuery query = const LibraryQuery(),
  }) async {
    final normalized = query.normalized();
    final records = _entries.entries
        .map((item) {
          final identity = _identities[item.key];
          if (identity == null) return null;
          return LibraryRecord(identity: identity, entry: item.value);
        })
        .whereType<LibraryRecord>()
        .where((record) {
          final status = normalized.group.status;
          if (status != null && record.entry.status != status) return false;
          if (normalized.query.isNotEmpty &&
              !SourceObservation.normalizeTitle(
                record.title,
              ).contains(SourceObservation.normalizeTitle(normalized.query))) {
            return false;
          }
          return true;
        })
        .toList();
    records.sort((left, right) {
      final result = switch (normalized.sort) {
        LibrarySort.title => left.title.toLowerCase().compareTo(
          right.title.toLowerCase(),
        ),
        LibrarySort.progress => left.entry.watched.compareTo(
          right.entry.watched,
        ),
        LibrarySort.updated => left.entry.updatedAt.compareTo(
          right.entry.updatedAt,
        ),
      };
      return normalized.descending ? -result : result;
    });
    return List<LibraryRecord>.unmodifiable(records);
  }

  @override
  IdentityPlan planObservation(SourceObservation observation) =>
      _planner.planObservation(observation, _baseline());

  @override
  Future<LibraryRecord> addLocal(
    SourceObservation observation, {
    LibraryWatchStatus status = LibraryWatchStatus.planned,
    int watched = 0,
    int? expectedRevision,
  }) async {
    _checkRevision(expectedRevision);
    final plan = planObservation(observation);
    if (plan.kind == IdentityPlanKind.candidate) {
      final candidate = plan.candidate!;
      _candidates[candidate.id] = candidate;
      final identityId = AnimeIdentityId.fromSources(<SourceAnimeId>[
        observation.sourceId,
      ]);
      final identity = AnimeIdentity(
        id: identityId,
        sources: <SourceObservation>[observation],
        canonicalTitle: observation.title,
        revision: _revision + 1,
      );
      final entry = LibraryEntry(
        identityId: identityId,
        status: status,
        watched: watched,
        totalEpisodes: observation.episodes,
        updatedAt: _clock(),
        localRevision: 1,
        modifiedLocally: true,
      );
      _validateEntry(entry);
      _identities[identityId] = identity;
      _entries[identityId] = entry;
      _revision++;
      _emit();
      throw LibraryReviewRequired(candidate.id);
    }
    final before = _capture();
    final identityId = plan.identityId!;
    var identity = _identities[identityId];
    if (identity == null) {
      identity = AnimeIdentity(
        id: identityId,
        sources: <SourceObservation>[observation],
        canonicalTitle: observation.title,
        revision: _revision + 1,
      );
      _identities[identityId] = identity;
    } else if (!identity.sources.any(
      (source) => source.sourceId == observation.sourceId,
    )) {
      identity = identity.copyWith(
        sources: <SourceObservation>[...identity.sources, observation],
        revision: identity.revision + 1,
      );
      _identities[identityId] = identity;
    }
    final current = _entries[identityId];
    if (current == null) {
      final entry = LibraryEntry(
        identityId: identityId,
        status: status,
        watched: watched,
        totalEpisodes: observation.episodes,
        updatedAt: _clock(),
        localRevision: 1,
        modifiedLocally: true,
      );
      _validateEntry(entry);
      _entries[identityId] = entry;
    } else {
      final incoming = current.copyWith(
        totalEpisodes: observation.episodes ?? current.totalEpisodes,
        updatedAt: _clock(),
      );
      _entries[identityId] = _planner
          .planStateChange(
            current: current,
            incoming: incoming,
            baselineRevision: _revision,
          )
          .result;
    }
    final op = _record(LibraryOperationKind.add, <String, Object?>{
      'identityId': identityId.value,
    }, () => _restore(before));
    final result = LibraryRecord(
      identity: _identities[identityId]!,
      entry: _entries[identityId]!,
    );
    _emit();
    _operations[op.id] = op;
    return result;
  }

  @override
  Future<void> remove(
    AnimeIdentityId identityId, {
    int? expectedRevision,
  }) async {
    _checkRevision(expectedRevision);
    if (!_identities.containsKey(identityId)) return;
    final before = _capture();
    _entries.remove(identityId);
    _identities.remove(identityId);
    final op = _record(LibraryOperationKind.remove, <String, Object?>{
      'identityId': identityId.value,
    }, () => _restore(before));
    _operations[op.id] = op;
    _emit();
  }

  @override
  Future<LibraryEntry> setStatus(
    AnimeIdentityId identityId,
    LibraryWatchStatus status, {
    int? expectedRevision,
  }) async {
    _checkRevision(expectedRevision);
    final current = _requireEntry(identityId);
    final before = _capture();
    final next = current.copyWith(
      status: status,
      updatedAt: _clock(),
      localRevision: current.localRevision + 1,
      modifiedLocally: true,
    );
    _entries[identityId] = next;
    final op = _record(LibraryOperationKind.setStatus, <String, Object?>{
      'identityId': identityId.value,
      'status': status.name,
    }, () => _restore(before));
    _operations[op.id] = op;
    _emit();
    return next;
  }

  @override
  Future<LibraryEntry> setProgress(
    AnimeIdentityId identityId,
    int watched, {
    int? expectedRevision,
  }) async {
    _checkRevision(expectedRevision);
    final current = _requireEntry(identityId);
    if (watched < 0) {
      throw ArgumentError.value(watched, 'watched', 'must be non-negative');
    }
    if (current.totalEpisodes != null && watched > current.totalEpisodes!) {
      throw ArgumentError.value(
        watched,
        'watched',
        'cannot exceed known total episodes',
      );
    }
    final before = _capture();
    final next = current.copyWith(
      watched: watched,
      updatedAt: _clock(),
      localRevision: current.localRevision + 1,
      modifiedLocally: true,
    );
    _entries[identityId] = next;
    final op = _record(LibraryOperationKind.setProgress, <String, Object?>{
      'identityId': identityId.value,
      'watched': watched,
    }, () => _restore(before));
    _operations[op.id] = op;
    _emit();
    return next;
  }

  @override
  Future<void> confirmCandidate(
    String candidateId, {
    int? expectedRevision,
  }) async {
    _checkRevision(expectedRevision);
    final candidate = _candidates[candidateId];
    if (candidate == null) throw LibraryRepositoryException('未找到身份候选。');
    final left = _identities.values.firstWhere(
      (identity) => identity.sourceIds.contains(candidate.left.sourceId),
    );
    final right = _identities.values.firstWhere(
      (identity) => identity.sourceIds.contains(candidate.right.sourceId),
    );
    await commitMerge(left.id, right.id, expectedRevision: _revision);
    _candidates[candidateId] = IdentityCandidate(
      id: candidate.id,
      left: candidate.left,
      right: candidate.right,
      evidence: candidate.evidence,
      status: IdentityReviewStatus.confirmed,
      baselineRevision: candidate.baselineRevision,
    );
    _decisions.add(
      _planner.decision(
        reviewId: candidateId,
        kind: IdentityDecisionKind.confirm,
        explanation: '用户确认候选合并。',
        now: _clock(),
      ),
    );
  }

  @override
  Future<void> keepSeparate(
    String candidateId, {
    int? expectedRevision,
  }) async => _decideCandidate(
    candidateId,
    IdentityDecisionKind.keepSeparate,
    IdentityReviewStatus.ignored,
    expectedRevision,
  );

  @override
  Future<void> ignoreCandidate(
    String candidateId, {
    int? expectedRevision,
  }) async => _decideCandidate(
    candidateId,
    IdentityDecisionKind.ignore,
    IdentityReviewStatus.ignored,
    expectedRevision,
  );

  Future<void> _decideCandidate(
    String candidateId,
    IdentityDecisionKind kind,
    IdentityReviewStatus status,
    int? expectedRevision,
  ) async {
    _checkRevision(expectedRevision);
    final candidate = _candidates[candidateId];
    if (candidate == null) throw LibraryRepositoryException('未找到身份候选。');
    final before = _capture();
    _candidates[candidateId] = IdentityCandidate(
      id: candidate.id,
      left: candidate.left,
      right: candidate.right,
      evidence: candidate.evidence,
      status: status,
      baselineRevision: candidate.baselineRevision,
    );
    _suppressedPairs.add(candidate.suppressionKey);
    _decisions.add(
      _planner.decision(
        reviewId: candidateId,
        kind: kind,
        explanation: kind == IdentityDecisionKind.ignore
            ? '用户忽略此候选。'
            : '用户要求保持分开。',
        now: _clock(),
      ),
    );
    final op = _record(LibraryOperationKind.decision, <String, Object?>{
      'candidateId': candidateId,
      'kind': kind.name,
    }, () => _restore(before));
    _operations[op.id] = op;
    _emit();
  }

  @override
  MergePreview previewMerge(
    AnimeIdentityId leftId,
    AnimeIdentityId rightId, {
    int? expectedRevision,
  }) {
    _checkRevision(expectedRevision);
    final left = _requireIdentity(leftId);
    final right = _requireIdentity(rightId);
    return _planner.previewMerge(
      left: left,
      right: right,
      leftEntry: _entries[leftId],
      rightEntry: _entries[rightId],
      baselineRevision: _revision,
      expectedRevision: expectedRevision,
    );
  }

  @override
  Future<AnimeIdentityId> commitMerge(
    AnimeIdentityId leftId,
    AnimeIdentityId rightId, {
    int? expectedRevision,
    LibraryWatchStatus? resolvedStatus,
    int? resolvedWatched,
  }) async {
    _checkRevision(expectedRevision);
    final preview = previewMerge(leftId, rightId, expectedRevision: _revision);
    if (preview.conflict != null && resolvedStatus == null) {
      throw const LibraryStateConflictException();
    }
    final before = _capture();
    final leftEntry = _entries[leftId];
    final rightEntry = _entries[rightId];
    _identities.remove(leftId);
    _identities.remove(rightId);
    _entries.remove(leftId);
    _entries.remove(rightId);
    _identities[preview.result.id] = preview.result;
    if (leftEntry != null || rightEntry != null) {
      final watched =
          resolvedWatched ??
          [
            leftEntry?.watched ?? 0,
            rightEntry?.watched ?? 0,
          ].reduce((a, b) => a > b ? a : b);
      final total = [leftEntry?.totalEpisodes, rightEntry?.totalEpisodes]
          .whereType<int>()
          .fold<int?>(
            null,
            (value, item) => value == null || item > value ? item : value,
          );
      final status =
          resolvedStatus ??
          leftEntry?.status ??
          rightEntry?.status ??
          LibraryWatchStatus.planned;
      final entry = LibraryEntry(
        identityId: preview.result.id,
        status: status,
        watched: watched,
        totalEpisodes: total,
        updatedAt: _clock(),
        localRevision:
            (leftEntry?.localRevision ?? 0) +
            (rightEntry?.localRevision ?? 0) +
            1,
        modifiedLocally: true,
      );
      _validateEntry(entry);
      _entries[preview.result.id] = entry;
    }
    final op = _record(LibraryOperationKind.merge, <String, Object?>{
      'left': leftId.value,
      'right': rightId.value,
      'result': preview.result.id.value,
    }, () => _restore(before));
    _operations[op.id] = op;
    _emit();
    return preview.result.id;
  }

  @override
  SplitPreview previewSplit(
    AnimeIdentityId identityId,
    AnimeIdentityId inheritStateTo, {
    int? expectedRevision,
  }) {
    _checkRevision(expectedRevision);
    final identity = _requireIdentity(identityId);
    return _planner.previewSplit(
      identity: identity,
      inheritStateTo: inheritStateTo,
      baselineRevision: _revision,
      expectedRevision: expectedRevision,
    );
  }

  @override
  Future<List<AnimeIdentityId>> commitSplit(
    AnimeIdentityId identityId,
    AnimeIdentityId inheritStateTo, {
    int? expectedRevision,
  }) async {
    _checkRevision(expectedRevision);
    final preview = previewSplit(
      identityId,
      inheritStateTo,
      expectedRevision: _revision,
    );
    final before = _capture();
    final oldEntry = _entries.remove(identityId);
    _identities.remove(identityId);
    for (final result in preview.results) {
      _identities[result.id] = result;
    }
    if (oldEntry != null) {
      final inherited = oldEntry.copyWith(
        identityId: preview.inheritStateTo,
        updatedAt: _clock(),
        localRevision: oldEntry.localRevision + 1,
      );
      _entries[preview.inheritStateTo] = inherited;
    }
    final op = _record(LibraryOperationKind.split, <String, Object?>{
      'identityId': identityId.value,
      'inherit': preview.inheritStateTo.value,
    }, () => _restore(before));
    _operations[op.id] = op;
    _emit();
    return preview.results.map((item) => item.id).toList(growable: false);
  }

  @override
  Future<LibraryOperation?> undo(String operationId) async {
    final operation = _operations[operationId];
    final inverse = _inverse[operationId];
    if (operation == null || inverse == null || operation.undoneAt != null) {
      return null;
    }
    inverse();
    _operations[operationId] = LibraryOperation(
      id: operation.id,
      kind: operation.kind,
      createdAt: operation.createdAt,
      payload: operation.payload,
      undoneAt: _clock(),
    );
    _revision++;
    _emit();
    return _operations[operationId];
  }

  @override
  Future<void> clearPublicCache() async {
    _publicCacheCleared = true;
  }

  @override
  Future<void> clearFlutterUserData() async {
    final before = _capture();
    _identities.clear();
    _entries.clear();
    _candidates.clear();
    _decisions.clear();
    _flutterUserDataCleared = true;
    _revision++;
    _inverse['clear-user-data-$_revision'] = () => _restore(before);
    _emit();
  }

  @override
  Future<void> deleteVueLegacyKeys() async {
    if (!kIsWeb) {
      throw const LibraryRepositoryException('删除 Vue 旧键仅可在 Web 平台执行。');
    }
    _vueLegacyKeysDeleted = true;
  }

  void dispose() => _changes.close();

  void _checkRevision(int? expected) {
    if (expected != null && expected != _revision) {
      throw LibraryRevisionConflict(expected: expected, actual: _revision);
    }
  }

  AnimeIdentity _requireIdentity(AnimeIdentityId id) =>
      _identities[id] ?? (throw LibraryRepositoryException('未找到作品身份。'));
  LibraryEntry _requireEntry(AnimeIdentityId id) =>
      _entries[id] ?? (throw LibraryRepositoryException('该作品尚未加入追番库。'));
  IdentityPlanningBaseline _baseline() {
    final sourceIds = <String, AnimeIdentityId>{};
    for (final identity in _identities.values) {
      for (final source in identity.sources) {
        sourceIds[source.sourceId.value] = identity.id;
      }
    }
    return IdentityPlanningBaseline(
      revision: _revision,
      identities: _identities.values.toList(growable: false),
      sourceIdentityIds: sourceIds,
      suppressedPairs: _suppressedPairs,
      libraryEntries: _entries,
    );
  }

  void _validateEntry(LibraryEntry entry) {
    if (entry.watched < 0) throw ArgumentError.value(entry.watched, 'watched');
    if (entry.totalEpisodes != null && entry.totalEpisodes! < entry.watched) {
      throw ArgumentError.value(entry.watched, 'watched');
    }
  }

  LibraryOperation _record(
    LibraryOperationKind kind,
    Map<String, Object?> payload,
    void Function() inverse,
  ) {
    _revision++;
    final operation = LibraryOperation(
      id: 'op-$_revision',
      kind: kind,
      createdAt: _clock(),
      payload: payload,
    );
    _operations[operation.id] = operation;
    _inverse[operation.id] = inverse;
    return operation;
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(const <LibraryRecord>[]);
  }

  _MemorySnapshot _capture() => _MemorySnapshot(
    Map<AnimeIdentityId, AnimeIdentity>.from(_identities),
    Map<AnimeIdentityId, LibraryEntry>.from(_entries),
    Map<String, IdentityCandidate>.from(_candidates),
    List<IdentityDecision>.from(_decisions),
    Set<String>.from(_suppressedPairs),
    _publicCacheCleared,
    _flutterUserDataCleared,
    _vueLegacyKeysDeleted,
    _revision,
  );
  void _restore(_MemorySnapshot snapshot) {
    _identities
      ..clear()
      ..addAll(snapshot.identities);
    _entries
      ..clear()
      ..addAll(snapshot.entries);
    _candidates
      ..clear()
      ..addAll(snapshot.candidates);
    _decisions
      ..clear()
      ..addAll(snapshot.decisions);
    _suppressedPairs
      ..clear()
      ..addAll(snapshot.suppressedPairs);
    _publicCacheCleared = snapshot.publicCacheCleared;
    _flutterUserDataCleared = snapshot.flutterUserDataCleared;
    _vueLegacyKeysDeleted = snapshot.vueLegacyKeysDeleted;
    _revision = snapshot.revision;
  }
}

final class _MemorySnapshot {
  const _MemorySnapshot(
    this.identities,
    this.entries,
    this.candidates,
    this.decisions,
    this.suppressedPairs,
    this.publicCacheCleared,
    this.flutterUserDataCleared,
    this.vueLegacyKeysDeleted,
    this.revision,
  );
  final Map<AnimeIdentityId, AnimeIdentity> identities;
  final Map<AnimeIdentityId, LibraryEntry> entries;
  final Map<String, IdentityCandidate> candidates;
  final List<IdentityDecision> decisions;
  final Set<String> suppressedPairs;
  final bool publicCacheCleared;
  final bool flutterUserDataCleared;
  final bool vueLegacyKeysDeleted;
  final int revision;
}
