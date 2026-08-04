import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';

typedef SourceAnimeId = AnimeSourceId;

enum LibraryWatchStatus { watching, completed, planned, paused, dropped }

enum IdentityEvidenceKind {
  sameSource,
  legacyLinkedIds,
  trustedMapping,
  userConfirmed,
  heuristicCandidate,
}

enum IdentityReviewStatus { pending, confirmed, ignored, split }

enum IdentityDecisionKind { confirm, keepSeparate, ignore, split, undo }

enum IdentityPlanKind { createIdentity, enrichIdentity, candidate }

enum LibraryOperationKind {
  add,
  remove,
  setStatus,
  setProgress,
  merge,
  split,
  decision,
  undo,
  clearPublicCache,
  clearFlutterUserData,
  deleteVueLegacyKeys,
}

final class AnimeIdentityId {
  const AnimeIdentityId._(this.value);
  final String value;

  factory AnimeIdentityId.fromSources(Iterable<SourceAnimeId> sourceIds) {
    final values = sourceIds.map((id) => id.value).toSet().toList()..sort();
    if (values.isEmpty) throw ArgumentError.value(sourceIds, 'sourceIds');
    final input = values.join('|');
    final hashes = <int>[
      _hash32(input, 0x811c9dc5, 0),
      _hash32(input, 0x9e3779b9, 0x9e),
      _hash32(input, 0x85ebca6b, 0x37),
      _hash32(input, 0xc2b2ae35, 0x71),
    ];
    final hex = hashes
        .map((value) => value.toRadixString(16).padLeft(8, '0'))
        .join();
    return AnimeIdentityId._('mioani-identity-v1:$hex');
  }

