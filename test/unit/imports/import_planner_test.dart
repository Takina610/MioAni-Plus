import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/imports/domain/import_planner.dart';
import 'package:mio_ani/src/features/imports/domain/import_staging.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

PublicCollectionItem _item(
  int id, {
  String title = '作品',
  LibraryWatchStatus status = LibraryWatchStatus.planned,
  int watched = 0,
}) => PublicCollectionItem(
  observation: SourceObservation(
    sourceId: AnimeSourceId.fromBangumiId(id),
    title: title,
    observedAt: DateTime.utc(2026, 8, 4),
    episodes: 12,
  ),
  status: status,
  watched: watched,
  totalEpisodes: 12,
);

ImportSnapshot _snapshot(List<PublicCollectionItem> items) => ImportSnapshot(
  sessionId: 'planner-session',
  profile: const PublicAccountProfile(
    key: PublicAccountKey(source: ImportSource.bangumi, stableUserId: '42'),
    displayName: '账号',
    inputAlias: 'renamed',
  ),
  items: items,
  pagesFetched: 1,
  declaredTotal: items.length,
  fingerprint: computeImportFingerprint(
    const PublicAccountKey(source: ImportSource.bangumi, stableUserId: '42'),
    items,
  ),
  status: ImportIntegrityStatus.complete,
  createdAt: DateTime.utc(2026, 8, 4),
);

LibraryRecord _record({
  LibraryWatchStatus status = LibraryWatchStatus.planned,
}) {
  final observation = _item(1).observation;
  final id = AnimeIdentityId.fromSources(<SourceAnimeId>[observation.sourceId]);
  return LibraryRecord(
    identity: AnimeIdentity(
      id: id,
      sources: <SourceObservation>[observation],
      canonicalTitle: observation.title,
    ),
    entry: LibraryEntry(
      identityId: id,
      status: status,
      watched: 0,
      totalEpisodes: 12,
      updatedAt: DateTime.utc(2026, 8, 1),
      localRevision: 1,
      modifiedLocally: true,
    ),
  );
}

void main() {
  test('规划区分新增、来源观察更新和状态冲突', () {
    final planner = const ImportPlanner();
    final preview = planner.plan(
      snapshot: _snapshot(<PublicCollectionItem>[
        _item(
          1,
          title: '更新后的作品',
          status: LibraryWatchStatus.completed,
          watched: 12,
        ),
        _item(2, title: '新作品'),
      ]),
      baseline: ImportPlanningBaseline(
        revision: 3,
        records: <LibraryRecord>[_record()],
      ),
    );
    expect(preview.counts.observationUpdated, 0);
    expect(preview.counts.stateConflicts, 1);
    expect(preview.counts.added, 1);
    expect(preview.canCommit, isFalse);
  });

  test('完整快照对比上一次成功批次才标记远端未出现', () {
    final old = _snapshot(<PublicCollectionItem>[_item(1), _item(2)]);
    final current = _snapshot(<PublicCollectionItem>[_item(1)]);
    final preview = const ImportPlanner().plan(
      snapshot: current,
      baseline: ImportPlanningBaseline(
        revision: 1,
        records: const <LibraryRecord>[],
        previousSnapshot: old,
      ),
    );
    expect(preview.counts.remoteMissing, 1);
    expect(
      preview.changes
          .singleWhere(
            (change) => change.kind == ImportChangeKind.remoteMissing,
          )
          .item
          .sourceId,
      'bgm-2',
    );
  });
}
