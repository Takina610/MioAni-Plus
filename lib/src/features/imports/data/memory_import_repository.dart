import 'package:mio_ani/src/features/imports/data/import_repository.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/imports/domain/import_planner.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/data/memory_library_repository.dart';

final class MemoryImportRepository implements ImportRepository {
  MemoryImportRepository({
    required this.libraryRepository,
    ImportPlanner? planner,
    DateTime Function()? clock,
  }) : _planner = planner ?? const ImportPlanner(),
       _clock = clock ?? (() => DateTime.now().toUtc());

  final LibraryRepository libraryRepository;
  final ImportPlanner _planner;
  final DateTime Function() _clock;
  final Map<String, ImportBatch> _batches = <String, ImportBatch>{};
  final Map<String, ImportSnapshot> _snapshots = <String, ImportSnapshot>{};
  final Map<String, List<BatchContribution>> _contributions =
      <String, List<BatchContribution>>{};
  final Map<String, ImportPreview> _previews = <String, ImportPreview>{};
  int _sequence = 0;

  @override
  Future<ImportPreview> preview(ImportSnapshot snapshot) async {
    if (!snapshot.isComplete) {
      throw const ImportIntegrityException('未完成的快照不能预览或提交。');
    }
    final records = await libraryRepository.readLibrary();
    final previous = lastSuccessfulSnapshot(snapshot.profile.key);
    final preview = _planner.plan(
      snapshot: snapshot.copyWith(
        previousSuccessfulBatchId: _batches.values
            .where(
              (batch) =>
                  batch.profile.key == snapshot.profile.key &&
                  batch.status == ImportBatchStatus.succeeded,
            )
            .fold<ImportBatch?>(null, (latest, batch) {
              if (latest == null || batch.createdAt.isAfter(latest.createdAt)) {
                return batch;
              }
              return latest;
            })
            ?.id,
      ),
      baseline: ImportPlanningBaseline(
        revision: libraryRepository.revision,
        records: records,
        previousSnapshot: previous,
      ),
      clock: _clock,
    );
    final accountChanged = _batches.values.any(
      (batch) =>
          batch.profile.key.source == snapshot.profile.key.source &&
          batch.profile.key != snapshot.profile.key &&
          batch.status == ImportBatchStatus.succeeded,
    );
    final result = ImportPreview(
      previewId: preview.previewId,
      snapshot: preview.snapshot,
      baselineRevision: preview.baselineRevision,
      changes: preview.changes,
      counts: preview.counts,
      createdAt: preview.createdAt,
      accountChangeRequiresConfirmation: accountChanged,
    );
    _previews[result.previewId] = result;
    return result;
  }

  @override
  Future<ImportBatch> commit(
    ImportPreview preview, {
    bool confirmAccountChange = false,
  }) async {
    final snapshot = preview.snapshot;
    if (!snapshot.isComplete) {
      throw const ImportIntegrityException('未完成的快照禁止提交。');
    }
    if (preview.accountChangeRequiresConfirmation && !confirmAccountChange) {
      throw const ImportConfirmationRequiredException(
        '同一来源检测到其他稳定账号，请确认合并且不会删除旧账号条目。',
      );
    }
    final existing = _batches.values.where(
      (batch) =>
          batch.profile.key == snapshot.profile.key &&
          batch.fingerprint == snapshot.fingerprint &&
          batch.status == ImportBatchStatus.succeeded,
    );
    if (existing.isNotEmpty) {
      return existing.reduce(
        (left, right) => left.createdAt.isAfter(right.createdAt) ? left : right,
      );
    }
    final actualRevision = libraryRepository.revision;
    if (actualRevision != preview.baselineRevision) {
      throw ImportPreviewStaleException(
        expected: preview.baselineRevision,
        actual: actualRevision,
      );
    }
    if (!preview.canCommit) {
      throw const ImportIntegrityException('预览仍包含待评审身份候选或状态冲突。');
    }

    final contributionList = <BatchContribution>[];
    final batchId = 'import:${_clock().microsecondsSinceEpoch}:${_sequence++}';
    final rollbackState = libraryRepository is MemoryLibraryRepository
        ? (libraryRepository as MemoryLibraryRepository).captureImportState()
        : null;
    try {
      for (final change in preview.changes) {
        if (change.kind == ImportChangeKind.remoteMissing ||
            change.kind == ImportChangeKind.skipped ||
            change.kind == ImportChangeKind.unchanged) {
          continue;
        }
        final record = await libraryRepository.addLocal(
          change.item.observation,
          status: change.item.status,
          watched: change.item.watched,
        );
        final removable = change.kind == ImportChangeKind.added;
        contributionList.add(
          BatchContribution(
            batchId: batchId,
            sourceId: change.item.sourceId,
            identityId: record.identity.id,
            disposition: removable
                ? ImportUndoDisposition.removable
                : ImportUndoDisposition.protected,
            observedAt: _clock(),
            reason: change.reason,
          ),
        );
      }
    } on Object {
      if (rollbackState != null) {
        (libraryRepository as MemoryLibraryRepository).restoreImportState(
          rollbackState,
        );
      }
      rethrow;
    }
    final previous = _latestBatch(snapshot.profile.key);
    final batch = ImportBatch(
      id: batchId,
      profile: snapshot.profile,
      fingerprint: snapshot.fingerprint,
      createdAt: _clock(),
      pagesFetched: snapshot.pagesFetched,
      declaredTotal: snapshot.declaredTotal,
      itemCount: snapshot.items.length,
      counts: preview.counts,
      status: ImportBatchStatus.succeeded,
      previousBatchId: previous?.id,
    );
    _batches[batch.id] = batch;
    _snapshots[batch.id] = snapshot;
    _contributions[batch.id] = contributionList;
    return batch;
  }

