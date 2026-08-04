import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/library/data/drift_library_repository.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';
import 'package:mio_ani/src/features/library/domain/library_query.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final repository = DriftLibraryRepository(ref.watch(catalogDatabaseProvider));
  ref.onDispose(repository.dispose);
  return repository;
});

final libraryStreamProvider = StreamProvider.autoDispose
    .family<List<LibraryRecord>, LibraryQuery>((ref, query) {
      return ref.watch(libraryRepositoryProvider).watchLibrary(query: query);
    });

final class LibraryControllerState {
  const LibraryControllerState({
    this.query = const LibraryQuery(),
    this.records = const <LibraryRecord>[],
    this.isSaving = false,
    this.error,
  });
  final LibraryQuery query;
  final List<LibraryRecord> records;
  final bool isSaving;
  final String? error;

  LibraryControllerState copyWith({
    LibraryQuery? query,
    List<LibraryRecord>? records,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) => LibraryControllerState(
    query: query ?? this.query,
    records: records ?? this.records,
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : (error ?? this.error),
  );
}

final class LibraryController extends Notifier<LibraryControllerState> {
  LibraryController(this._initialQuery);
  final LibraryQuery _initialQuery;

  @override
  LibraryControllerState build() {
    ref.listen<AsyncValue<List<LibraryRecord>>>(
      libraryStreamProvider(_initialQuery),
      (_, next) {
        next.whenData(
          (records) => state = state.copyWith(
            records: records,
            isSaving: false,
            clearError: true,
          ),
        );
      },
    );
    final async = ref.watch(libraryStreamProvider(_initialQuery));
    return LibraryControllerState(
      query: _initialQuery,
      records: async.value ?? const <LibraryRecord>[],
    );
  }

  void setQuery(LibraryQuery query) {
    state = state.copyWith(query: query.normalized(), clearError: true);
    ref.invalidate(libraryStreamProvider(state.query));
  }

  Future<void> addLocal(
    SourceObservation observation, {
    LibraryWatchStatus status = LibraryWatchStatus.planned,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await ref
          .read(libraryRepositoryProvider)
          .addLocal(observation, status: status);
    } catch (error) {
      state = state.copyWith(isSaving: false, error: _message(error));
    }
  }

  Future<void> remove(AnimeIdentityId identityId) =>
      _run(() => ref.read(libraryRepositoryProvider).remove(identityId));
  Future<void> setStatus(
    AnimeIdentityId identityId,
    LibraryWatchStatus status,
  ) => _run(
    () => ref.read(libraryRepositoryProvider).setStatus(identityId, status),
  );
  Future<void> setProgress(AnimeIdentityId identityId, int watched) => _run(
    () => ref.read(libraryRepositoryProvider).setProgress(identityId, watched),
  );

  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await action();
    } catch (error) {
      state = state.copyWith(isSaving: false, error: _message(error));
    }
  }

  static String _message(Object error) =>
      error is LibraryRepositoryException ? error.message : '保存失败，请稍后重试。';
}

final libraryControllerProvider = NotifierProvider.autoDispose
    .family<LibraryController, LibraryControllerState, LibraryQuery>(
      LibraryController.new,
    );
