import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/domain/identity_planner.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

final class ImportPlanningBaseline {
  const ImportPlanningBaseline({
    required this.revision,
    required this.records,
    this.previousSnapshot,
  });

  final int revision;
  final List<LibraryRecord> records;
  final ImportSnapshot? previousSnapshot;

  Map<String, LibraryRecord> get sourceRecords {
    final result = <String, LibraryRecord>{};
    for (final record in records) {
      for (final source in record.identity.sources) {
        result[source.sourceId.value] = record;
      }
    }
    return result;
  }
}

final class ImportPlanner {
  const ImportPlanner({this.identityPlanner = const AnimeIdentityPlanner()});

  final AnimeIdentityPlanner identityPlanner;

  ImportPreview plan({
    required ImportSnapshot snapshot,
    required ImportPlanningBaseline baseline,
    DateTime Function()? clock,
  }) {
    if (!snapshot.isComplete) {
      throw const ImportIntegrityException('未完成的公开收藏快照不能生成可提交预览。');
    }
    final now = (clock ?? (() => DateTime.now().toUtc()))();
    final sourceRecords = baseline.sourceRecords;
    final changes = <ImportChange>[];
    final seen = <String>{};
    final identityBaseline = _identityBaseline(baseline);
    for (final item in snapshot.items) {
      if (!seen.add(item.sourceId)) {
        changes.add(
          ImportChange(
            kind: ImportChangeKind.skipped,
            item: item,
            reason: '同一来源实体在分页中重复，已按来源 ID 去重。',
          ),
        );
        continue;
      }
      final plan = identityPlanner.planObservation(
        item.observation,
        identityBaseline,
      );
      final record = sourceRecords[item.sourceId];
      var kind = _kindForPlan(plan, record, item);
      StateConflict? conflict;
      if (plan.identityId != null && record != null) {
        final current = record.entry;
        final incoming = LibraryEntry(
          identityId: current.identityId,
          status: item.status,
          watched: item.watched,
          totalEpisodes: item.totalEpisodes ?? item.observation.episodes,
          updatedAt: item.observation.observedAt ?? now,
          localRevision: 0,
          modifiedLocally: false,
        );
        final statePlan = identityPlanner.planStateChange(
          current: current,
          incoming: incoming,
          baselineRevision: baseline.revision,
        );
        conflict = statePlan.conflict;
        if (conflict != null) kind = ImportChangeKind.stateConflict;
      }
      changes.add(
        ImportChange(
          kind: kind,
          item: item,
          identityId: plan.identityId,
          candidate: plan.candidate,
          conflict: conflict,
          reason: plan.evidence.explanation,
        ),
      );
    }

    final previous = baseline.previousSnapshot;
    if (previous != null && previous.profile.key == snapshot.profile.key) {
      final currentIds = snapshot.items.map((item) => item.sourceId).toSet();
      for (final oldItem in previous.items) {
        if (currentIds.contains(oldItem.sourceId)) continue;
        changes.add(
          ImportChange(
            kind: ImportChangeKind.remoteMissing,
            item: oldItem,
            reason: '本次完整快照未出现，仅标记来源观察，不删除本地作品或进度。',
          ),
        );
      }
    }

    final counts = ImportPreviewCounts.fromChanges(changes);
    final previousProfile = baseline.previousSnapshot?.profile;
    final accountChange =
        previousProfile != null &&
        previousProfile.key.source == snapshot.profile.key.source &&
        previousProfile.key != snapshot.profile.key;
    final previewId = 'preview:${snapshot.sessionId}:${snapshot.fingerprint}';
    return ImportPreview(
      previewId: previewId,
      snapshot: snapshot,
      baselineRevision: baseline.revision,
      changes: List<ImportChange>.unmodifiable(changes),
      counts: counts,
      createdAt: now,
      accountChangeRequiresConfirmation: accountChange,
    );
  }

  ImportChangeKind _kindForPlan(
    IdentityPlan plan,
    LibraryRecord? record,
    PublicCollectionItem item,
  ) {
    switch (plan.kind) {
      case IdentityPlanKind.createIdentity:
        return ImportChangeKind.added;
      case IdentityPlanKind.candidate:
        return ImportChangeKind.identityCandidate;
      case IdentityPlanKind.enrichIdentity:
        if (record == null) return ImportChangeKind.linked;
        final existing = record.identity.sources.firstWhere(
          (source) => source.sourceId == item.observation.sourceId,
          orElse: () => item.observation,
        );
        return _sameObservation(existing, item.observation)
            ? ImportChangeKind.unchanged
            : ImportChangeKind.observationUpdated;
    }
  }

  bool _sameObservation(SourceObservation left, SourceObservation right) =>
      left.sourceId == right.sourceId &&
      left.title.trim() == right.title.trim() &&
      _sameList(left.aliases, right.aliases) &&
      left.year == right.year &&
      left.season == right.season &&
      left.episodes == right.episodes &&
      left.imageUrl?.toString() == right.imageUrl?.toString();

  bool _sameList(List<String> left, List<String> right) {
    final a = left.map((value) => value.trim()).toSet();
    final b = right.map((value) => value.trim()).toSet();
    return a.length == b.length && a.containsAll(b);
  }

  IdentityPlanningBaseline _identityBaseline(ImportPlanningBaseline baseline) {
    final sourceIdentityIds = <String, AnimeIdentityId>{};
    for (final record in baseline.records) {
      for (final source in record.identity.sources) {
        sourceIdentityIds[source.sourceId.value] = record.identity.id;
      }
    }
    return IdentityPlanningBaseline(
      revision: baseline.revision,
      identities: baseline.records
          .map((record) => record.identity)
          .toList(growable: false),
      sourceIdentityIds: sourceIdentityIds,
      sourceToIdentity: sourceIdentityIds,
      libraryEntries: <AnimeIdentityId, LibraryEntry>{
        for (final record in baseline.records) record.identity.id: record.entry,
      },
    );
  }
}
