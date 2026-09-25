/// What a Bangumi subject says about itself beside its summary.
///
/// The subject endpoint carries an `infobox` next to the rating and the covers:
/// one entry per credited thing — the studio, the staff, the songs, the
/// broadcasters, the copyright line — and it is the only place the source names
/// the studio that animated a work or the work it adapts. Which entries exist
/// differs from subject to subject, a value arrives either as text or as a list
/// of `{v: ...}` objects, and the wording flips between simplified and
/// traditional Chinese, so only the keys this app has a place for are read and
/// they are matched against every spelling the source uses.
final class BangumiSubjectFacts {
  const BangumiSubjectFacts({
    this.studio,
    this.sourceMaterial,
    this.durationMinutes,
  });

  /// No infobox, or one with nothing this app shows.
  static const BangumiSubjectFacts empty = BangumiSubjectFacts();

  /// Who animated it (`动画制作`), falling back to the production line
  /// (`制作`/`製作`) for subjects that do not separate the two.
  final String? studio;

  /// The work this anime adapts (`原作`), or where its story came from
  /// (`原案`).
  final String? sourceMaterial;

  /// Minutes per episode, when the source states one (`单集时长`).
  final int? durationMinutes;

  /// Reads [infobox] — the raw JSON value, which anything it does not
  /// recognise is dropped from rather than guessed at.
  factory BangumiSubjectFacts.fromInfobox(Object? infobox) {
    final entries = _entries(infobox);
    if (entries.isEmpty) return empty;
    return BangumiSubjectFacts(
      studio: _firstValue(entries, _studioKeys),
      sourceMaterial: _firstValue(entries, _sourceMaterialKeys),
      durationMinutes: _minutes(_firstValue(entries, _durationKeys)),
    );
  }

  /// Keys the source uses for the studio, in the order they are worth taking:
  /// the animation studio is what the subject actually credits, while `制作` is
  /// the committee it was produced for and only stands in when it is all there
  /// is.
  static const List<String> _studioKeys = <String>[
    '动画制作',
    '動畫製作',
    'アニメーション制作',
    '制作',
    '製作',
  ];

  static const List<String> _sourceMaterialKeys = <String>['原作', '原案'];

  static const List<String> _durationKeys = <String>[
    '单集时长',
    '單集時長',
    '单集片长',
    '播放时长',
    '播放時長',
  ];

  /// Every name the entry is filed under, with its values flattened.
  static List<_InfoboxEntry> _entries(Object? infobox) {
    if (infobox is! List<Object?>) return const <_InfoboxEntry>[];
    final entries = <_InfoboxEntry>[];
    for (final item in infobox) {
      if (item is! Map<Object?, Object?>) continue;
      final key = item['key'];
      if (key is! String || key.trim().isEmpty) continue;
      final values = _values(item['value']);
      if (values.isEmpty) continue;
      entries.add(_InfoboxEntry(key.trim(), values));
    }
    return entries;
  }

  static List<String> _values(Object? value) {
    final values = <String>[];
    void collect(Object? item) {
      switch (item) {
        case final String text:
          final trimmed = text.trim();
          if (trimmed.isNotEmpty) values.add(trimmed);
        case final List<Object?> items:
          items.forEach(collect);
        case final Map<Object?, Object?> map:
          collect(map['v']);
        default:
          break;
      }
    }

    collect(value);
    return values;
  }

  static String? _firstValue(List<_InfoboxEntry> entries, List<String> keys) {
    for (final key in keys) {
      for (final entry in entries) {
        if (entry.key == key) return entry.values.first;
      }
    }
    return null;
  }

  /// The episode length in [value], which the source writes as free text
  /// (`24分钟`, `24m`, `片长 24 分`). A number outside the range an episode can
  /// plausibly run is a different fact filed under the same key, so it is
  /// dropped rather than shown.
  static int? _minutes(String? value) {
    if (value == null) return null;
    final match = RegExp(r'\d+').firstMatch(value);
    final minutes = match == null ? null : int.tryParse(match.group(0)!);
    if (minutes == null || minutes <= 0 || minutes > _maximumEpisodeMinutes) {
      return null;
    }
    return minutes;
  }

  /// Longest an episode can be and still be one: anything above this is a
  /// runtime for the whole work, or a different number entirely.
  static const int _maximumEpisodeMinutes = 300;
}

final class _InfoboxEntry {
  const _InfoboxEntry(this.key, this.values);

  final String key;
  final List<String> values;
}
