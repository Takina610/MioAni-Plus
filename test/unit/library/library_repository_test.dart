import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/data/memory_library_repository.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

SourceObservation item(
  int id, {
  AnimeSource source = AnimeSource.bangumi,
  String title = '本地动画',
  int? episodes = 12,
}) => SourceObservation(
  sourceId: source == AnimeSource.bangumi
      ? AnimeSourceId.fromBangumiId(id)
      : AnimeSourceId.fromAniListId(id),
  title: title,
  episodes: episodes,
  observedAt: DateTime.utc(2026, 8, 4),
);

void main() {
  test(
    'offline repository supports five statuses and progress bounds',
    () async {
      final repository = MemoryLibraryRepository();
      final record = await repository.addLocal(item(1));
      for (final status in LibraryWatchStatus.values) {
        await repository.setStatus(record.entry.identityId, status);
        expect((await repository.readLibrary()).single.entry.status, status);
      }
      await repository.setProgress(record.entry.identityId, 12);
      expect((await repository.readLibrary()).single.entry.watched, 12);
      expect(
        () => repository.setProgress(record.entry.identityId, 13),
        throwsArgumentError,
      );
      expect(
        () => repository.setProgress(record.entry.identityId, -1),
        throwsArgumentError,
      );
    },
  );

  test('similar source remains independent and can be ignored', () async {
    final repository = MemoryLibraryRepository();
    final first = await repository.addLocal(item(2));
    expect(first.identity.sources, hasLength(1));
    expect(
      () => repository.addLocal(item(3, source: AnimeSource.anilist)),
      throwsA(isA<LibraryReviewRequired>()),
    );
    expect(repository.pendingCandidates, hasLength(1));
    final candidate = repository.pendingCandidates.single;
    expect((await repository.readLibrary()), hasLength(2));
    await repository.ignoreCandidate(candidate.id);
    expect(repository.pendingCandidates, isEmpty);
    expect(
      repository.planObservation(item(3, source: AnimeSource.anilist)).kind,
      isNot(IdentityPlanKind.candidate),
    );
  });

  test('baseline conflict prevents last-write-wins', () async {
    final repository = MemoryLibraryRepository();
    final record = await repository.addLocal(item(4));
    final baseline = repository.revision;
    await repository.setStatus(
      record.entry.identityId,
      LibraryWatchStatus.watching,
    );
    expect(
      () => repository.setProgress(
        record.entry.identityId,
        2,
        expectedRevision: baseline,
      ),
      throwsA(isA<LibraryRevisionConflict>()),
    );
  });

  test(
    'merge conflict requires explicit status and split preserves one entry',
    () async {
      final repository = MemoryLibraryRepository();
      final left = await repository.addLocal(item(5));
      final right = await repository.addLocal(
        item(6, source: AnimeSource.anilist, title: '另一个标题'),
      );
      await repository.setStatus(
        left.entry.identityId,
        LibraryWatchStatus.watching,
      );
      await repository.setStatus(
        right.entry.identityId,
        LibraryWatchStatus.paused,
      );
      expect(
        () => repository.commitMerge(
          left.entry.identityId,
          right.entry.identityId,
        ),
        throwsA(isA<LibraryStateConflictException>()),
      );
      final mergedId = await repository.commitMerge(
        left.entry.identityId,
        right.entry.identityId,
        resolvedStatus: LibraryWatchStatus.watching,
      );
      final merged = (await repository.readLibrary()).single;
      expect(merged.identity.id, mergedId);
      expect(merged.identity.sources, hasLength(2));
      final resultIds = await repository.commitSplit(
        mergedId,
        merged.identity.sources.first.sourceId ==
                merged.identity.sources.first.sourceId
            ? AnimeIdentityId.fromSources([
                merged.identity.sources.first.sourceId,
              ])
            : mergedId,
      );
      expect(resultIds, hasLength(2));
      expect((await repository.readLibrary()), hasLength(1));
    },
  );

  test('clear operations are independent', () async {
    final repository = MemoryLibraryRepository();
    await repository.addLocal(item(7));
    await repository.clearPublicCache();
    expect(repository.publicCacheCleared, isTrue);
    expect((await repository.readLibrary()), hasLength(1));
    await repository.clearFlutterUserData();
    expect((await repository.readLibrary()), isEmpty);
    expect(repository.publicCacheCleared, isTrue);
    expect(repository.vueLegacyKeysDeleted, isFalse);
  });
}
