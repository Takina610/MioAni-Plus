import 'package:mio_ani/src/features/library/domain/library_models.dart';

enum ImportSource { bangumi, anilist }

enum ImportStage {
  idle,
  resolving,
  fetchingPages,
  planning,
  previewing,
  committing,
  succeeded,
  failed,
  cancelled,
  previewStale,
}

enum ImportIntegrityStatus {
  collecting,
  complete,
  incomplete,
  cancelled,
  failed,
}

enum ImportChangeKind {
  added,
  observationUpdated,
  linked,
  identityCandidate,
  stateConflict,
  skipped,
  remoteMissing,
  unchanged,
}

enum ImportBatchStatus { succeeded, undone }

enum ImportUndoDisposition { removable, protected }

final class PublicAccountKey {
  const PublicAccountKey({required this.source, required this.stableUserId});

  final ImportSource source;
  final String stableUserId;

  String get value => '${source.name}:$stableUserId';

  @override
  bool operator ==(Object other) =>
      other is PublicAccountKey &&
      other.source == source &&
      other.stableUserId == stableUserId;

  @override
  int get hashCode => Object.hash(source, stableUserId);

  @override
  String toString() => value;
}

final class PublicAccountProfile {
  const PublicAccountProfile({
    required this.key,
    required this.displayName,
    required this.inputAlias,
  });

  final PublicAccountKey key;
  final String displayName;
  final String inputAlias;

  PublicAccountProfile copyWith({
    PublicAccountKey? key,
    String? displayName,
    String? inputAlias,
  }) => PublicAccountProfile(
    key: key ?? this.key,
    displayName: displayName ?? this.displayName,
    inputAlias: inputAlias ?? this.inputAlias,
  );
}

final class PublicCollectionItem {
  const PublicCollectionItem({
    required this.observation,
    required this.status,
    required this.watched,
    this.totalEpisodes,
  });

  final SourceObservation observation;
  final LibraryWatchStatus status;
  final int watched;
  final int? totalEpisodes;

  String get sourceId => observation.sourceId.value;

  PublicCollectionItem copyWith({
    SourceObservation? observation,
    LibraryWatchStatus? status,
    int? watched,
    int? totalEpisodes,
  }) => PublicCollectionItem(
    observation: observation ?? this.observation,
    status: status ?? this.status,
    watched: watched ?? this.watched,
    totalEpisodes: totalEpisodes ?? this.totalEpisodes,
  );
}

final class CollectionPage {
  const CollectionPage({
    required this.page,
    required this.items,
    required this.hasNextPage,
    this.declaredTotal,
    this.cursor,
  });

  final int page;
  final List<PublicCollectionItem> items;
  final bool hasNextPage;
  final int? declaredTotal;
  final String? cursor;
}

final class ImportProgress {
  const ImportProgress({
    required this.stage,
    required this.pagesFetched,
    required this.itemsParsed,
    this.declaredTotal,
    this.message,
  });

  final ImportStage stage;
  final int pagesFetched;
  final int itemsParsed;
  final int? declaredTotal;
  final String? message;

  double? get fraction {
    final total = declaredTotal;
    if (total == null || total <= 0) return null;
    return (itemsParsed / total).clamp(0.0, 1.0);
  }
}

final class ImportSnapshot {
  const ImportSnapshot({
    required this.sessionId,
    required this.profile,
    required this.items,
    required this.pagesFetched,
    required this.declaredTotal,
    required this.fingerprint,
    required this.status,
    required this.createdAt,
    this.previousSuccessfulBatchId,
  });

  final String sessionId;
  final PublicAccountProfile profile;
  final List<PublicCollectionItem> items;
  final int pagesFetched;
  final int? declaredTotal;
  final String fingerprint;
  final ImportIntegrityStatus status;
  final DateTime createdAt;
  final String? previousSuccessfulBatchId;

  bool get isComplete => status == ImportIntegrityStatus.complete;
  bool get isEmpty => items.isEmpty;

  ImportSnapshot copyWith({
    List<PublicCollectionItem>? items,
    int? pagesFetched,
    int? declaredTotal,
    String? fingerprint,
    ImportIntegrityStatus? status,
    String? previousSuccessfulBatchId,
  }) => ImportSnapshot(
    sessionId: sessionId,
    profile: profile,
    items: items ?? this.items,
    pagesFetched: pagesFetched ?? this.pagesFetched,
    declaredTotal: declaredTotal ?? this.declaredTotal,
    fingerprint: fingerprint ?? this.fingerprint,
    status: status ?? this.status,
    createdAt: createdAt,
    previousSuccessfulBatchId:
        previousSuccessfulBatchId ?? this.previousSuccessfulBatchId,
  );
}

final class ImportChange {
  const ImportChange({
    required this.kind,
    required this.item,
    this.identityId,
    this.candidate,
    this.conflict,
    this.reason,
  });

