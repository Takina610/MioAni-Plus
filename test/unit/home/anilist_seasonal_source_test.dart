import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/home/data/anilist_seasonal_source.dart';

void main() {
  test('posts the season query and maps the lineup', () async {
    final adapter = _QueueAdapter(<Object?>[_fixture('seasonal_page.json')]);
    final source = _source(adapter, clock: () => DateTime(2026, 8, 4));

    final items = await source.fetchSeason();

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.uri.toString(), 'https://graphql.anilist.co');
    expect(request.method, 'POST');
    final body = jsonDecode(request.data as String) as Map<String, Object?>;
    final variables = body['variables'] as Map<String, Object?>;
    expect(variables['season'], 'SUMMER');
    expect(variables['seasonYear'], 2026);
    expect(variables['page'], 1);
    expect(variables['perPage'], 50);
    final query = body['query'] as String;
    expect(query, contains('POPULARITY_DESC'));
    expect(query, contains('isAdult: false'));

    expect(items, hasLength(2));
    final first = items.first;
    expect(first.id, AnimeSourceId.fromAniListId(101));
    // AniList publishes romaji first, but a transliteration is not the title
    // anyone reads: the entry's own Japanese name is the display title.
    expect(first.title, 'サマー');
    expect(first.sourceTitle, 'Summer Show');
    expect(first.score, 7.5);
    expect(first.popularity, 5000);
    expect(first.episodes, 12);
    expect(first.imageUrl?.scheme, 'https');

    final second = items.last;
    // No native title on this entry, so the romanized one stands in.
    expect(second.title, 'No Art');
    expect(second.sourceTitle, '');
    expect(second.score, isNull);
    expect(second.imageUrl, isNull);
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
      source.fetchSeason(),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });
}

AniListSeasonalSource _source(
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
  return AniListSeasonalSource(
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
