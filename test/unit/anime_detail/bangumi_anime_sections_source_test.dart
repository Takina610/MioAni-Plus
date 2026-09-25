import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/anime_detail/data/bangumi_anime_sections_source.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';

void main() {
  test('maps the cast the subject endpoint publishes', () async {
    final source = _source(
      _QueueAdapter(<Object?>[
        <Object?>[
          <String, Object?>{
            'id': 174916,
            'name': 'ヤニねこ',
            'relation': '主角',
            'images': <String, Object?>{
              'large': 'https://lain.bgm.tv/pic/crt/l/18/c7/174916_crt.jpg',
            },
            'actors': <Object?>[
              <String, Object?>{
                'id': 36024,
                'name': '夏吉ゆうこ',
                'images': <String, Object?>{
                  'grid': 'https://lain.bgm.tv/pic/crt/g/7d/6d/36024_prsn.jpg',
                  'large': 'https://lain.bgm.tv/pic/crt/l/7d/6d/36024_prsn.jpg',
                },
              },
            ],
          },
        ],
      ]),
    );

    final credits = await source.fetchCharacters(
      AnimeSourceId.fromBangumiId(622206),
    );

    expect(credits, hasLength(1));
    final credit = credits.single;
    expect(credit.name, 'ヤニねこ');
    // How a character stands to the work is filed under `relation` on this
    // endpoint, which is why the card used to draw every character as unnamed.
    expect(credit.role, '主角');
    expect(credit.imageUrl.toString(), contains('/pic/crt/l/'));
    // And the actor is a list of credits rather than one field, with their own
    // portrait published at several sizes — a card shows a face next to a name,
    // not a full portrait.
    expect(credit.voiceActorName, '夏吉ゆうこ');
    expect(credit.voiceActorId?.value, 'bgm-person-36024');
    expect(credit.voiceActorImageUrl.toString(), contains('/pic/crt/g/'));
  });

  test('a character with no actor is still a character', () async {
    final source = _source(
      _QueueAdapter(<Object?>[
        <Object?>[
          <String, Object?>{'id': 7, 'name': '背景角色', 'actors': <Object?>[]},
        ],
      ]),
    );

    final credits = await source.fetchCharacters(
      AnimeSourceId.fromBangumiId(1),
    );

    expect(credits.single.voiceActorName, isNull);
    expect(credits.single.voiceActorId, isNull);
    expect(credits.single.voiceActorImageUrl, isNull);
  });

  test('reads relations and staff as the subject publishes them', () async {
    final source = _source(
      _QueueAdapter(<Object?>[
        // Related subjects come from `/subjects`, and a relation is the subject
        // itself beside the word for how it relates.
        <Object?>[
          <String, Object?>{
            'id': 9,
            'name': 'Yani Neko 2',
            'name_cn': '尼古喵喵 第二季',
            'relation': '续集',
            'images': <String, Object?>{
              'common': 'https://lain.bgm.tv/r/400/pic/cover/l/aa/bb/9.jpg',
              'large': 'https://lain.bgm.tv/pic/cover/l/aa/bb/9.jpg',
            },
          },
        ],
        <Object?>[
          <String, Object?>{'id': 91473, 'name': '見留滉平', 'relation': '音响制作担当'},
        ],
      ]),
    );

    final relations = await source.fetchRelations(
      AnimeSourceId.fromBangumiId(1),
    );
    final staff = await source.fetchStaff(AnimeSourceId.fromBangumiId(1));

    expect(relations.single.title, '尼古喵喵 第二季');
    expect(relations.single.relation, '续集');
    // A relation's poster is drawn 56 pixels wide; the original is not asked
    // for something that size.
    expect(relations.single.imageUrl.toString(), contains('/r/400/'));
    expect(staff.single.name, '見留滉平');
    expect(staff.single.role, '音响制作担当');
  });
}

BangumiAnimeSectionsSource _source(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  )..httpClientAdapter = adapter;
  return BangumiAnimeSectionsSource(
    dio: dio,
    coordinator: RequestCoordinator(),
  );
}

final class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this.responses);

  final List<Object?> responses;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = responses.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