  final ImportChangeKind kind;
  final PublicCollectionItem item;
  final AnimeIdentityId? identityId;
  final IdentityCandidate? candidate;
  final StateConflict? conflict;
  final String? reason;
}

final class ImportPreviewCounts {
  const ImportPreviewCounts({
    this.added = 0,
    this.observationUpdated = 0,
    this.linked = 0,
    this.identityCandidates = 0,
    this.stateConflicts = 0,
    this.skipped = 0,
    this.remoteMissing = 0,
    this.unchanged = 0,
  });

  final int added;
  final int observationUpdated;
  final int linked;
  final int identityCandidates;
  final int stateConflicts;
  final int skipped;
  final int remoteMissing;
  final int unchanged;

  int get total =>
      added +
      observationUpdated +
      linked +
      identityCandidates +
      stateConflicts +
      skipped +
      remoteMissing +
      unchanged;

  factory ImportPreviewCounts.fromChanges(Iterable<ImportChange> changes) {
    var added = 0;
    var observationUpdated = 0;
    var linked = 0;
    var identityCandidates = 0;
    var stateConflicts = 0;
    var skipped = 0;
    var remoteMissing = 0;
    var unchanged = 0;
    for (final change in changes) {
      switch (change.kind) {
        case ImportChangeKind.added:
          added++;
        case ImportChangeKind.observationUpdated:
          observationUpdated++;
        case ImportChangeKind.linked:
          linked++;
        case ImportChangeKind.identityCandidate:
          identityCandidates++;
        case ImportChangeKind.stateConflict:
          stateConflicts++;
        case ImportChangeKind.skipped:
          skipped++;
        case ImportChangeKind.remoteMissing:
          remoteMissing++;
        case ImportChangeKind.unchanged:
          unchanged++;
      }
    }
    return ImportPreviewCounts(
      added: added,
      observationUpdated: observationUpdated,
      linked: linked,
      identityCandidates: identityCandidates,
      stateConflicts: stateConflicts,
      skipped: skipped,
      remoteMissing: remoteMissing,
      unchanged: unchanged,
    );
  }
}

final class ImportPreview {
  const ImportPreview({
    required this.previewId,
    required this.snapshot,
    required this.baselineRevision,
    required this.changes,
    required this.counts,
    required this.createdAt,
    this.accountChangeRequiresConfirmation = false,
  });

  final String previewId;
  final ImportSnapshot snapshot;
  final int baselineRevision;
  final List<ImportChange> changes;
  final ImportPreviewCounts counts;
  final DateTime createdAt;
  final bool accountChangeRequiresConfirmation;

  bool get canCommit =>
      snapshot.isComplete &&
      counts.identityCandidates == 0 &&
      counts.stateConflicts == 0;
}

final class ImportBatch {
  const ImportBatch({
    required this.id,
    required this.profile,
    required this.fingerprint,
    required this.createdAt,
    required this.pagesFetched,
    required this.declaredTotal,
    required this.itemCount,
    required this.counts,
    required this.status,
    this.previousBatchId,
    this.undoneAt,
  });

  final String id;
  final PublicAccountProfile profile;
  final String fingerprint;
  final DateTime createdAt;
  final int pagesFetched;
  final int? declaredTotal;
  final int itemCount;
  final ImportPreviewCounts counts;
  final ImportBatchStatus status;
  final String? previousBatchId;
  final DateTime? undoneAt;

  bool get isUndone => status == ImportBatchStatus.undone;
}

final class BatchContribution {
  const BatchContribution({
    required this.batchId,
    required this.sourceId,
    required this.disposition,
    required this.observedAt,
    this.identityId,
    this.reason,
  });

  final String batchId;
  final String sourceId;
  final ImportUndoDisposition disposition;
  final DateTime observedAt;
  final AnimeIdentityId? identityId;
  final String? reason;
}

final class UndoPreview {
  const UndoPreview({
    required this.batch,
    required this.removable,
    required this.protectedContributions,
    required this.createdAt,
  });

  final ImportBatch batch;
  final List<BatchContribution> removable;
  final List<BatchContribution> protectedContributions;
  final DateTime createdAt;

  bool get canUndo => removable.isNotEmpty || protectedContributions.isEmpty;
}

final class ImportIntegrityException implements Exception {
  const ImportIntegrityException(this.message);
  final String message;
  @override
  String toString() => message;
}

final class ImportPreviewStaleException implements Exception {
  const ImportPreviewStaleException({
    required this.expected,
    required this.actual,
  });
  final int expected;
  final int actual;
  @override
  String toString() =>
      'Import preview is stale: expected $expected, actual $actual';
}

final class ImportConfirmationRequiredException implements Exception {
  const ImportConfirmationRequiredException(this.message);
  final String message;
  @override
  String toString() => message;
}
