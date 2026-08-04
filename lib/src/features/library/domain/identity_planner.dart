import 'package:mio_ani/src/features/library/domain/library_models.dart';

final class BaselineChangedException implements Exception {
  const BaselineChangedException({
    required this.expected,
    required this.actual,
  });
  final int expected;
  final int actual;
  @override
  String toString() => 'Baseline changed: expected $expected, actual $actual';
}

final class IdentityPlanningBaseline {
  const IdentityPlanningBaseline({
    this.revision = 0,
    this.identities = const <AnimeIdentity>[],
    this.sourceIdentityIds = const <String, AnimeIdentityId>{},
    this.legacyLinkedIdentityIds = const <String, AnimeIdentityId>{},
    this.trustedMappingIdentityIds = const <String, AnimeIdentityId>{},
    this.confirmedIdentityIds = const <String, AnimeIdentityId>{},
    this.sourceToIdentity = const <String, AnimeIdentityId>{},
    this.legacyLinks = const <String, AnimeIdentityId>{},
    this.trustedMappings = const <String, AnimeIdentityId>{},
    this.userConfirmed = const <String, AnimeIdentityId>{},
    this.suppressedPairs = const <String>{},
    this.libraryEntries = const <AnimeIdentityId, LibraryEntry>{},
  });
  final int revision;
  final List<AnimeIdentity> identities;
  final Map<String, AnimeIdentityId> sourceIdentityIds;
  final Map<String, AnimeIdentityId> legacyLinkedIdentityIds;
  final Map<String, AnimeIdentityId> trustedMappingIdentityIds;
  final Map<String, AnimeIdentityId> confirmedIdentityIds;
  final Map<String, AnimeIdentityId> sourceToIdentity;
  final Map<String, AnimeIdentityId> legacyLinks;
  final Map<String, AnimeIdentityId> trustedMappings;
  final Map<String, AnimeIdentityId> userConfirmed;
  final Set<String> suppressedPairs;
  final Map<AnimeIdentityId, LibraryEntry> libraryEntries;

  AnimeIdentity? identityFor(AnimeIdentityId id) {
    for (final identity in identities) {
      if (identity.id == id) return identity;
    }
    return null;
  }

  AnimeIdentityId? exactIdentityFor(SourceAnimeId sourceId) {
    final mapped =
        sourceIdentityIds[sourceId.value] ?? sourceToIdentity[sourceId.value];
    if (mapped != null) return mapped;
    for (final identity in identities) {
      if (identity.sourceIds.contains(sourceId)) return identity.id;
    }
    return null;
  }

  bool isSuppressed(SourceAnimeId left, SourceAnimeId right) {
    final ids = <String>[left.value, right.value]..sort();
    return suppressedPairs.contains(ids.join('|'));
  }
}

final class AnimeIdentityPlanner {
  const AnimeIdentityPlanner();

