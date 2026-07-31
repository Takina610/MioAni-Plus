import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_dto.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_mapper.dart';

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
  });

  test('checked detail DTO tolerates unknown fields and cleans markup', () {
    final map =
        jsonDecode(File('test/fixtures/bangumi/detail.json').readAsStringSync())
            as Map<String, Object?>;
    map['future_field'] = 'ignored';

    final detail = mapBangumiDetail(BangumiSubjectDto.fromJson(map));

    expect(detail.title, '初音岛 S.S.');
    expect(detail.summary, '梦幻的初音岛上， 新的故事开始了。');
    expect(detail.episodes, 26);
    expect(detail.tags, containsAll(<String>['恋爱', '校园']));
  });

  test('checked DTO rejects missing identities and invalid roots', () {
    expect(
      () => BangumiSubjectDto.fromJson(const <String, Object?>{'name': 'x'}),
      throwsA(anything),
    );
    expect(
      () => BangumiCalendarResponse.fromJson(const <String, Object?>{}),
      throwsA(isA<FormatException>()),
    );
  });

  test('missing source titles remain empty instead of fabricating a title', () {
    final summary = mapBangumiSummary(
      BangumiSubjectDto.fromJson(const <String, Object?>{
        'id': 7,
        'name': '',
        'name_cn': '   ',
      }),
    );

    expect(summary.title, isEmpty);
    expect(summary.sourceTitle, isEmpty);
  });
}
