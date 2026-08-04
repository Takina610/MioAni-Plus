import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/home_cache_codec.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

void main() {
  final codec = const HomeCacheCodec();

  test('round-trips hero/recommended/trending sections', () {
    final content = HomeCatalogContent(
      hero: <AnimeSummary>[_anime(1, '首推', score: 9.0)],
      recommended: <AnimeSummary>[
        _anime(1, '首推', score: 9.0),
        _anime(2, '次推', score: 8.0),
      ],
      trending: <AnimeSummary>[_anime(3, '热门', popularity: 100)],
    );

    final decoded = codec.decodeSections(codec.encodeSections(content));

    expect(decoded.hero.single.title, '首推');
    expect(decoded.hero.single.id, AnimeSourceId.fromBangumiId(1));
    expect(decoded.recommended, hasLength(2));
    expect(decoded.trending.single.popularity, 100);
  });

  test('rejects malformed section payloads', () {
    expect(
      () => codec.decodeSections(
        jsonEncode(<String, Object?>{
          'hero': <Object?>[
            <String, Object?>{'id': 'bad-id'},
          ],
          'recommended': <Object?>[],
          'trending': <Object?>[],
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => codec.decodeSections(
        jsonEncode(<String, Object?>{
          'hero': <Object?>[],
          'recommended': <Object?>[],
        }),
      ),
      throwsFormatException,
    );
  });
}

AnimeSummary _anime(int id, String title, {double? score, int? popularity}) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: title,
    sourceTitle: '',
    score: score,
    popularity: popularity,
  );
}
