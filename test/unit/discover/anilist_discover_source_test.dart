import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/discover/data/anilist_discover_source.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

void main() {
  test('maps the live discover payload and omits unbound variables', () async {
    final adapter = _QueueAdapter(<_AdapterResponse>[
      _AdapterResponse.json(_fixture('discover_page.json')),
    ]);
    final source = AniListDiscoverSource(
      dio: _dio(adapter),
      coordinator: RequestCoordinator(),
    );

    final result = await source.fetchPage(
      const DiscoverPageRequest(
        query: DiscoverQuery(keyword: 'Frieren'),
        page: 1,
        source: AnimeSource.anilist,
      ),
    );

    final variables = _variables(adapter.requests.single);
    expect(variables['search'], 'Frieren');
    expect(variables['type'], 'ANIME');
    expect(variables['sort'], <String>['SEARCH_MATCH']);
    // AniList reads a present-but-null variable as an active filter: explicit
    // nulls rejected score bounds and emptied status-filtered pages.
    expect(variables.containsKey('status'), isFalse);
    expect(variables.containsKey('scoreGreater'), isFalse);
    expect(variables.containsKey('scoreLesser'), isFalse);
    expect(variables.containsKey('season'), isFalse);
    expect(variables.containsKey('seasonYear'), isFalse);
    expect(variables.containsKey('genres'), isFalse);

    expect(result.items, isNotEmpty);
    expect(result.source, AnimeSource.anilist);
    final first = result.items.first;
    expect(first.id.source, AnimeSource.anilist);
    expect(first.id.rawId, greaterThan(0));
    expect(first.title, isNotEmpty);
    expect(first.sourceTitle, isNotEmpty);
    expect(first.imageUrl, isNotNull);
    expect(first.airDate, isNotNull);
    expect(first.score, isNotNull);
  });

  test('sends filter values only when the query narrows them', () async {
    final adapter = _QueueAdapter(<_AdapterResponse>[
      _AdapterResponse.json(_fixture('discover_page.json')),
    ]);
    final source = AniListDiscoverSource(
      dio: _dio(adapter),
      coordinator: RequestCoordinator(),
    );

    await source.fetchPage(
      const DiscoverPageRequest(
        query: DiscoverQuery(
          format: DiscoverFormat.tv,
          airStatus: DiscoverAirStatus.airing,
          genres: <String>['Action'],
          scoreMin: 7,
        ),
        page: 1,
        source: AnimeSource.anilist,
      ),
    );

    final variables = _variables(adapter.requests.single);
    expect(variables['type'], 'ANIME');
    expect(variables['formatList'], <String>['TV']);
    expect(variables['status'], 'RELEASING');
    expect(variables['genres'], <String>['Action']);
    expect(variables['scoreGreater'], 70);
    expect(variables.containsKey('search'), isFalse);
  });
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  )..httpClientAdapter = adapter;
}

Map<String, Object?> _variables(RequestOptions options) {
  final data = options.data;
  final decoded = data is String ? jsonDecode(data) : data;
  final variables = (decoded as Map<Object?, Object?>)['variables'];
  return (variables as Map<Object?, Object?>).cast<String, Object?>();
}

Object? _fixture(String name) {
  final text = File('test/fixtures/anilist/$name').readAsStringSync();
  return jsonDecode(text);
}

final class _QueueAdapter implements HttpClientAdapter {
  _QueueAdapter(this.responses);

  final List<_AdapterResponse> responses;
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
      response.body is String
          ? response.body as String
          : jsonEncode(response.body),
      response.statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _AdapterResponse {
  const _AdapterResponse({required this.statusCode, required this.body});

  const _AdapterResponse.json(Object? body) : this(statusCode: 200, body: body);

  final int statusCode;
  final Object? body;
}
