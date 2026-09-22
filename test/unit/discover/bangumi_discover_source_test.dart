import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/discover/data/bangumi_discover_source.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

void main() {
  test('maps the live subjects search payload', () async {
    final adapter = _QueueAdapter(<_AdapterResponse>[
      _AdapterResponse.json(_fixture('search_page.json')),
    ]);
    final source = BangumiDiscoverSource(
      dio: _dio(adapter),
      coordinator: RequestCoordinator(),
    );

    final result = await source.fetchPage(
      const DiscoverPageRequest(
        query: DiscoverQuery(keyword: 'Frieren', sort: DiscoverSort.popularity),
        page: 1,
        source: AnimeSource.bangumi,
      ),
    );

    expect(
      adapter.requests.single.uri.toString(),
      'https://api.bgm.tv/v0/search/subjects?limit=24&offset=0',
    );
    final body = _requestBody(adapter.requests.single);
    expect(body['keyword'], 'Frieren');
    expect(body['sort'], 'heat');
    // The endpoint ignores page/page_size in the body.
    expect(body.containsKey('page'), isFalse);
    expect(body.containsKey('page_size'), isFalse);

    expect(result.total, 5);
    expect(result.source, AnimeSource.bangumi);
    // Every subject in the payload survives mapping; none is dropped.
    expect(result.items, hasLength(5));
    final first = result.items.first;
    expect(first.id.source, AnimeSource.bangumi);
    expect(first.id.rawId, greaterThan(0));
    expect(first.title, isNotEmpty);
    expect(first.sourceTitle, isNotEmpty);
    expect(first.imageUrl, isNotNull);
    expect(first.airDate, isNotNull);
    // The payload holds fewer matches than one page, so nothing follows.
    expect(result.hasMore, isFalse);
  });

  test('maps every sort to a value the subjects endpoint accepts', () async {
    // The endpoint answers 400 "sort not supported" for anything else, so a
    // new DiscoverSort must not leak an unsupported value into the request.
    const supported = <String>{'match', 'heat', 'rank', 'score'};
    for (final sort in DiscoverSort.values) {
      final adapter = _QueueAdapter(<_AdapterResponse>[
        _AdapterResponse.json(_fixture('search_page.json')),
      ]);
      final source = BangumiDiscoverSource(
        dio: _dio(adapter),
        coordinator: RequestCoordinator(),
      );

      await source.fetchPage(
        DiscoverPageRequest(
          query: DiscoverQuery(keyword: 'Frieren', sort: sort),
          page: 1,
          source: AnimeSource.bangumi,
        ),
      );

      expect(
        supported,
        contains(_requestBody(adapter.requests.single)['sort']),
        reason: 'sort $sort',
      );
    }
  });

  test('advances the offset when a later page is requested', () async {
    final adapter = _QueueAdapter(<_AdapterResponse>[
      _AdapterResponse.json(_fixture('search_page.json')),
      _AdapterResponse.json(_fixture('search_page.json')),
    ]);
    final source = BangumiDiscoverSource(
      dio: _dio(adapter),
      coordinator: RequestCoordinator(),
    );

    for (final page in <int>[1, 2]) {
      await source.fetchPage(
        DiscoverPageRequest(
          query: const DiscoverQuery(keyword: 'Frieren'),
          page: page,
          source: AnimeSource.bangumi,
        ),
      );
    }

    expect(adapter.requests.map((request) => request.uri.query), <String>[
      'limit=24&offset=0',
      'limit=24&offset=24',
    ]);
  });

  test('rejects a payload without the documented data list', () async {
    final source = BangumiDiscoverSource(
      dio: _dio(
        _QueueAdapter(<_AdapterResponse>[
          _AdapterResponse.json(<String, Object?>{'total': 3}),
        ]),
      ),
      coordinator: RequestCoordinator(),
    );

    await expectLater(
      source.fetchPage(
        const DiscoverPageRequest(
          query: DiscoverQuery(keyword: 'Frieren'),
          page: 1,
          source: AnimeSource.bangumi,
        ),
      ),
      throwsA(isA<InvalidPayloadFailure>()),
    );
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

Map<Object?, Object?> _requestBody(RequestOptions options) {
  final data = options.data;
  if (data is Map<Object?, Object?>) return data;
  if (data is String) {
    return jsonDecode(data) as Map<Object?, Object?>;
  }
  throw StateError('unexpected request body: $data');
}

Object? _fixture(String name) {
  final text = File('test/fixtures/bangumi/$name').readAsStringSync();
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
