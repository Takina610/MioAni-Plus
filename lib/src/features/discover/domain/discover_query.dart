import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

enum DiscoverSourcePreference {
  auto,
  bangumi,
  anilist;

  String get queryValue => switch (this) {
    DiscoverSourcePreference.auto => 'auto',
    DiscoverSourcePreference.bangumi => 'bangumi',
    DiscoverSourcePreference.anilist => 'anilist',
  };

  static DiscoverSourcePreference? tryParse(String? value) {
    return switch (value?.toLowerCase()) {
      'auto' => DiscoverSourcePreference.auto,
      'bangumi' || 'bgm' => DiscoverSourcePreference.bangumi,
      'anilist' => DiscoverSourcePreference.anilist,
      _ => null,
    };
  }
}

enum DiscoverSort {
  relevance,
  popularity,
  score,
  rank,
  airDate;

  String get queryValue => switch (this) {
    DiscoverSort.relevance => 'relevance',
    DiscoverSort.popularity => 'popularity',
    DiscoverSort.score => 'score',
    DiscoverSort.rank => 'rank',
    DiscoverSort.airDate => 'air-date',
  };

  String get label => switch (this) {
    DiscoverSort.relevance => '匹配度',
    DiscoverSort.popularity => '热度',
    DiscoverSort.score => '评分',
    DiscoverSort.rank => '排名',
    DiscoverSort.airDate => '开播时间',
  };

  static DiscoverSort? tryParse(String? value) {
    return switch (value?.toLowerCase()) {
      'relevance' => DiscoverSort.relevance,
      'popularity' || 'hot' => DiscoverSort.popularity,
      'score' => DiscoverSort.score,
      'rank' => DiscoverSort.rank,
      'air-date' || 'airdate' => DiscoverSort.airDate,
      _ => null,
    };
  }
}

enum DiscoverFormat {
  all,
  tv,
  movie,
  ova,
  ona,
  special,
  music;

  String get queryValue => switch (this) {
    DiscoverFormat.all => 'all',
    DiscoverFormat.tv => 'tv',
    DiscoverFormat.movie => 'movie',
    DiscoverFormat.ova => 'ova',
    DiscoverFormat.ona => 'ona',
    DiscoverFormat.special => 'special',
    DiscoverFormat.music => 'music',
  };

  String get label => switch (this) {
    DiscoverFormat.all => '全部格式',
    DiscoverFormat.tv => 'TV',
    DiscoverFormat.movie => '剧场版',
    DiscoverFormat.ova => 'OVA',
    DiscoverFormat.ona => 'ONA',
    DiscoverFormat.special => '特别篇',
    DiscoverFormat.music => '音乐企划',
  };

  static DiscoverFormat? tryParse(String? value) {
    return switch (value?.toLowerCase()) {
      'all' => DiscoverFormat.all,
      'tv' => DiscoverFormat.tv,
      'movie' => DiscoverFormat.movie,
      'ova' => DiscoverFormat.ova,
      'ona' => DiscoverFormat.ona,
      'special' => DiscoverFormat.special,
      'music' => DiscoverFormat.music,
      _ => null,
    };
  }
}

enum DiscoverAirStatus {
  all,
  airing,
  finished,
  upcoming;

  String get queryValue => switch (this) {
    DiscoverAirStatus.all => 'all',
    DiscoverAirStatus.airing => 'airing',
    DiscoverAirStatus.finished => 'finished',
    DiscoverAirStatus.upcoming => 'upcoming',
  };

  String get label => switch (this) {
    DiscoverAirStatus.all => '全部状态',
    DiscoverAirStatus.airing => '放送中',
    DiscoverAirStatus.finished => '已完结',
    DiscoverAirStatus.upcoming => '未播出',
  };

  static DiscoverAirStatus? tryParse(String? value) {
    return switch (value?.toLowerCase()) {
      'all' => DiscoverAirStatus.all,
      'airing' || 'releasing' => DiscoverAirStatus.airing,
      'finished' || 'ended' => DiscoverAirStatus.finished,
      'upcoming' || 'not-yet-released' => DiscoverAirStatus.upcoming,
      _ => null,
    };
  }
}

enum DiscoverSeason {
  winter,
  spring,
  summer,
  fall;

  String get queryValue => name;

  String get label => switch (this) {
    DiscoverSeason.winter => '冬季',
    DiscoverSeason.spring => '春季',
    DiscoverSeason.summer => '夏季',
    DiscoverSeason.fall => '秋季',
  };

  static DiscoverSeason? tryParse(String? value) {
    return switch (value?.toLowerCase()) {
      'winter' => DiscoverSeason.winter,
      'spring' => DiscoverSeason.spring,
      'summer' => DiscoverSeason.summer,
      'fall' || 'autumn' => DiscoverSeason.fall,
      _ => null,
    };
  }
}

final class DiscoverQuery {
  const DiscoverQuery({
    this.keyword = '',
    this.genres = const <String>[],
    this.year,
    this.season,
    this.airStatus = DiscoverAirStatus.all,
    this.scoreMin,
    this.scoreMax,
    this.sort = DiscoverSort.relevance,
    this.format = DiscoverFormat.all,
    this.origin,
    this.sourcePreference = DiscoverSourcePreference.auto,
    this.pageSize = defaultPageSize,
  });

