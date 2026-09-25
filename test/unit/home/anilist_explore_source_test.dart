import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/home/data/anilist_explore_source.dart';

void main() {
  test('posts the explore query for the page it was asked for', () async {
    final adapter = _QueueAdapter(<Object?>[_fixture('explore_page.json')]);
    final source = _source(adapter);

    final page = await source.fetchPage(2);

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://graphql.anilist.co');
    expect(request.method, 'POST');
    final body = jsonDecode(request.data as String) as Map<String, Object?>;
    final variables = body['variables'] as Map<String, Object?>;
    expect(variables['page'], 2);
    expect(variables['perPage'], 30);
    final query = body['query'] as String;
    expect(query, contains('POPULARITY_DESC'));
    expect(query, contains('isAdult: false'));
    // Exploring is walking past the current season, so the query must not be
    // scoped to one.
    expect(query, isNot(contains('season:')));

    expect(page.page, 2);
    expect(page.hasMore, isTrue);
    expect(page.source, AnimeSource.anilist);
    expect(page.items, hasLength(2));
    final first = page.items.first;
    expect(first.id, AnimeSourceId.fromAniListId(201));
    expect(first.title, 'エバーグリーン');
    expect(first.sourceTitle, 'Evergreen Show');
    expect(first.score, 8.4);
    expect(first.popularity, 900000);
    expect(first.episodes, 24);
    expect(first.imageUrl?.scheme, 'https');

    final second = page.items.last;
    expect(second.title, 'No Art');
    expect(second.sourceTitle, '');
    expect(second.score, isNull);
    expect(second.imageUrl, isNull);
  });

  test('a ranking with nothing behind it reports no more pages', () async {
    final source = _source(
      _QueueAdapter(<Object?>[
        <String, Object?>{
          'data': <String, Object?>{
            'Page': <String, Object?>{
              'pageInfo': <String, Object?>{'hasNextPage': false},
              'media': <Object?>[],
            },
          },
        },
      ]),
    );

    final page = await source.fetchPage(1);

    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
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
      source.fetchPage(1),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });
}

AniListExploreSource _source(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  )..httpClientAdapter = adapter;
  return AniListExploreSource(dio: dio, coordinator: RequestCoordinator());
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
