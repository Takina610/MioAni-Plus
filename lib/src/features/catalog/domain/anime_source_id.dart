/// Identifier for an anime as known by an upstream source, serialized as
/// `<source-prefix>-<positive integer>` (e.g. `bgm-2`, `anilist-12345`).
///
/// C4 schedule content merges Bangumi and AniList rows; the same string form
/// keeps cache records, routes and deep links stable across sources while
/// still rejecting unparseable input at the boundary.
enum AnimeSource { bangumi, anilist }

final class AnimeSourceId {
  const AnimeSourceId._(this.source, this.rawId);

  final AnimeSource source;
  final int rawId;

  /// Stable URL/cache prefix. `bgm-` is the established Bangumi form used by
  /// routes and existing cache records; `anilist-` mirrors the Vue reference.
  String get value => switch (source) {
    AnimeSource.bangumi => 'bgm-$rawId',
    AnimeSource.anilist => 'anilist-$rawId',
  };

  static AnimeSourceId? tryParse(String value) {
    final match = RegExp(r'^(bgm|anilist)-([1-9][0-9]*)$').firstMatch(value);
    if (match == null) return null;
    final rawId = int.tryParse(match.group(2)!);
    if (rawId == null) return null;
    final source = switch (match.group(1)) {
      'bgm' => AnimeSource.bangumi,
      'anilist' => AnimeSource.anilist,
      _ => null,
    };
    return source == null ? null : AnimeSourceId._(source, rawId);
  }

  static AnimeSourceId fromBangumiId(int rawId) {
    if (rawId <= 0) throw ArgumentError.value(rawId, 'rawId');
    return AnimeSourceId._(AnimeSource.bangumi, rawId);
  }

  static AnimeSourceId fromAniListId(int rawId) {
    if (rawId <= 0) throw ArgumentError.value(rawId, 'rawId');
    return AnimeSourceId._(AnimeSource.anilist, rawId);
  }

  @override
  bool operator ==(Object other) {
    return other is AnimeSourceId &&
        other.source == source &&
        other.rawId == rawId;
  }

  @override
  int get hashCode => Object.hash(source, rawId);

  @override
  String toString() => value;
}
