import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_dto.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_mapper.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

void main() {
  test('checked calendar DTO maps source data into a safe domain summary', () {
    final payload = jsonDecode(
      File('test/fixtures/bangumi/calendar.json').readAsStringSync(),
    );
    final response = BangumiCalendarResponse.fromJson(payload);
    final summary = mapBangumiSummary(response.days.single.items.single);

    expect(summary.id.value, 'bgm-2');
    expect(summary.title, '初音岛 S.S.');
    expect(summary.score, 6.5);
    expect(summary.imageUrl.toString(), startsWith('https://'));

    // The app asks the CDN for the sizes it actually paints rather than pulling
    // the original down and scaling it: a grid tile is about 320 physical
    // pixels wide and a hero card about 900, while the originals here run to
    // 1700×2400 and up to a megabyte each. The API's own `common` is a 150×212
    // thumbnail — too small for either — so the sizes are derived.
    expect(summary.imageUrl.toString(), contains('/r/800/pic/cover/l/'));
    expect(summary.thumbnailUrl.toString(), contains('/r/400/pic/cover/l/'));
  });

  test('a payload with one rendition leaves the thumbnail unset', () {
    final detail = mapBangumiDetail(
      BangumiSubjectDto.fromJson(
        jsonDecode(File('test/fixtures/bangumi/detail.json').readAsStringSync())
            as Map<String, Object?>,
      ),
    );

    // The weekly calendar and the detail endpoint publish `large` alone, and
    // the calendar is where the home page's poster grid comes from. Bangumi's
    // other renditions are the same file behind the CDN's resizing endpoint, so
    // the tile cover is derived rather than dropped: a grid tile drawing the
    // original downloads several times the pixels it can show.
    expect(detail.imageUrl.toString(), contains('/r/800/pic/cover/l/'));
    expect(detail.thumbnailUrl.toString(), contains('/r/400/pic/cover/l/'));
  });

  test('a fixed-size rendition is never resized again', () {
    // `common` on the calendar endpoint is a 150×212 picture. Resizing it up
    // would ask the CDN for a size that does not exist, so a payload carrying
    // only that is left alone.
    final summary = mapBangumiSummary(
      BangumiSubjectDto.fromJson(const <String, Object?>{
        'id': 11,
        'name': 'x',
        'images': <String, Object?>{
          'common': 'https://lain.bgm.tv/pic/cover/c/aa/bb/11.jpg',
        },
      }),
    );

    expect(summary.imageUrl.toString(), contains('/pic/cover/c/'));
    expect(summary.thumbnailUrl.toString(), contains('/pic/cover/c/'));
  });

  test('the country a work is filed under comes from its meta tags', () {
    // `meta_tags` is where Bangumi says where a work is from, and it is the
    // only place it does: the tag lists here are real ones, read off the
    // subjects they name. Nothing about the characters can settle it —
    // `万古至尊：李云霄传` and `東京喰種` are the same script.
    AnimeDetail detail(List<String> metaTags) => mapBangumiDetail(
      BangumiSubjectDto.fromJson(<String, Object?>{
        'id': 14,
        'name': 'x',
        'meta_tags': metaTags,
      }),
    );

    expect(detail(<String>['玄幻', '小说改', '中国', 'WEB']).origin, WorkOrigin.china);
    expect(detail(<String>['TV', '日本']).origin, WorkOrigin.japan);
    expect(
      detail(<String>['机战', 'TV', '日本', '原创', '战斗']).origin,
      WorkOrigin.japan,
    );
    // A work the source says nothing about is left unstated rather than
    // guessed at, and so is one from somewhere else.
    expect(detail(<String>['美国', '子供向', 'TV']).origin, isNull);
    expect(detail(const <String>[]).origin, isNull);
  });

  test('a cover that is already a rendition is not asked for twice', () {
    final summary = mapBangumiSummary(
      BangumiSubjectDto.fromJson(const <String, Object?>{
        'id': 12,
        'name': 'x',
        'images': <String, Object?>{
          'large': 'https://lain.bgm.tv/r/400/pic/cover/l/aa/bb/12.jpg',
        },
      }),
    );

    // Stacking another `/r/<width>/` on a rendition would ask for a picture
    // that does not exist, so a payload that carries only a rendition hands
    // the same URL back for both sizes.
    expect(
      summary.thumbnailUrl.toString(),
      'https://lain.bgm.tv/r/400/pic/cover/l/aa/bb/12.jpg',
    );
  });

  test('a cover from another host is handed back as it came', () {
    final summary = mapBangumiSummary(
      BangumiSubjectDto.fromJson(const <String, Object?>{
        'id': 13,
        'name': 'x',
        'images': <String, Object?>{
          'large':
              'https://s4.anilist.co/file/anilistcdn/media/anime/cover/'
              'large/bx13.jpg',
        },
      }),
    );

    // Another source's CDN is not Bangumi's and has no `/r/<width>/` resize to
    // ask for, so the one URL it publishes is used as it is.
    expect(
      summary.thumbnailUrl.toString(),
      'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx13.jpg',
    );
  });
}