  IdentityPlan planObservation(
    SourceObservation observation,
    IdentityPlanningBaseline baseline,
  ) {
    final exact = baseline.exactIdentityFor(observation.sourceId);
    if (exact != null) {
      return IdentityPlan(
        kind: IdentityPlanKind.enrichIdentity,
        observation: observation,
        identityId: exact,
        evidence: IdentityEvidence(
          kind: IdentityEvidenceKind.sameSource,
          sourceIds: <SourceAnimeId>[observation.sourceId],
          explanation: '同一来源实体 ID 已存在，更新展示观察而不改变作品身份。',
        ),
      );
    }
    final legacy =
        baseline.legacyLinkedIdentityIds[observation.sourceId.value] ??
        baseline.legacyLinks[observation.sourceId.value];
    if (legacy != null) {
      return IdentityPlan(
        kind: IdentityPlanKind.enrichIdentity,
        observation: observation,
        identityId: legacy,
        evidence: IdentityEvidence(
          kind: IdentityEvidenceKind.legacyLinkedIds,
          sourceIds: <SourceAnimeId>[observation.sourceId],
          explanation: 'C3 legacy_linked_ids 明确声明了来源关联。',
        ),
      );
    }
    final trusted =
        baseline.trustedMappingIdentityIds[observation.sourceId.value];
    if (trusted != null && observation.hasTrustedMapping) {
      return IdentityPlan(
        kind: IdentityPlanKind.enrichIdentity,
        observation: observation,
        identityId: trusted,
        evidence: IdentityEvidence(
          kind: IdentityEvidenceKind.trustedMapping,
          sourceIds: <SourceAnimeId>[observation.sourceId],
          provider: observation.provider,
          mappingVersion: observation.mappingVersion,
          observedAt: observation.mappingObservedAt,
          explanation: '提供者、映射版本和观察时间完整，使用可信映射关联。',
        ),
      );
    }
    final confirmed =
        baseline.confirmedIdentityIds[observation.sourceId.value] ??
        baseline.userConfirmed[observation.sourceId.value];
    if (confirmed != null) {
      return IdentityPlan(
        kind: IdentityPlanKind.enrichIdentity,
        observation: observation,
        identityId: confirmed,
        evidence: IdentityEvidence(
          kind: IdentityEvidenceKind.userConfirmed,
          sourceIds: <SourceAnimeId>[observation.sourceId],
          explanation: '用户已确认该来源属于现有作品身份。',
        ),
      );
    }
    final candidate = _findCandidate(observation, baseline);
    if (candidate != null) {
      return IdentityPlan(
        kind: IdentityPlanKind.candidate,
        observation: observation,
        candidate: candidate,
        evidence: candidate.evidence,
      );
    }
    final identityId = AnimeIdentityId.fromSources(<SourceAnimeId>[
      observation.sourceId,
    ]);
    return IdentityPlan(
      kind: IdentityPlanKind.createIdentity,
      observation: observation,
      identityId: identityId,
      evidence: IdentityEvidence(
        kind: IdentityEvidenceKind.sameSource,
        sourceIds: <SourceAnimeId>[observation.sourceId],
        explanation: '没有确定关联证据，创建仅包含该来源实体的新身份。',
      ),
    );
  }

  IdentityPlan plan(
    SourceObservation observation,
    IdentityPlanningBaseline baseline,
  ) => planObservation(observation, baseline);

  IdentityCandidate? _findCandidate(
    SourceObservation observation,
    IdentityPlanningBaseline baseline,
  ) {
    final incomingTitles = observation.searchableTitles.toSet();
    IdentityCandidate? best;
    var bestScore = 0.0;
    for (final identity in baseline.identities) {
      for (final source in identity.sources) {
        if (source.sourceId == observation.sourceId ||
            baseline.isSuppressed(source.sourceId, observation.sourceId)) {
          continue;
        }
        final score = _similarity(observation, source, incomingTitles);
        if (score < 0.55 || score < bestScore) continue;
        bestScore = score;
        final ids = <String>[source.sourceId.value, observation.sourceId.value]
          ..sort();
        best = IdentityCandidate(
          id: 'candidate:${ids.join('|')}',
          left: source,
          right: observation,
          evidence: IdentityEvidence(
            kind: IdentityEvidenceKind.heuristicCandidate,
            sourceIds: <SourceAnimeId>[source.sourceId, observation.sourceId],
            score: score,
            explanation: _candidateExplanation(observation, source, score),
          ),
          status: IdentityReviewStatus.pending,
          baselineRevision: baseline.revision,
        );
      }
    }
    return best;
  }

