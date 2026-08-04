import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/people/data/bangumi_html_parser.dart';
import 'package:mio_ani/src/features/people/data/translation_parser.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

void main() {
  test('parses Bangumi profile text, infobox, aliases and image', () {
    const html =
        '''<h1> 角色名 </h1><img src="https://img.example/avatar.jpg"><div class="alias">别名一</div><div class="alias"><b>别名二</b></div><dl><dt>性别</dt><dd>女</dd><dt>生日</dt><dd>2001年2月3日</dd><dt>血型</dt><dd>A</dd><dt>职业</dt><dd>演员, 歌手</dd></dl><div class="summary">简介 &amp; 内容</div>''';
    final id = PersonSourceId.fromBangumiCharacter(7);
    final profile = const BangumiHtmlParser().parseProfile(html, id);
    expect(profile.name, '角色名');
    expect(profile.aliases, containsAll(<String>['别名一', '别名二']));
    expect(profile.gender, '女');
    expect(profile.birthDate, DateTime(2001, 2, 3));
    expect(profile.imageUrl, Uri.parse('https://img.example/avatar.jpg'));
    expect(profile.summary, contains('&'));
  });

  test('rejects empty and oversized HTML payloads', () {
    final id = PersonSourceId.fromBangumiPerson(1);
    expect(
      () => const BangumiHtmlParser().parseProfile('', id),
      throwsA(isA<InvalidPayloadFailure>()),
    );
    expect(
      () => const BangumiHtmlParser().parseProfile('<div></div>', id),
      throwsA(isA<InvalidPayloadFailure>()),
    );
    expect(
      () => const BangumiHtmlParser().parseProfile(
        List<String>.filled(2 * 1024 * 1024 + 1, 'x').join(),
        id,
      ),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });

  test('parses comments without exposing source markup', () {
    const html =
        '<article data-comment-id="c1"><span class="user">Alice</span><p>很好看</p></article><a>下一页</a>';
    final result = const BangumiCommentsParser().parse(html);
    expect(result.comments.single.id, 'c1');
    expect(result.comments.single.userName, 'Alice');
    expect(result.comments.single.body, isNot(contains('<')));
    expect(result.hasMore, isTrue);
  });

  test('parses nested translation blocks and rejects type drift', () {
    final blocks = const TranslationParser().parse(<Object?>[
      <Object?, Object?>{'source': 'a', 'text': '甲', 'language': 'zh'},
      <Object?, Object?>{
        'source': 'b',
        'text': '乙',
        'unknown': <Object?>[1],
      },
    ]);
    expect(blocks, hasLength(2));
    expect(blocks.first, isA<TranslationBlock>());
    expect(
      () => const TranslationParser().parse(<Object?>[
        <Object?, Object?>{'source': 'a', 'text': 1},
      ]),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });
}
