import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/imports/data/drift_import_repository.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/imports/domain/import_staging.dart';
import 'package:mio_ani/src/features/library/data/drift_library_repository.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

ImportSnapshot _snapshot() {
  const profile = PublicAccountProfile(
    key: PublicAccountKey(source: ImportSource.anilist, stableUserId: '7'),
    displayName: '公开账号',
    inputAlias: 'alias',
  );
  final item = PublicCollectionItem(
    observation: SourceObservation(
      sourceId: AnimeSourceId.fromAniListId(100),
      title: '无敏感测试作品',
    ),
    status: LibraryWatchStatus.planned,
    watched: 0,
  );
  return ImportSnapshot(
    sessionId: 'drift-session',
    profile: profile,
    items: <PublicCollectionItem>[item],
    pagesFetched: 1,
    declaredTotal: 1,
    fingerprint: computeImportFingerprint(profile.key, <PublicCollectionItem>[
      item,
    ]),
    status: ImportIntegrityStatus.complete,
    createdAt: DateTime.utc(2026, 8, 4),
  );
}

void main() {
  test('批次、贡献和快照在 Drift v4 中一起持久化', () async {
    final database = MioAniDatabase(NativeDatabase.memory());
    final library = DriftLibraryRepository(database);
    final repository = DriftImportRepository(
      database: database,
      libraryRepository: library,
    );
    final preview = await repository.preview(_snapshot());
    final batch = await repository.commit(preview);
    expect(
      (await database.select(database.importBatchRecords).get()),
      hasLength(1),
    );
    expect(
      (await database.select(database.importContributionRecords).get()),
      hasLength(1),
    );
    expect(
      (await database.select(database.importSnapshotRecords).get()),
      hasLength(1),
    );
    expect(batch.fingerprint, isNot(contains('alias')));
    await database.close();
    library.dispose();
  });
}
