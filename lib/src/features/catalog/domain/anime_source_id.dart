final class AnimeSourceId {
  const AnimeSourceId._(this.rawId);

  final int rawId;

  String get value => 'bgm-$rawId';

  static AnimeSourceId? tryParse(String value) {
    final match = RegExp(r'^bgm-([1-9][0-9]*)$').firstMatch(value);
    if (match == null) return null;
    final rawId = int.tryParse(match.group(1)!);
    return rawId == null ? null : AnimeSourceId._(rawId);
  }

  static AnimeSourceId fromBangumiId(int rawId) {
    if (rawId <= 0) throw ArgumentError.value(rawId, 'rawId');
    return AnimeSourceId._(rawId);
  }

  @override
  bool operator ==(Object other) {
    return other is AnimeSourceId && other.rawId == rawId;
  }

  @override
  int get hashCode => rawId.hashCode;

  @override
  String toString() => value;
}
