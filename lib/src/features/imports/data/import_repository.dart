import 'package:mio_ani/src/features/imports/domain/import_models.dart';

abstract interface class ImportRepository {
  Future<ImportPreview> preview(ImportSnapshot snapshot);

  Future<ImportBatch> commit(
    ImportPreview preview, {
    bool confirmAccountChange = false,
  });

  Future<UndoPreview> previewUndo(String batchId);

  Future<ImportBatch> undo(String batchId);

  List<ImportBatch> history({PublicAccountKey? account});

  ImportSnapshot? lastSuccessfulSnapshot(PublicAccountKey account);
}