  static int _hash32(String input, int seed, int salt) {
    var hash = seed;
    for (final codeUnit in input.codeUnits) {
      hash = ((hash ^ (codeUnit + salt)) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static AnimeIdentityId? tryParse(String value) {
    final normalized = value.trim();
    return RegExp(r'^mioani-identity-v1:[0-9a-f]{32}$').hasMatch(normalized)
        ? AnimeIdentityId._(normalized)
        : null;
  }

  @override
  bool operator ==(Object other) =>
      other is AnimeIdentityId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class SourceObservation {
  const SourceObservation({
    required this.sourceId,
    required this.title,
    this.aliases = const <String>[],
    this.year,
    this.season,
    this.episodes,
    this.imageUrl,
    this.observedAt,
    this.provider,
    this.mappingVersion,
    this.mappingObservedAt,
  });

  final SourceAnimeId sourceId;
  final String title;
  final List<String> aliases;
  final int? year;
  final String? season;
  final int? episodes;
  final Uri? imageUrl;
  final DateTime? observedAt;
  final String? provider;
  final String? mappingVersion;
  final DateTime? mappingObservedAt;

  List<String> get searchableTitles => <String>{title, ...aliases}
      .map(_normalizeTitle)
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  bool get hasTrustedMapping =>
      provider != null &&
      provider!.trim().isNotEmpty &&
      mappingVersion != null &&
      mappingVersion!.trim().isNotEmpty &&
      mappingObservedAt != null;

  SourceObservation copyWith({
    SourceAnimeId? sourceId,
    String? title,
    List<String>? aliases,
    int? year,
    String? season,
    int? episodes,
    Uri? imageUrl,
    DateTime? observedAt,
    String? provider,
    String? mappingVersion,
    DateTime? mappingObservedAt,
  }) => SourceObservation(
    sourceId: sourceId ?? this.sourceId,
    title: title ?? this.title,
    aliases: aliases ?? this.aliases,
    year: year ?? this.year,
    season: season ?? this.season,
    episodes: episodes ?? this.episodes,
    imageUrl: imageUrl ?? this.imageUrl,
    observedAt: observedAt ?? this.observedAt,
    provider: provider ?? this.provider,
    mappingVersion: mappingVersion ?? this.mappingVersion,
    mappingObservedAt: mappingObservedAt ?? this.mappingObservedAt,
  );

  static String normalizeTitle(String value) => _normalizeTitle(value);

  static String _normalizeTitle(String value) => value.toLowerCase().replaceAll(
    RegExp(r'[^\p{L}\p{N}]', unicode: true),
    '',
  );
}

final class IdentityEvidence {
  const IdentityEvidence({
    required this.kind,
    required this.explanation,
    this.sourceIds = const <SourceAnimeId>[],
    this.provider,
    this.mappingVersion,
    this.observedAt,
    this.score,
  });

  final IdentityEvidenceKind kind;
  final String explanation;
  final List<SourceAnimeId> sourceIds;
  final String? provider;
  final String? mappingVersion;
  final DateTime? observedAt;
  final double? score;
}

final class AnimeIdentity {
  const AnimeIdentity({
    required this.id,
    required this.sources,
    required this.canonicalTitle,
    this.revision = 0,
  });

  final AnimeIdentityId id;
  final List<SourceObservation> sources;
  final String canonicalTitle;
  final int revision;

  List<SourceAnimeId> get sourceIds =>
      sources.map((item) => item.sourceId).toList(growable: false);

  AnimeIdentity copyWith({
    AnimeIdentityId? id,
    List<SourceObservation>? sources,
    String? canonicalTitle,
    int? revision,
  }) => AnimeIdentity(
    id: id ?? this.id,
    sources: sources ?? this.sources,
    canonicalTitle: canonicalTitle ?? this.canonicalTitle,
    revision: revision ?? this.revision,
  );
}

final class LibraryEntry {
  const LibraryEntry({
    required this.identityId,
    required this.status,
    required this.watched,
    required this.updatedAt,
    this.totalEpisodes,
    this.localRevision = 0,
    this.modifiedLocally = true,
  });

  final AnimeIdentityId identityId;
  final LibraryWatchStatus status;
  final int watched;
  final int? totalEpisodes;
  final DateTime updatedAt;
  final int localRevision;
  final bool modifiedLocally;

  LibraryEntry copyWith({
    AnimeIdentityId? identityId,
    LibraryWatchStatus? status,
    int? watched,
    int? totalEpisodes,
    DateTime? updatedAt,
    int? localRevision,
    bool? modifiedLocally,
  }) => LibraryEntry(
    identityId: identityId ?? this.identityId,
    status: status ?? this.status,
    watched: watched ?? this.watched,
    totalEpisodes: totalEpisodes ?? this.totalEpisodes,
    updatedAt: updatedAt ?? this.updatedAt,
    localRevision: localRevision ?? this.localRevision,
    modifiedLocally: modifiedLocally ?? this.modifiedLocally,
  );
}

final class IdentityCandidate {
  const IdentityCandidate({
    required this.id,
    required this.left,
    required this.right,
    required this.evidence,
    required this.status,
    required this.baselineRevision,
  });

  final String id;
  final SourceObservation left;
  final SourceObservation right;
  final IdentityEvidence evidence;
  final IdentityReviewStatus status;
  final int baselineRevision;

  String get suppressionKey {
    final ids = <String>[left.sourceId.value, right.sourceId.value]..sort();
    return ids.join('|');
  }
}

final class StateConflict {
  const StateConflict({
    required this.identityId,
    required this.current,
    required this.incoming,
    required this.explanation,
    required this.baselineRevision,
  });

  final AnimeIdentityId identityId;
  final LibraryEntry current;
  final LibraryEntry incoming;
  final String explanation;
  final int baselineRevision;
}

final class IdentityPlan {
  const IdentityPlan({
    required this.kind,
    required this.observation,
    required this.evidence,
    this.identityId,
    this.candidate,
  });

  final IdentityPlanKind kind;
  final SourceObservation observation;
  final IdentityEvidence evidence;
  final AnimeIdentityId? identityId;
  final IdentityCandidate? candidate;
}

final class LibraryStatePlan {
  const LibraryStatePlan({
    required this.result,
    this.conflict,
    this.completionSuggested = false,
    this.progressClamped = false,
  });

  final LibraryEntry result;
  final StateConflict? conflict;
  final bool completionSuggested;
  final bool progressClamped;
}

final class MergePreview {
  const MergePreview({
    required this.left,
    required this.right,
    required this.result,
    required this.evidence,
    required this.baselineRevision,
    this.leftEntry,
    this.rightEntry,
    this.conflict,
  });

  final AnimeIdentity left;
  final AnimeIdentity right;
  final AnimeIdentity result;
  final IdentityEvidence evidence;
  final int baselineRevision;
  final LibraryEntry? leftEntry;
  final LibraryEntry? rightEntry;
  final StateConflict? conflict;
}

final class SplitPreview {
  const SplitPreview({
    required this.identity,
    required this.results,
    required this.inheritStateTo,
    required this.baselineRevision,
  });

  final AnimeIdentity identity;
  final List<AnimeIdentity> results;
  final AnimeIdentityId inheritStateTo;
  final int baselineRevision;
}

final class IdentityDecision {
  const IdentityDecision({
    required this.id,
    required this.reviewId,
    required this.kind,
    required this.createdAt,
    this.explanation,
  });

  final String id;
  final String reviewId;
  final IdentityDecisionKind kind;
  final DateTime createdAt;
  final String? explanation;
}

final class LibraryOperation {
  const LibraryOperation({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.payload,
    this.undoneAt,
  });

  final String id;
  final LibraryOperationKind kind;
  final DateTime createdAt;
  final Map<String, Object?> payload;
  final DateTime? undoneAt;
}