  static const int defaultPageSize = 24;
  static const int maximumPageSize = 48;

  final String keyword;
  final List<String> genres;
  final int? year;
  final DiscoverSeason? season;
  final DiscoverAirStatus airStatus;
  final double? scoreMin;
  final double? scoreMax;
  final DiscoverSort sort;
  final DiscoverFormat format;
  final String? origin;
  final DiscoverSourcePreference sourcePreference;
  final int pageSize;

  DiscoverQuery normalized() {
    final cleanedGenres =
        genres
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final min = _clampScore(scoreMin);
    final max = _clampScore(scoreMax);
    final normalizedMin = min == null || max == null
        ? min
        : min <= max
        ? min
        : max;
    final normalizedMax = min == null || max == null
        ? max
        : min <= max
        ? max
        : min;
    final normalizedKeyword = keyword.trim().replaceAll(RegExp(r'\s+'), ' ');
    return DiscoverQuery(
      keyword: normalizedKeyword.substring(
        0,
        normalizedKeyword.length.clamp(0, 120),
      ),
      genres: cleanedGenres,
      year: year != null && year! >= 1900 && year! <= 2100 ? year : null,
      season: season,
      airStatus: airStatus,
      scoreMin: normalizedMin,
      scoreMax: normalizedMax,
      sort: sort,
      format: format,
      origin: origin?.trim().isEmpty == true ? null : origin?.trim(),
      sourcePreference: sourcePreference,
      pageSize: pageSize.clamp(1, maximumPageSize),
    );
  }

  String get cacheKey {
    final value = normalized();
    return <String>[
      'discover:v1',
      value.sourcePreference.queryValue,
      Uri.encodeComponent(value.keyword),
      value.genres.map(Uri.encodeComponent).join(','),
      value.year?.toString() ?? '-',
      value.season?.queryValue ?? '-',
      value.airStatus.queryValue,
      value.scoreMin?.toStringAsFixed(1) ?? '-',
      value.scoreMax?.toStringAsFixed(1) ?? '-',
      value.sort.queryValue,
      value.format.queryValue,
      Uri.encodeComponent(value.origin ?? '-'),
      value.pageSize.toString(),
    ].join('|');
  }

  DiscoverQuery copyWith({
    String? keyword,
    List<String>? genres,
    int? year,
    bool clearYear = false,
    DiscoverSeason? season,
    bool clearSeason = false,
    DiscoverAirStatus? airStatus,
    double? scoreMin,
    bool clearScoreMin = false,
    double? scoreMax,
    bool clearScoreMax = false,
    DiscoverSort? sort,
    DiscoverFormat? format,
    String? origin,
    bool clearOrigin = false,
    DiscoverSourcePreference? sourcePreference,
    int? pageSize,
  }) {
    return DiscoverQuery(
      keyword: keyword ?? this.keyword,
      genres: genres ?? this.genres,
      year: clearYear ? null : year ?? this.year,
      season: clearSeason ? null : season ?? this.season,
      airStatus: airStatus ?? this.airStatus,
      scoreMin: clearScoreMin ? null : scoreMin ?? this.scoreMin,
      scoreMax: clearScoreMax ? null : scoreMax ?? this.scoreMax,
      sort: sort ?? this.sort,
      format: format ?? this.format,
      origin: clearOrigin ? null : origin ?? this.origin,
      sourcePreference: sourcePreference ?? this.sourcePreference,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiscoverQuery &&
        other.keyword == keyword &&
        _listEquals(other.genres, genres) &&
        other.year == year &&
        other.season == season &&
        other.airStatus == airStatus &&
        other.scoreMin == scoreMin &&
        other.scoreMax == scoreMax &&
        other.sort == sort &&
        other.format == format &&
        other.origin == origin &&
        other.sourcePreference == sourcePreference &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
    keyword,
    Object.hashAll(genres),
    year,
    season,
    airStatus,
    scoreMin,
    scoreMax,
    sort,
    format,
    origin,
    sourcePreference,
    pageSize,
  );

  static double? _clampScore(double? value) {
    if (value == null || !value.isFinite) return null;
    return value.clamp(0, 10).toDouble();
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

final class DiscoverPageRequest {
  const DiscoverPageRequest({
    required this.query,
    required this.page,
    required this.source,
  });

  final DiscoverQuery query;
  final int page;
  final AnimeSource source;
}

final class DiscoverPageResult {
  const DiscoverPageResult({
    required this.items,
    required this.page,
    required this.source,
    required this.hasMore,
    this.total,
    this.fetchedAt,
  });

  final List<AnimeSummary> items;
  final int page;
  final AnimeSource source;
  final bool hasMore;
  final int? total;
  final DateTime? fetchedAt;
}

final class DiscoverFilterCatalog {
  const DiscoverFilterCatalog({
    this.genres = const <String>[],
    this.origins = const <String>[],
    this.formats = const <DiscoverFormat>[],
    this.isFallback = false,
  });

  final List<String> genres;
  final List<String> origins;
  final List<DiscoverFormat> formats;
  final bool isFallback;
}

extension DiscoverSourceX on AnimeSource {
  String get label => switch (this) {
    AnimeSource.bangumi => 'Bangumi',
    AnimeSource.anilist => 'AniList',
  };
}
