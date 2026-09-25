import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/translation/domain/translation_candidate.dart';

/// The titles, synopses and tags in this file are real ones, taken from the
/// source on 2026-09-24 along with the country it files each work under. That is
/// the point of it: the rule exists to be right about what this app is actually
/// handed, and a rule tested only on invented strings is a rule tested on
/// nothing.
void main() {
  group('a Chinese text is never offered', () {
    // Every one of these is a Chinese work's own title, and every one is
    // written in characters Japanese also uses. Nothing about them says
    // Chinese except the source's filing, which is exactly why it is consulted.
    test('even when it is written in characters Japanese shares', () {
      for (final title in <String>[
        '李熊猫',
        '万古至尊：李云霄传',
        '一斩苍穹',
        '百日成王',
        '太古神尊',
        '择日飞升',
        '东大高武学院',
        '茶啊二中第六季',
        '喜羊羊与灰太狼之破界山海诀',
      ]) {
        expect(
          workTextReadsForeign(title, origin: WorkOrigin.china),
          isFalse,
          reason: title,
        );
      }
    });

    test('a Chinese synopsis, however long', () {
      expect(
        workTextReadsForeign(
          '在一个人类与兽人共存的世界里，住着一只整天抽着烟、过着懒散生活的兽人。'
          '没钱！没生活能力！简直是个废物！礼仪和道德早就跟烟蒂一起被丢进垃圾桶了。',
          origin: WorkOrigin.china,
        ),
        isFalse,
      );
    });

    test('a tag row, whatever names are on it', () {
      // These are the rows this app actually produces — the source orders its
      // tags by how many readers filed a work under them, so the six it takes
      // are the genre words, and over sixty subjects every one of those rows
      // scored zero kana. The Chinese is what gets read and there is nothing
      // here to translate.
      expect(workTextReadsForeign('漫画改 · TV · 运动 · CUE'), isFalse);
      expect(workTextReadsForeign('WEB · 美国'), isFalse);
      expect(workTextReadsForeign('美国 · 子供向 · TV'), isFalse);
      expect(
        workTextReadsForeign('搞笑 · 漫画改 · 2026年7月 · 日常 · 喜剧 · TV'),
        isFalse,
      );
      expect(workTextReadsForeign('中国 · WEB · 玄幻 · 小说改 · 3D'), isFalse);
    });

    test('but a row that is a third a name nobody can read is offered', () {
      // A studio's name is katakana, and when one reaches the six the app
      // shows, a third of the row is unreadable to this app's reader. That is
      // worth an offer even though the rest is Chinese.
      expect(
        workTextReadsForeign('碧蓝之海 · 日常 · ゼロジー', origin: WorkOrigin.japan),
        isTrue,
      );
    });

    test('a Chinese title on a work the source files under Japan', () {
      // A Japanese work whose Chinese name the source published: the page shows
      // the Chinese name, so there is nothing to translate.
      expect(
        workTitleReadsForeign(
          title: '尼古喵喵',
          sourceTitle: 'ヤニねこ',
          origin: WorkOrigin.japan,
        ),
        isFalse,
      );
      expect(
        workTitleReadsForeign(
          title: '幼女战记 第二季',
          sourceTitle: '幼女戦記Ⅱ',
          origin: WorkOrigin.japan,
        ),
        isFalse,
      );
    });
  });

  group('a Japanese text is offered', () {
    test('a title with kana in it', () {
      for (final title in <String>[
        'ヤニねこ',
        'パンの赤ちゃん',
        'つかめ！理科ダマン',
        '進撃の巨人',
        '君の名は。',
        '鬼の花嫁',
        '猫と竜',
      ]) {
        expect(workTextReadsForeign(title), isTrue, reason: title);
      }
    });

    test('a Japanese synopsis', () {
      expect(
        workTextReadsForeign(
          '「俺は、この異世界で本気だす！」 34歳・童貞・無職の引きこもりニート男。'
          '両親の葬儀の日に家を追い出された瞬間、トラックに轢かれ命を落としてしまう。',
          origin: WorkOrigin.japan,
        ),
        isTrue,
      );
    });

    test('a Japanese tag row', () {
      expect(workTextReadsForeign('ギャグ · 日常 · 2026年7月'), isTrue);
    });
  });

  group('a Japanese title written in nothing but kanji', () {
    // The case the characters cannot settle: these are all kanji, and so are
    // the Chinese titles above. Only the source's filing tells them apart, and
    // without it the app declines rather than guesses — a page that says
    // nothing is better than a button that translates Chinese into Chinese.
    test('is offered when the source files the work under Japan', () {
      for (final title in <String>['東京喰種', '銀魂', '犬夜叉', '喰霊', '灼眼']) {
        expect(
          workTitleReadsForeign(
            title: title,
            sourceTitle: title,
            origin: WorkOrigin.japan,
          ),
          isTrue,
          reason: title,
        );
      }
    });

    test('is offered even though the characters read as Chinese', () {
      expect(
        detectTextLanguage('東京喰種'),
        TextLanguage.chinese,
        reason: 'the characters alone do say Chinese; the filing overrides it',
      );
      expect(
        workTitleReadsForeign(
          title: '東京喰種',
          sourceTitle: '東京喰種',
          origin: WorkOrigin.japan,
        ),
        isTrue,
      );
    });

    test('is not offered when the source says nothing about the work', () {
      expect(
        workTitleReadsForeign(title: '東京喰種', sourceTitle: '東京喰種'),
        isFalse,
      );
    });

    test('is not offered when the source files the work under China', () {
      expect(
        workTitleReadsForeign(
          title: '一斩苍穹',
          sourceTitle: '一斩苍穹',
          origin: WorkOrigin.china,
        ),
        isFalse,
      );
    });
  });

  group('the marks that are not letters', () {
    // ・ and ー live in the katakana block and are not katakana. Chinese uses
    // both: ・ as a separator, ー in names. Counting either as Japanese is what
    // would put a button on a Chinese page, so neither is counted.
    test('a middle dot or a long-vowel mark alone is not Japanese', () {
      expect(detectTextLanguage('搞笑・日常'), TextLanguage.chinese);
      expect(detectTextLanguage('一ー二'), TextLanguage.chinese);
      expect(workTextReadsForeign('胶囊计划·奇迹'), isFalse);
      expect(workTextReadsForeign('搞笑·日常·校园·TV'), isFalse);
    });

    test('they do not stop a text that has real kana from being Japanese', () {
      expect(detectTextLanguage('スーパーの裏でヤニ吸うふたり'), TextLanguage.japanese);
      expect(detectTextLanguage('幼女戦記Ⅱ'), TextLanguage.chinese);
      expect(
        detectTextLanguage('Dodgers x ONE PIECE | 特別アニメーション映像 2026'),
        TextLanguage.japanese,
      );
    });
  });

  group('English is offered', () {
    test('a synopsis the source published in English', () {
      for (final text in <String>[
        'This season will introduce a new "Rescue-Webs"',
        "X-Men '97 Season 2 continues with the heroic mutants",
        'Mickey and friends use their new farm vehicles',
      ]) {
        expect(workTextReadsForeign(text), isTrue, reason: text);
      }
    });

    test('a work whose name is Latin script', () {
      expect(
        workTitleReadsForeign(
          title: 'SEALOOK 2nd season',
          sourceTitle: 'SEALOOK 2nd season',
        ),
        isTrue,
      );
    });
  });

  group('nothing at all', () {
    test('empty, blank and missing text is not offered', () {
      expect(readsForeign(null), isFalse);
      expect(readsForeign(''), isFalse);
      expect(readsForeign('   \n  '), isFalse);
      expect(detectTextLanguage(null), TextLanguage.undetermined);
    });

    test('a short label is not offered', () {
      // A format, a season, an episode count, a tag: translating `WEB` helps
      // nobody, and a translation of it is `WEB` back again.
      for (final label in <String>[
        'TV',
        'OP',
        'ED',
        '1',
        '—',
        'WEB',
        'TVA',
        'CUE',
        'AURA',
        '2026',
      ]) {
        expect(readsForeign(label), isFalse, reason: label);
      }
      // Five letters is where a run stops reading as a code.
      expect(readsForeign('NARUTO'), isTrue);
    });
  });

  group('the share', () {
    // The line between "some kana in a Chinese text" and "a Japanese text".
    // Over sixty subjects measured against the source, every Chinese text
    // scored zero and every Japanese one above a quarter; the line sits in the
    // empty space between.
    test('a text with a little kana in it is still Chinese', () {
      // A Chinese sentence that quotes one Japanese word: the kana in it is a
      // name, not the language it is written in.
      expect(
        detectTextLanguage('这是一个关于友情与成长的故事，很好看的动画テスト'),
        TextLanguage.chinese,
      );
    });

    test('a text that is a third kana is Japanese', () {
      expect(detectTextLanguage('物語のテスト'), TextLanguage.japanese);
    });
  });
}
