import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/imports/data/anilist_import_source.dart';
import 'package:mio_ani/src/features/imports/data/bangumi_import_source.dart';
import 'package:mio_ani/src/features/imports/data/drift_import_repository.dart';
import 'package:mio_ani/src/features/imports/data/import_repository.dart';
import 'package:mio_ani/src/features/imports/data/import_service.dart';
import 'package:mio_ani/src/features/imports/data/import_source.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/imports/domain/import_staging.dart';
import 'package:mio_ani/src/features/library/application/library_providers.dart';

final importServiceProvider = Provider<ImportService>((ref) {
  final dio = ref.watch(dioProvider);
  final coordinator = ref.watch(requestCoordinatorProvider);
  return ImportService(<ImportSource, PublicCollectionSourceLike>{
    ImportSource.bangumi: BangumiImportSource(
      dio: dio,
      coordinator: coordinator,
    ),
    ImportSource.anilist: AniListImportSource(
      dio: dio,
      coordinator: coordinator,
    ),
  });
});

final importRepositoryProvider = Provider<ImportRepository>((ref) {
  final repository = DriftImportRepository(
    database: ref.watch(catalogDatabaseProvider),
    libraryRepository: ref.watch(libraryRepositoryProvider),
  );
  return repository;
});

final class ImportControllerState {
  const ImportControllerState({
    this.source = ImportSource.bangumi,
    this.input = '',
    this.stage = ImportStage.idle,
    this.profile,
    this.snapshot,
    this.preview,
    this.batch,
    this.history = const <ImportBatch>[],
    this.undoPreview,
    this.progress,
    this.error,
  });

  final ImportSource source;
  final String input;
  final ImportStage stage;
  final PublicAccountProfile? profile;
  final ImportSnapshot? snapshot;
  final ImportPreview? preview;
  final ImportBatch? batch;
  final List<ImportBatch> history;
  final UndoPreview? undoPreview;
  final ImportProgress? progress;
  final String? error;

  bool get isBusy => switch (stage) {
    ImportStage.resolving ||
    ImportStage.fetchingPages ||
    ImportStage.planning ||
    ImportStage.previewing ||
    ImportStage.committing => true,
    _ => false,
  };

  ImportControllerState copyWith({
    ImportSource? source,
    String? input,
    ImportStage? stage,
    PublicAccountProfile? profile,
    ImportSnapshot? snapshot,
    ImportPreview? preview,
    ImportBatch? batch,
    List<ImportBatch>? history,
    UndoPreview? undoPreview,
    ImportProgress? progress,
    String? error,
    bool clearData = false,
    bool clearError = false,
  }) => ImportControllerState(
    source: source ?? this.source,
    input: input ?? this.input,
    stage: stage ?? this.stage,
    profile: clearData ? profile : (profile ?? this.profile),
    snapshot: clearData ? snapshot : (snapshot ?? this.snapshot),
    preview: clearData ? preview : (preview ?? this.preview),
    batch: clearData ? batch : (batch ?? this.batch),
    history: history ?? this.history,
    undoPreview: clearData ? undoPreview : (undoPreview ?? this.undoPreview),
    progress: clearData ? progress : (progress ?? this.progress),
    error: clearError ? null : (error ?? this.error),
  );
}

final class ImportController extends Notifier<ImportControllerState> {
  ImportCancellationToken? _cancellation;

  @override
  ImportControllerState build() => const ImportControllerState();

  void setSource(ImportSource source) {
    if (state.isBusy) return;
    state = state.copyWith(
      source: source,
      clearData: true,
      stage: ImportStage.idle,
      clearError: true,
    );
  }

  void setInput(String input) => state = state.copyWith(input: input);

  Future<void> start() async {
    if (state.isBusy) return;
    final input = state.input.trim();
    if (input.isEmpty) {
      state = state.copyWith(stage: ImportStage.failed, error: '请输入公开用户名。');
      return;
    }
    final token = ImportCancellationToken();
    _cancellation = token;
    state = state.copyWith(
      stage: ImportStage.resolving,
      clearData: true,
      clearError: true,
    );
    try {
      final snapshot = await ref
          .read(importServiceProvider)
          .fetchSnapshot(
            source: state.source,
            input: input,
            cancellation: token,
            onProgress: (progress) {
              if (!ref.mounted) return;
              state = state.copyWith(stage: progress.stage, progress: progress);
            },
          );
      if (!ref.mounted) return;
      state = state.copyWith(
        stage: ImportStage.planning,
        profile: snapshot.profile,
        snapshot: snapshot,
        progress: ImportProgress(
          stage: ImportStage.planning,
          pagesFetched: snapshot.pagesFetched,
          itemsParsed: snapshot.items.length,
          declaredTotal: snapshot.declaredTotal,
          message: '正在与本地追番库比较',
        ),
      );
      final preview = await ref
          .read(importRepositoryProvider)
          .preview(snapshot);
      state = state.copyWith(stage: ImportStage.previewing, preview: preview);
    } on ImportCancelledException {
      state = state.copyWith(stage: ImportStage.cancelled, clearError: true);
    } on Object catch (error) {
      state = state.copyWith(stage: ImportStage.failed, error: _message(error));
    } finally {
      _cancellation = null;
    }
  }

  void cancel() {
    _cancellation?.cancel();
    if (state.isBusy) state = state.copyWith(stage: ImportStage.cancelled);
  }

  Future<void> commit({bool confirmAccountChange = false}) async {
    final preview = state.preview;
    if (preview == null) return;
    state = state.copyWith(stage: ImportStage.committing, clearError: true);
    try {
      final batch = await ref
          .read(importRepositoryProvider)
          .commit(preview, confirmAccountChange: confirmAccountChange);
      state = state.copyWith(
        stage: ImportStage.succeeded,
        batch: batch,
        history: ref.read(importRepositoryProvider).history(),
      );
    } on ImportPreviewStaleException catch (error) {
      state = state.copyWith(
        stage: ImportStage.previewStale,
        error: error.toString(),
      );
    } on Object catch (error) {
      state = state.copyWith(stage: ImportStage.failed, error: _message(error));
    }
  }

  Future<void> prepareUndo(String batchId) async {
    try {
      final preview = await ref
          .read(importRepositoryProvider)
          .previewUndo(batchId);
      state = state.copyWith(undoPreview: preview, clearError: true);
    } on Object catch (error) {
      state = state.copyWith(error: _message(error));
    }
  }

  Future<void> undo() async {
    final preview = state.undoPreview;
    if (preview == null) return;
    try {
      final batch = await ref
          .read(importRepositoryProvider)
          .undo(preview.batch.id);
      state = state.copyWith(
        batch: batch,
        undoPreview: null,
        stage: ImportStage.succeeded,
      );
    } on Object catch (error) {
      state = state.copyWith(error: _message(error));
    }
  }

  static String _message(Object error) {
    if (error is AppFailure) return error.userMessage;
    if (error is ImportIntegrityException) return error.message;
    if (error is ImportConfirmationRequiredException) return error.message;
    return '导入失败，请检查账号、网络和公开收藏后重试。';
  }
}

final importControllerProvider =
    NotifierProvider<ImportController, ImportControllerState>(
      ImportController.new,
    );

typedef PublicCollectionSourceLike = PublicCollectionSource;
