import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/library/domain/identity_planner.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

SourceObservation observation(
  int id, {
  AnimeSource source = AnimeSource.bangumi,
  String title = '银河铁道',
  int? year = 2026,
  int? episodes = 12,
}) {
  final sourceId = source == AnimeSource.bangumi
      ? AnimeSourceId.fromBangumiId(id)
      : AnimeSourceId.fromAniListId(id);
  return SourceObservation(
    sourceId: sourceId,
    title: title,
    year: year,
    episodes: episodes,
    observedAt: DateTime.utc(2026, 8, 4),
  );
}

void main() {
  const planner = AnimeIdentityPlanner();
  test('same source id enriches existing identity without heuristic merge', () {
    final first = observation(1);
    final identity = AnimeIdentity(
      id: AnimeIdentityId.fromSources([first.sourceId]),
      sources: [first],
      canonicalTitle: first.title,
    );
    final plan = planner.planObservation(
      first.copyWith(title: '更新标题'),
      IdentityPlanningBaseline(identities: [identity]),
    );
    expect(plan.kind, IdentityPlanKind.enrichIdentity);
    expect(plan.evidence.kind, IdentityEvidenceKind.sameSource);
    expect(plan.identityId, identity.id);
  });

  test('title similarity creates a candidate and does not auto merge', () {
    final left = observation(1);
    final identity = AnimeIdentity(
      id: AnimeIdentityId.fromSources([left.sourceId]),
      sources: [left],
      canonicalTitle: left.title,
    );
    final incoming = observation(2, source: AnimeSource.anilist);
    final plan = planner.planObservation(
      incoming,
      IdentityPlanningBaseline(identities: [identity], revision: 4),
    );
    expect(plan.kind, IdentityPlanKind.candidate);
    expect(plan.candidate, isNotNull);
    expect(plan.candidate!.status, IdentityReviewStatus.pending);
    expect(plan.evidence.explanation, contains('仅供评审'));
  });

  test('different years remain explainable as remake candidate', () {
    final left = observation(3, year: 2010);
    final identity = AnimeIdentity(
      id: AnimeIdentityId.fromSources([left.sourceId]),
      sources: [left],
      canonicalTitle: left.title,
    );
    final incoming = observation(4, source: AnimeSource.anilist, year: 2026);
    final plan = planner.planObservation(
      incoming,
      IdentityPlanningBaseline(identities: [identity]),
    );
    expect(plan.kind, IdentityPlanKind.candidate);
    expect(plan.evidence.explanation, contains('重制或续作'));
  });

  test('ignored pair is suppressed on the next heuristic pass', () {
    final left = observation(5);
    final identity = AnimeIdentity(
      id: AnimeIdentityId.fromSources([left.sourceId]),
      sources: [left],
      canonicalTitle: left.title,
    );
    final right = observation(6, source: AnimeSource.anilist);
    final ids = [left.sourceId.value, right.sourceId.value]..sort();
    final plan = planner.planObservation(
      right,
      IdentityPlanningBaseline(
        identities: [identity],
        suppressedPairs: {ids.join('|')},
      ),
    );
    expect(plan.kind, IdentityPlanKind.createIdentity);
  });

  test('local state wins while progress never decreases', () {
    final id = AnimeIdentityId.fromSources([observation(7).sourceId]);
    final current = LibraryEntry(
      identityId: id,
      status: LibraryWatchStatus.paused,
      watched: 8,
      totalEpisodes: 12,
      updatedAt: DateTime.utc(2026, 8, 4),
      localRevision: 3,
      modifiedLocally: true,
    );
    final incoming = LibraryEntry(
      identityId: id,
      status: LibraryWatchStatus.completed,
      watched: 4,
      totalEpisodes: 12,
      updatedAt: DateTime.utc(2026, 8, 5),
      localRevision: 0,
      modifiedLocally: false,
    );
    final plan = planner.planStateChange(
      current: current,
      incoming: incoming,
      baselineRevision: 7,
    );
    expect(plan.result.status, LibraryWatchStatus.paused);
    expect(plan.result.watched, 8);
    expect(plan.conflict, isNotNull);
  });

  test('merge and split enforce baseline and explicit inheritance', () {
    final leftSource = observation(8);
    final rightSource = observation(9, source: AnimeSource.anilist);
    final left = AnimeIdentity(
      id: AnimeIdentityId.fromSources([leftSource.sourceId]),
      sources: [leftSource],
      canonicalTitle: leftSource.title,
      revision: 1,
    );
    final right = AnimeIdentity(
      id: AnimeIdentityId.fromSources([rightSource.sourceId]),
      sources: [rightSource],
      canonicalTitle: rightSource.title,
      revision: 1,
    );
    expect(
      () => planner.previewMerge(
        left: left,
        right: right,
        baselineRevision: 3,
        expectedRevision: 2,
      ),
      throwsA(isA<BaselineChangedException>()),
    );
    final merge = planner.previewMerge(
      left: left,
      right: right,
      baselineRevision: 3,
    );
    expect(merge.result.sources, hasLength(2));
    final split = planner.previewSplit(
      identity: merge.result,
      inheritStateTo: merge.result.id,
      baselineRevision: 4,
    );
    expect(split.results, hasLength(2));
    expect(split.inheritStateTo, split.results.first.id);
  });
}
