import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_infobox.dart';

void main() {
  test('reads the facts a subject files under its own keys', () {
    final facts = BangumiSubjectFacts.fromInfobox(<Object?>[
      <String, Object?>{'key': '中文名', 'value': '初音岛 S.S.'},
      <String, Object?>{
        'key': '别名',
        'value': <Object?>[
          <String, Object?>{'v': 'D.C.S.S.'},
          <String, Object?>{'v': 'ダ・カーポ セカンドシーズン'},
        ],
      },
      <String, Object?>{'key': '单集时长', 'value': '24分钟'},
      <String, Object?>{'key': '原作', 'value': 'CIRCUS'},
      <String, Object?>{'key': '动画制作', 'value': 'feel.'},
    ]);

    // A value is either text or a list of `{v: ...}` objects depending on the
    // entry, and both are the same fact: the aliases are the value here, so a
    // reader that only understood strings would drop every entry that has more
    // than one.
    expect(facts.studio, 'feel.');
    expect(facts.sourceMaterial, 'CIRCUS');
    expect(facts.durationMinutes, 24);
  });

  test('reads the traditional spellings of the same keys', () {
    final facts = BangumiSubjectFacts.fromInfobox(<Object?>[
      <String, Object?>{'key': '動畫製作', 'value': '京都アニメーション'},
      <String, Object?>{'key': '播放時長', 'value': '23 分'},
    ]);

    // The source is written in by hand and the same fact comes through in
    // either script, so both spellings are the same key to this reader.
    expect(facts.studio, '京都アニメーション');
    expect(facts.durationMinutes, 23);
  });

  test('prefers the studio over the production line it was made for', () {
    final facts = BangumiSubjectFacts.fromInfobox(<Object?>[
      <String, Object?>{'key': '製作', 'value': '毎日放送、サンライズ'},
      <String, Object?>{'key': '动画制作', 'value': 'サンライズ'},
    ]);

    // `制作` is the committee a work was produced for and `动画制作` is who
    // drew it: the same subject carries both, and the fact worth showing is the
    // studio. The line stands in only when the studio is not named at all.
    expect(facts.studio, 'サンライズ');
  });

  test('a duration outside what an episode can run is left out', () {
    // Values under these keys are free text, and the number in them is not
    // always an episode length: a whole series' runtime filed under the same
    // key would be shown as one episode's and read as wrong.
    expect(_duration('600分钟'), isNull);
    expect(_duration('0'), isNull);
    expect(_duration('约'), isNull);
    expect(_duration('24:00'), 24);
    expect(_duration('146m'), 146);
  });

  test('an infobox with nothing to show produces nothing', () {
    expect(BangumiSubjectFacts.fromInfobox(null).studio, isNull);
    expect(BangumiSubjectFacts.fromInfobox('not an infobox').studio, isNull);
    expect(
      BangumiSubjectFacts.fromInfobox(<Object?>[
        <String, Object?>{'key': 'Copyright', 'value': '©SUNRISE'},
        <String, Object?>{'key': '导演', 'value': '谷口悟朗'},
        <String, Object?>{'key': '原作'},
        'not an entry',
      ]).sourceMaterial,
      isNull,
    );
  });
}

int? _duration(String value) {
  return BangumiSubjectFacts.fromInfobox(<Object?>[
    <String, Object?>{'key': '单集时长', 'value': value},
  ]).durationMinutes;
}
