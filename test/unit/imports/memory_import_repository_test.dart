import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/imports/data/memory_import_repository.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/imports/domain/import_staging.dart';
import 'package:mio_ani/src/features/library/data/memory_library_repository.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

PublicAccountProfile _profile(String id, {String alias = 'alias'}) =>
    PublicAccountProfile(
      key: PublicAccountKey(source: ImportSource.bangumi, stableUserId: id),
      displayName: '账号$id',
      inputAlias: alias,
    );

PublicCollectionItem _item(int id, String title) => PublicCollectionItem(
  observation: SourceObservation(
    sourceId: AnimeSourceId.fromBangumiId(id),
    title: title,
  ),
  status: LibraryWatchStatus.planned,
  watched: 0,
);

ImportSnapshot _snapshot(
  PublicAccountProfile profile,
  List<PublicCollectionItem> items,
) => ImportSnapshot(
  sessionId: 'session-${profile.key.stableUserId}-${items.length}',
  profile: profile,
  items: items,
  pagesFetched: 1,
  declaredTotal: items.length,
  fingerprint: computeImportFingerprint(profile.key, items),
  status: ImportIntegrityStatus.complete,
  createdAt: DateTime.utc(2026, 8, 4),
);

void main() {
  test('相同账号和 fingerprint 重复提交保持幂等', () async {
    final library = MemoryLibraryRepository();
    final repository = MemoryImportRepository(libraryRepository: library);
    final snapshot = _snapshot(_profile('42'), <PublicCollectionItem>[
      _item(1, '独立作品'),
    ]);
    final preview = await repository.preview(snapshot);
    final first = await repository.commit(preview);
    final second = await repository.commit(preview);
    expect(second.id, first.id);
    expect(repository.history(), hasLength(1));
    expect(await library.readLibrary(), hasLength(1));
    library.dispose();
  });

  test('同来源换稳定账号必须确认且不删除旧账号条目', () async {
    final library = MemoryLibraryRepository();
    final repository = MemoryImportRepository(libraryRepository: library);
    final firstPreview = await repository.preview(
      _snapshot(_profile('42'), <PublicCollectionItem>[_item(1, '作品一')]),
    );
    await repository.commit(firstPreview);
    final changedPreview = await repository.preview(
      _snapshot(_profile('99'), <PublicCollectionItem>[_item(2, '作品二')]),
    );
    expect(changedPreview.accountChangeRequiresConfirmation, isTrue);
    expect(
      () => repository.commit(changedPreview),
      throwsA(isA<ImportConfirmationRequiredException>()),
    );
    await repository.commit(changedPreview, confirmAccountChange: true);
    expect(await library.readLibrary(), hasLength(2));
    library.dispose();
  });

  test('空收藏是成功零条目批次，撤销只移除该批次新增贡献', () async {
    final library = MemoryLibraryRepository();
    final repository = MemoryImportRepository(libraryRepository: library);
    final nonEmpty = await repository.preview(
      _snapshot(_profile('42'), <PublicCollectionItem>[_item(1, '作品一')]),
    );
    final batch = await repository.commit(nonEmpty);
    final empty = await repository.preview(_snapshot(_profile('42'), const []));
    final emptyBatch = await repository.commit(empty);
    expect(emptyBatch.itemCount, 0);
    expect(emptyBatch.counts.remoteMissing, 1);
    final undo = await repository.previewUndo(batch.id);
    expect(undo.removable, hasLength(1));
    await repository.undo(batch.id);
    expect(await library.readLibrary(), isEmpty);
    expect(repository.history(), hasLength(2));
    library.dispose();
  });
}