  double _similarity(
    SourceObservation incoming,
    SourceObservation existing,
    Set<String> incomingTitles,
  ) {
    final existingTitles = existing.searchableTitles.toSet();
    final sameTitle = incomingTitles.intersection(existingTitles).isNotEmpty;
    if (!sameTitle) return 0;
    var score = 0.60;
    if (incoming.year != null && existing.year != null) {
      final distance = (incoming.year! - existing.year!).abs();
      score += distance == 0 ? 0.22 : (distance <= 1 ? 0.08 : 0.0);
    }
    if (incoming.episodes != null && existing.episodes != null) {
      final distance = (incoming.episodes! - existing.episodes!).abs();
      score += distance == 0 ? 0.12 : (distance <= 2 ? 0.04 : 0.0);
    }
    return score.clamp(0.0, 0.99);
  }

  String _candidateExplanation(
    SourceObservation incoming,
    SourceObservation existing,
    double score,
  ) {
    final reasons = <String>['标题或别名相似'];
    if (incoming.year != null && existing.year != null) {
      reasons.add(incoming.year == existing.year ? '年份一致' : '年份不同，可能是重制或续作');
    } else {
      reasons.add('缺少完整年份证据');
    }
    if (incoming.episodes != null && existing.episodes != null) {
      reasons.add(incoming.episodes == existing.episodes ? '集数一致' : '集数不同');
    } else {
      reasons.add('缺少完整集数证据');
    }
    return '候选相似度 ${(score * 100).round()}%：${reasons.join('、')}。仅供评审，不自动合并。';
  }

  LibraryStatePlan planStateChange({
    required LibraryEntry current,
    required LibraryEntry incoming,
    required int baselineRevision,
  }) {
    _validateEntry(current);
    _validateEntry(incoming);
    final totalEpisodes = _mergeTotalEpisodes(
      current.totalEpisodes,
      incoming.totalEpisodes,
    );
    final watched = current.watched > incoming.watched
        ? current.watched
        : incoming.watched;
    final currentWins =
        current.modifiedLocally ||
        current.localRevision > incoming.localRevision;
    final status = currentWins ? current.status : incoming.status;
    final conflict = current.status != incoming.status
        ? StateConflict(
            identityId: current.identityId,
            current: current,
            incoming: incoming,
            explanation: '两个来源给出了不同状态，未按枚举���序或导入顺序静默决胜。',
            baselineRevision: baselineRevision,
          )
        : null;
    final result = current.copyWith(
      status: status,
      watched: watched,
      totalEpisodes: totalEpisodes,
      updatedAt: _latest(current.updatedAt, incoming.updatedAt),
      localRevision: current.localRevision > incoming.localRevision
          ? current.localRevision
          : incoming.localRevision,
      modifiedLocally: currentWins,
    );
    return LibraryStatePlan(
      result: result,
      conflict: conflict,
      completionSuggested:
          totalEpisodes != null &&
          watched >= totalEpisodes &&
          status != LibraryWatchStatus.completed,
    );
  }

  LibraryStatePlan planLibraryState({
    required LibraryEntry current,
    required LibraryEntry incoming,
    required int baselineRevision,
  }) => planStateChange(
    current: current,
    incoming: incoming,
    baselineRevision: baselineRevision,
  );

  MergePreview previewMerge({
    required AnimeIdentity left,
    required AnimeIdentity right,
    required int baselineRevision,
    LibraryEntry? leftEntry,
    LibraryEntry? rightEntry,
    int? expectedRevision,
  }) {
    if (expectedRevision != null && expectedRevision != baselineRevision) {
      throw BaselineChangedException(
        expected: expectedRevision,
        actual: baselineRevision,
      );
    }
    final mergedSources = <SourceObservation>[...left.sources];
    for (final source in right.sources) {
      if (!mergedSources.any((item) => item.sourceId == source.sourceId)) {
        mergedSources.add(source);
      }
    }
    final result = AnimeIdentity(
      id: AnimeIdentityId.fromSources(
        mergedSources.map((item) => item.sourceId),
      ),
      sources: List<SourceObservation>.unmodifiable(mergedSources),
      canonicalTitle: _canonicalTitle(left, right),
      revision: baselineRevision + 1,
    );
    StateConflict? conflict;
    if (leftEntry != null && rightEntry != null) {
      conflict = planStateChange(
        current: leftEntry,
        incoming: rightEntry,
        baselineRevision: baselineRevision,
      ).conflict;
    }
    return MergePreview(
      left: left,
      right: right,
      result: result,
      evidence: const IdentityEvidence(
        kind: IdentityEvidenceKind.userConfirmed,
        explanation: '用户请求手动合并；合并结果须在同一事务中提交。',
      ),
      baselineRevision: baselineRevision,
      leftEntry: leftEntry,
      rightEntry: rightEntry,
      conflict: conflict,
    );
  }

