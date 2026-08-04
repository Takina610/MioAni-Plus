import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/imports/domain/import_staging.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

PublicAccountProfile _profile() => const PublicAccountProfile(
  key: PublicAccountKey(source: ImportSource.bangumi, stableUserId: '42'),
  displayName: '公开测试账号',
  inputAlias: 'old-alias',
);

PublicCollectionItem _item(int id, {int watched = 0}) => PublicCollectionItem(
  observation: SourceObservation(
    sourceId: AnimeSourceId.fromBangumiId(id),
    title: '作品$id',
  ),
  status: LibraryWatchStatus.planned,
  watched: watched,
);

void main() {
  test('分页按来源 ID 去重并在明确结束后生成稳定 fingerprint', () {
    final session = ImportStagingSession(
      sessionId: 'session-1',
      profile: _profile(),
    );
    session.addPage(
      CollectionPage(
        page: 1,
        items: <PublicCollectionItem>[_item(1), _item(2)],
        hasNextPage: true,
        declaredTotal: 2,
      ),
    );
    session.addPage(
      CollectionPage(
        page: 2,
        items: <PublicCollectionItem>[_item(2)],
        hasNextPage: false,
        declaredTotal: 2,
      ),
    );
    final snapshot = session.complete();
    expect(snapshot.isComplete, isTrue);
    expect(
      snapshot.items.map((item) => item.sourceId),
      containsAll(<String>['bgm-1', 'bgm-2']),
    );
    expect(snapshot.items, hasLength(2));
    expect(snapshot.fingerprint, hasLength(32));
  });

  test('缺页、数量不一致和取消不能完成快照', () {
    final missing = ImportStagingSession(
      sessionId: 'missing',
      profile: _profile(),
    );
    missing.addPage(
      CollectionPage(
        page: 1,
        items: <PublicCollectionItem>[_item(1)],
        hasNextPage: true,
      ),
    );
    expect(
      () => missing.addPage(
        CollectionPage(
          page: 3,
          items: const <PublicCollectionItem>[],
          hasNextPage: false,
        ),
      ),
      throwsA(isA<ImportIntegrityException>()),
    );

    final mismatch = ImportStagingSession(
      sessionId: 'mismatch',
      profile: _profile(),
    );
    mismatch.addPage(
      CollectionPage(
        page: 1,
        items: <PublicCollectionItem>[_item(1)],
        hasNextPage: false,
        declaredTotal: 2,
      ),
    );
    expect(() => mismatch.complete(), throwsA(isA<ImportIntegrityException>()));

    final cancelled = ImportStagingSession(
      sessionId: 'cancel',
      profile: _profile(),
    );
    cancelled.cancel();
    expect(
      () => cancelled.complete(),
      throwsA(isA<ImportIntegrityException>()),
    );
  });

  test('fingerprint 不包含输入用户名且字段顺序与分页顺序无关', () {
    final first = computeImportFingerprint(
      _profile().key,
      <PublicCollectionItem>[_item(1), _item(2)],
    );
    final renamed = computeImportFingerprint(
      _profile().key,
      <PublicCollectionItem>[_item(2), _item(1)],
    );
    expect(renamed, first);
  });
}
