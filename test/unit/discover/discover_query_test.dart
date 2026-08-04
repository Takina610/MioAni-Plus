import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query_codec.dart';

void main() {
  const codec = DiscoverQueryCodec();

  test('normalizes keyword, genres and score bounds deterministically', () {
    final value = DiscoverQuery(
      keyword: '  Frieren   Beyond  ',
      genres: <String>['Drama', ' drama ', 'Action'],
      scoreMin: 11,
      scoreMax: -1,
      year: 1899,
      pageSize: 100,
    ).normalized();

    expect(value.keyword, 'Frieren Beyond');
    expect(value.genres, <String>['Action', 'Drama', 'drama']);
    expect(value.scoreMin, 0);
    expect(value.scoreMax, 10);
    expect(value.year, isNull);
    expect(value.pageSize, DiscoverQuery.maximumPageSize);
  });

  test('round trips shareable query values and ignores unknown fields', () {
    final original = DiscoverQuery(
      keyword: '银河',
      genres: <String>['动作', '科幻'],
      year: 2026,
      season: DiscoverSeason.summer,
      airStatus: DiscoverAirStatus.airing,
      scoreMin: 7.5,
      scoreMax: 9,
      sort: DiscoverSort.score,
      format: DiscoverFormat.tv,
      origin: '日本',
      sourcePreference: DiscoverSourcePreference.anilist,
    );
    final uri = codec.apply(Uri.parse('/discover?temporary=hidden'), original);
    final parsed = codec.parse(uri);
    expect(parsed, original.normalized());
    expect(
      codec.normalizeUri(uri).queryParameters.containsKey('temporary'),
      isFalse,
    );
  });

  test('invalid enums and malformed score values fall back safely', () {
    final parsed = codec.parse(
      Uri.parse(
        '/discover?year=bad&season=??&score=abc&sort=unknown&source=wat',
      ),
    );
    expect(parsed.year, isNull);
    expect(parsed.season, isNull);
    expect(parsed.scoreMin, isNull);
    expect(parsed.scoreMax, isNull);
    expect(parsed.sort, DiscoverSort.relevance);
    expect(parsed.sourcePreference, DiscoverSourcePreference.auto);
  });

  test(
    'cache key excludes transient UI state and is stable for equivalent values',
    () {
      final a = DiscoverQuery(keyword: ' x ', genres: <String>['B', 'A']);
      final b = DiscoverQuery(keyword: 'x', genres: <String>['A', 'B']);
      expect(a.cacheKey, b.cacheKey);
      expect(a.cacheKey, isNot(contains('temporary')));
    },
  );
}