  MergePreview planMerge({
    required AnimeIdentity left,
    required AnimeIdentity right,
    required int baselineRevision,
    LibraryEntry? leftEntry,
    LibraryEntry? rightEntry,
    int? expectedRevision,
  }) => previewMerge(
    left: left,
    right: right,
    baselineRevision: baselineRevision,
    leftEntry: leftEntry,
    rightEntry: rightEntry,
    expectedRevision: expectedRevision,
  );

  SplitPreview previewSplit({
    required AnimeIdentity identity,
    required AnimeIdentityId inheritStateTo,
    required int baselineRevision,
    int? expectedRevision,
  }) {
    if (expectedRevision != null && expectedRevision != baselineRevision) {
      throw BaselineChangedException(
        expected: expectedRevision,
        actual: baselineRevision,
      );
    }
    final results = identity.sources
        .map(
          (source) => AnimeIdentity(
            id: AnimeIdentityId.fromSources(<SourceAnimeId>[source.sourceId]),
            sources: <SourceObservation>[source],
            canonicalTitle: source.title,
            revision: baselineRevision + 1,
          ),
        )
        .toList(growable: false);
    final resolvedInherit = inheritStateTo == identity.id
        ? results.first.id
        : results.firstWhere((item) => item.id == inheritStateTo).id;
    return SplitPreview(
      identity: identity,
      results: results,
      inheritStateTo: resolvedInherit,
      baselineRevision: baselineRevision,
    );
  }

  SplitPreview planSplit({
    required AnimeIdentity identity,
    required AnimeIdentityId inheritStateTo,
    required int baselineRevision,
    int? expectedRevision,
  }) => previewSplit(
    identity: identity,
    inheritStateTo: inheritStateTo,
    baselineRevision: baselineRevision,
    expectedRevision: expectedRevision,
  );

  IdentityDecision decision({
    required String reviewId,
    required IdentityDecisionKind kind,
    String? explanation,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now().toUtc());
    return IdentityDecision(
      id: 'decision:$reviewId:${timestamp.microsecondsSinceEpoch}',
      reviewId: reviewId,
      kind: kind,
      createdAt: timestamp,
      explanation: explanation,
    );
  }

  static int? _mergeTotalEpisodes(int? left, int? right) {
    if (left == null) return right;
    if (right == null) return left;
    return left > right ? left : right;
  }

  static DateTime _latest(DateTime left, DateTime right) =>
      left.isAfter(right) ? left : right;
  static String _canonicalTitle(AnimeIdentity left, AnimeIdentity right) =>
      left.canonicalTitle.trim().isNotEmpty
      ? left.canonicalTitle
      : right.canonicalTitle;
  static void _validateEntry(LibraryEntry entry) {
    if (entry.watched < 0) {
      throw ArgumentError.value(
        entry.watched,
        'watched',
        'must be non-negative',
      );
    }
    if (entry.totalEpisodes != null && entry.totalEpisodes! < 0) {
      throw ArgumentError.value(
        entry.totalEpisodes,
        'totalEpisodes',
        'must be non-negative',
      );
    }
    if (entry.totalEpisodes != null && entry.watched > entry.totalEpisodes!) {
      throw ArgumentError.value(
        entry.watched,
        'watched',
        'cannot exceed known total episodes',
      );
    }
  }
}
