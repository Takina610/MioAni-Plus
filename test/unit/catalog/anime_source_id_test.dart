import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';

void main() {
  test('accepts canonical Bangumi and AniList anime identifiers', () {
    final bangumi = AnimeSourceId.tryParse('bgm-2');

    expect(bangumi, isNotNull);
    expect(bangumi!.rawId, 2);
    expect(bangumi.source, AnimeSource.bangumi);
    expect(bangumi.value, 'bgm-2');

    final anilist = AnimeSourceId.tryParse('anilist-12345');
    expect(anilist, isNotNull);
    expect(anilist!.source, AnimeSource.anilist);
    expect(anilist.rawId, 12345);
    expect(anilist.value, 'anilist-12345');
  });

  test('rejects malformed identifiers', () {
    for (final invalid in <String>[
      '2',
      'bgm-0',
      'bgm--1',
      'bgm-01',
      'anilist-0',
      'anilist-01',
      'bgm-abc',
      '',
      'mal-2',
    ]) {
      expect(AnimeSourceId.tryParse(invalid), isNull, reason: invalid);
    }
  });

  test('fromBangumiId and fromAniListId build valid ids', () {
    expect(AnimeSourceId.fromBangumiId(7).value, 'bgm-7');
    expect(AnimeSourceId.fromAniListId(7).value, 'anilist-7');
    expect(() => AnimeSourceId.fromBangumiId(0), throwsArgumentError);
    expect(() => AnimeSourceId.fromAniListId(0), throwsArgumentError);
  });

  test('equality and hashing include source and raw id', () {
    expect(AnimeSourceId.fromBangumiId(2), AnimeSourceId.fromBangumiId(2));
    expect(
      AnimeSourceId.fromBangumiId(2) == AnimeSourceId.fromAniListId(2),
      isFalse,
    );
    expect(
      AnimeSourceId.fromBangumiId(2).hashCode,
      AnimeSourceId.fromBangumiId(2).hashCode,
    );
  });
}
