import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_catalog_source.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';

void main() {
  test('requests fixed calendar and detail paths and maps fixtures', () async {
    final adapter = _QueueAdapter(<_AdapterResponse>[
      _AdapterResponse.json(_fixture('calendar.json')),
      _AdapterResponse.json(_fixture('detail.json')),
    ]);
    final source = _source(adapter);

    final catalog = await source.fetchCatalog();
    final detail = await source.fetchDetail(AnimeSourceId.fromBangumiId(2));

    expect(adapter.requests.map((request) => request.uri.toString()), <String>[
      'https://api.bgm.tv/calendar',
      'https://api.bgm.tv/v0/subjects/2',
    ]);
    expect(catalog, isNotEmpty);
    expect(catalog.map((item) => item.id.value), <String>['bgm-2']);
    expect(detail.id.value, 'bgm-2');
    expect(detail.title, isNotEmpty);
  });

  test('rejects invalid payloads and redirects as platform failures', () async {
    final invalidSource = _source(
      _QueueAdapter(<_AdapterResponse>[
        _AdapterResponse.json(<String, Object?>{}),
      ]),
    );
    await expectLater(
      invalidSource.fetchCatalog(),
      throwsA(isA<InvalidPayloadFailure>()),
    );

    final redirectSource = _source(
      _QueueAdapter(<_AdapterResponse>[
        const _AdapterResponse(statusCode: 302, body: ''),
      ]),
    );
    await expectLater(
      redirectSource.fetchCatalog(),
      throwsA(isA<BrowserPolicyFailure>()),
    );
  });

  test(
    'rejects detail payloads whose identity differs from the path',
    () async {
      final source = _source(
        _QueueAdapter(<_AdapterResponse>[
          _AdapterResponse.json(_fixture('detail.json')),
        ]),
      );

      await expectLater(
        source.fetchDetail(AnimeSourceId.fromBangumiId(1)),
        throwsA(isA<InvalidPayloadFailure>()),
      );
    },
  );
}

BangumiCatalogSource _source(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  )..httpClientAdapter = adapter;
  return BangumiCatalogSource(dio: dio, coordinator: RequestCoordinator());
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