  @override
  Future<UndoPreview> previewUndo(String batchId) async {
    final batch = _batches[batchId];
    if (batch == null) throw const ImportIntegrityException('未找到导入批次。');
    if (batch.isUndone) {
      return UndoPreview(
        batch: batch,
        removable: const <BatchContribution>[],
        protectedContributions:
            _contributions[batchId] ?? const <BatchContribution>[],
        createdAt: _clock(),
      );
    }
    final later = _batches.values.where(
      (candidate) =>
          candidate.profile.key == batch.profile.key &&
          candidate.createdAt.isAfter(batch.createdAt) &&
          !candidate.isUndone,
    );
    final laterSourceIds = later
        .expand(
          (candidate) =>
              _contributions[candidate.id] ?? const <BatchContribution>[],
        )
        .map((item) => item.sourceId)
        .toSet();
    final removable = <BatchContribution>[];
    final protected = <BatchContribution>[];
    for (final contribution
        in _contributions[batchId] ?? const <BatchContribution>[]) {
      final record = contribution.identityId == null
          ? null
          : (await libraryRepository.readLibrary())
                .where((item) => item.identity.id == contribution.identityId)
                .firstOrNull;
      final locallyChanged = record != null && record.entry.localRevision > 1;
      if (contribution.disposition == ImportUndoDisposition.removable &&
          !laterSourceIds.contains(contribution.sourceId) &&
          !locallyChanged) {
        removable.add(contribution);
      } else {
        protected.add(
          BatchContribution(
            batchId: contribution.batchId,
            sourceId: contribution.sourceId,
            identityId: contribution.identityId,
            disposition: ImportUndoDisposition.protected,
            observedAt: contribution.observedAt,
            reason: locallyChanged ? '本地修改过，撤销时保留。' : '存在后续批次或其他依赖。',
          ),
        );
      }
    }
    return UndoPreview(
      batch: batch,
      removable: removable,
      protectedContributions: protected,
      createdAt: _clock(),
    );
  }

  @override
  Future<ImportBatch> undo(String batchId) async {
    final preview = await previewUndo(batchId);
    if (preview.batch.isUndone) return preview.batch;
    for (final contribution in preview.removable) {
      final identityId = contribution.identityId;
      if (identityId != null) await libraryRepository.remove(identityId);
    }
    final undone = ImportBatch(
      id: preview.batch.id,
      profile: preview.batch.profile,
      fingerprint: preview.batch.fingerprint,
      createdAt: preview.batch.createdAt,
      pagesFetched: preview.batch.pagesFetched,
      declaredTotal: preview.batch.declaredTotal,
      itemCount: preview.batch.itemCount,
      counts: preview.batch.counts,
      status: ImportBatchStatus.undone,
      previousBatchId: preview.batch.previousBatchId,
      undoneAt: _clock(),
    );
    _batches[batchId] = undone;
    return undone;
  }

  @override
  List<ImportBatch> history({PublicAccountKey? account}) =>
      _batches.values
          .where((batch) => account == null || batch.profile.key == account)
          .toList(growable: false)
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

  @override
  ImportSnapshot? lastSuccessfulSnapshot(PublicAccountKey account) {
    final latest = _latestBatch(account);
    return latest == null ? null : _snapshots[latest.id];
  }

  List<BatchContribution> contributionsForBatch(String batchId) =>
      List<BatchContribution>.unmodifiable(
        _contributions[batchId] ?? const <BatchContribution>[],
      );

  ImportBatch? _latestBatch(PublicAccountKey account) {
    final batches = _batches.values.where(
      (batch) =>
          batch.profile.key == account &&
          batch.status == ImportBatchStatus.succeeded,
    );
    return batches.isEmpty
        ? null
        : batches.reduce(
            (left, right) =>
                left.createdAt.isAfter(right.createdAt) ? left : right,
          );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
