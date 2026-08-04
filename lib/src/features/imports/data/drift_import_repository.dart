import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/imports/data/import_codec.dart';
import 'package:mio_ani/src/features/imports/data/import_repository.dart';
import 'package:mio_ani/src/features/imports/data/memory_import_repository.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';

final class DriftImportRepository implements ImportRepository {
  DriftImportRepository({
    required this.database,
    required this.libraryRepository,
    MemoryImportRepository? memory,
    DateTime Function()? clock,
  }) : _memory =
           memory ??
           MemoryImportRepository(
             libraryRepository: libraryRepository,
             clock: clock,
           );

  final MioAniDatabase database;
  final LibraryRepository libraryRepository;
  final MemoryImportRepository _memory;

  @override
  Future<ImportPreview> preview(ImportSnapshot snapshot) =>
      _memory.preview(snapshot);

  @override
  Future<ImportBatch> commit(
    ImportPreview preview, {
    bool confirmAccountChange = false,
  }) async {
    final batch = await _memory.commit(
      preview,
      confirmAccountChange: confirmAccountChange,
    );
    final contributions = _memory.contributionsForBatch(batch.id);
    final now = batch.createdAt.toUtc().millisecondsSinceEpoch;
    await database.transaction(() async {
      await database
          .into(database.publicAccounts)
          .insertOnConflictUpdate(
            PublicAccountsCompanion.insert(
              source: batch.profile.key.source.name,
              stableUserId: batch.profile.key.stableUserId,
              displayName: batch.profile.displayName,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.importBatchRecords)
          .insertOnConflictUpdate(
            ImportBatchRecordsCompanion.insert(
              batchId: batch.id,
              source: batch.profile.key.source.name,
              stableUserId: batch.profile.key.stableUserId,
              displayName: batch.profile.displayName,
              fingerprint: batch.fingerprint,
              createdAt: now,
              pagesFetched: batch.pagesFetched,
              declaredTotal: Value(batch.declaredTotal),
              itemCount: batch.itemCount,
              countsJson: Value(jsonEncode(_counts(batch.counts))),
              previousBatchId: Value(batch.previousBatchId),
              status: Value(batch.status.name),
            ),
          );
      await database
          .into(database.importSnapshotRecords)
          .insertOnConflictUpdate(
            ImportSnapshotRecordsCompanion.insert(
              batchId: batch.id,
              source: batch.profile.key.source.name,
              stableUserId: batch.profile.key.stableUserId,
              fingerprint: batch.fingerprint,
              itemsJson: Value(encodeImportItems(preview.snapshot.items)),
              createdAt: now,
            ),
          );
      for (final contribution in contributions) {
        await database
            .into(database.importContributionRecords)
            .insertOnConflictUpdate(
              ImportContributionRecordsCompanion.insert(
                batchId: batch.id,
                sourceId: contribution.sourceId,
                identityId: Value(contribution.identityId?.value),
                disposition: contribution.disposition.name,
                observedAt: contribution.observedAt
                    .toUtc()
                    .millisecondsSinceEpoch,
                reason: Value(contribution.reason),
              ),
            );
      }
    });
    return batch;
  }

  @override
  Future<UndoPreview> previewUndo(String batchId) =>
      _memory.previewUndo(batchId);

  @override
  Future<ImportBatch> undo(String batchId) async {
    final batch = await _memory.undo(batchId);
    await (database.update(
      database.importBatchRecords,
    )..where((row) => row.batchId.equals(batchId))).write(
      ImportBatchRecordsCompanion(
        status: const Value('undone'),
        undoneAt: Value(batch.undoneAt?.toUtc().millisecondsSinceEpoch),
      ),
    );
    return batch;
  }

  @override
  List<ImportBatch> history({PublicAccountKey? account}) =>
      _memory.history(account: account);

  @override
  ImportSnapshot? lastSuccessfulSnapshot(PublicAccountKey account) =>
      _memory.lastSuccessfulSnapshot(account);

  static Map<String, Object?> _counts(ImportPreviewCounts counts) =>
      <String, Object?>{
        'added': counts.added,
        'observationUpdated': counts.observationUpdated,
        'linked': counts.linked,
        'identityCandidates': counts.identityCandidates,
        'stateConflicts': counts.stateConflicts,
        'skipped': counts.skipped,
        'remoteMissing': counts.remoteMissing,
        'unchanged': counts.unchanged,
      };
}
