import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/home_cache_codec.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

void main() {
  final codec = const HomeCacheCodec();

  test('round-trips hero/trending sections', () {
    final content = HomeCatalogContent(
      hero: <AnimeSummary>[_anime(1, '首推', score: 9.0)],
      trending: <AnimeSummary>[_anime(3, '热门', popularity: 100)],
    );

    final decoded = codec.decodeSections(codec.encodeSections(content));

    expect(decoded.hero.single.title, '首推');
    expect(decoded.hero.single.id, AnimeSourceId.fromBangumiId(1));
    expect(decoded.trending.single.popularity, 100);
  });

  test('keeps the tile rendition a cached summary was read with', () {
    final summary = AnimeSummary(
      id: AnimeSourceId.fromBangumiId(9),
      title: '海报',
      sourceTitle: '',
      imageUrl: Uri.parse('https://lain.bgm.tv/pic/cover/l/aa/bb/9.jpg'),
      thumbnailUrl: Uri.parse('https://lain.bgm.tv/pic/cover/c/aa/bb/9.jpg'),
    );

    final decoded = codec.decodeSections(
      codec.encodeSections(
        HomeCatalogContent(
          hero: <AnimeSummary>[summary],
          trending: <AnimeSummary>[summary],
        ),
      ),
    );

    // A cache that dropped this would send every warm start back to the
    // full-size covers, which is most of what a slow grid is waiting for.
    expect(
      decoded.trending.single.thumbnailUrl,
      Uri.parse('https://lain.bgm.tv/pic/cover/c/aa/bb/9.jpg'),
    );
  });

  test('ignores the retired recommended rail in older caches', () {
    final decoded = codec.decodeSections(
      jsonEncode(<String, Object?>{
        'hero': <Object?>[
          <String, Object?>{'id': 'bgm-1', 'title': '首推'},
        ],
        'recommended': <Object?>[
          <String, Object?>{'id': 'bgm-1', 'title': '首推'},
          <String, Object?>{'id': 'bgm-2', 'title': '次推'},
        ],
        'trending': <Object?>[],
      }),
    );

    expect(decoded.hero.single.title, '首推');
    expect(decoded.trending, isEmpty);
  });

  test('rejects malformed section payloads', () {
    expect(
      () => codec.decodeSections(
        jsonEncode(<String, Object?>{
          'hero': <Object?>[
            <String, Object?>{'id': 'bad-id'},
          ],
          'trending': <Object?>[],
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => codec.decodeSections(
        jsonEncode(<String, Object?>{'hero': <Object?>[]}),
      ),
      throwsFormatException,
    );
  });

  test('round-trips the explore feed with the ranking it was read from', () {
    final page = HomeExplorePage(
      items: <AnimeSummary>[_anime(1, '甲')],
      page: 2,
      hasMore: true,
      source: AnimeSource.anilist,
    );

    final decoded = codec.decodeExplore(codec.encodeExplore(page));

    expect(decoded.page, 2);
    expect(decoded.hasMore, isTrue);
    expect(decoded.source, AnimeSource.anilist);
    expect(decoded.items.single.title, '甲');
  });

  test('rejects an explore record without a ranking it can be paged from', () {
    for (final source in <Object?>[null, 'kitsu']) {
      expect(
        () => codec.decodeExplore(
          jsonEncode(<String, Object?>{
            'page': 1,
            'hasMore': false,
            'source': source,
            'items': <Object?>[],
          }),
        ),
        throwsFormatException,
        reason: 'source $source',
      );
    }
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
