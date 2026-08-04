import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_schedule_source.dart';

void main() {
  test('posts the static GraphQL query and maps airing donors', () async {
    final adapter = _QueueAdapter(<Object?>[_fixture('season_page.json')]);
    final source = _source(adapter, clock: () => DateTime(2026, 8, 4));

    final entries = await source.fetchAiringEntries();

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://graphql.anilist.co');
    expect(request.method, 'POST');
    final body = jsonDecode(request.data as String) as Map<String, Object?>;
    final variables = body['variables'] as Map<String, Object?>;
    expect(variables['season'], 'SUMMER');
    expect(variables['seasonYear'], 2026);
    expect(body['query'], contains('nextAiringEpisode'));

    expect(entries, hasLength(1));
    final entry = entries.single;
    expect(entry.anime.id, AnimeSourceId.fromAniListId(141391));
    expect(entry.anime.title, 'D.C.S.S. ~Da Capo Second Season~');
    expect(entry.anime.sourceTitle, contains('ダ・カーポ'));
    expect(entry.anime.score, 6.5);
    expect(entry.anime.popularity, 4321);
    expect(entry.anime.episodes, 26);
    expect(entry.airingAt.toUtc().year, 2024);
    expect(entry.airingAt.toUtc().hour, 21);
  });

  test('drops media without a next airing and tolerates missing fields', () {
    final source = _source(
      _QueueAdapter(<Object?>[
        <String, Object?>{
          'data': <String, Object?>{
            'Page': <String, Object?>{
              'media': <Object?>[
                <String, Object?>{
                  'id': 1,
                  'title': null,
                  'coverImage': null,
                  'nextAiringEpisode': null,
                },
                <String, Object?>{
                  'id': 2,
                  'title': <String, Object?>{
                    'romaji': 'Two',
                    'english': null,
                    'native': null,
                  },
                  'coverImage': null,
                  'episodes': 12,
                  'averageScore': null,
                  'popularity': 5,
                  'nextAiringEpisode': <String, Object?>{
                    'airingAt': 1722805200,
                    'episode': 1,
                  },
                },
              ],
            },
          },
        },
      ]),
    );

    final entries = source.fetchAiringEntries();
    return entries.then((value) {
      expect(value, hasLength(1));
      expect(value.single.anime.title, 'Two');
      expect(value.single.anime.episodes, 12);
      expect(value.single.anime.score, isNull);
    });
  });

  test('maps an invalid GraphQL root to a payload failure', () async {
    final source = _source(
      _QueueAdapter(<Object?>[
        <String, Object?>{
          'errors': <Object?>[
            <String, Object?>{'message': 'boom'},
          ],
        },
      ]),
    );

    await expectLater(
      source.fetchAiringEntries(),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });
}

AniListScheduleSource _source(
  HttpClientAdapter adapter, {
  DateTime Function()? clock,
}) {
  final dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  )..httpClientAdapter = adapter;
  return AniListScheduleSource(
    dio: dio,
    coordinator: RequestCoordinator(),
    clock: clock ?? DateTime.now,
  );
}

Object? _fixture(String name) {
  final text = File('test/fixtures/anilist/$name').readAsStringSync();
  return jsonDecode(text);
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
    final body = responses.removeAt(0);
    return ResponseBody.fromString(
      body is String ? body : jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
