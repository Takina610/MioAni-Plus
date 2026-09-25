import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/home/data/bangumi_explore_source.dart';

void main() {
  test('asks the heat ranking for the page and maps it in Chinese', () async {
    final adapter = _QueueAdapter(<Object?>[_fixture('explore_page.json')]);
    final source = _source(adapter);

    final page = await source.fetchPage(3);

    expect(page.source, AnimeSource.bangumi);
    final request = adapter.requests.single;
    expect(
      request.uri.toString(),
      'https://api.bgm.tv/v0/search/subjects?limit=20&offset=40',
    );
    final body = _requestBody(request);
    expect(body['sort'], 'heat');
    expect(body['keyword'], '');
    expect(body['filter'], <String, Object?>{});

    // Three of the four entries are published; the adult one is not part of a
    // lineup browsed from the home page.
    expect(page.items, hasLength(3));
    final first = page.items.first;
    expect(first.id, AnimeSourceId.fromBangumiId(10380));
    expect(first.title, '命运石之门');
    expect(first.sourceTitle, 'STEINS;GATE');
    expect(first.score, 8.8);
    expect(first.episodes, 25);
    expect(first.imageUrl.toString(), contains('/pic/cover/l/a9/79/'));
  });

  test('reads on while the ranking has entries behind the page', () async {
    final adapter = _QueueAdapter(<Object?>[_fixture('explore_page.json')]);
    final source = _source(adapter);

    final page = await source.fetchPage(1);

    // The offset the payload was read at is 40 and it carried 4 entries of a
    // 1000-entry ranking, so there is more behind it. The number of *mapped*
    // (published) entries cannot decide this: a filtered entry would otherwise
    // make a ranking with pages left look finished.
    expect(page.hasMore, isTrue);
  });

  test('a ranking that ends reports no more pages', () async {
    final source = _source(
      _QueueAdapter(<Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'id': 10380,
              'name': 'STEINS;GATE',
              'name_cn': '命运石之门',
              'nsfw': false,
            },
          ],
          'total': 41,
          'limit': 20,
          'offset': 40,
        },
      ]),
    );

    final page = await source.fetchPage(3);

    expect(page.items, hasLength(1));
    expect(page.hasMore, isFalse);
  });

  test('prefers the cover size the entry actually publishes', () async {
    final adapter = _QueueAdapter(<Object?>[_fixture('explore_page.json')]);
    final source = _source(adapter);

    final page = await source.fetchPage(3);

    // The original is preferred when the entry publishes one…
    expect(page.items[0].imageUrl.toString(), contains('10380_YwP4R.jpg'));
    // …and an entry that only published a smaller rendition still shows one,
    // rather than the placeholder a `large`-or-nothing read would leave.
    expect(page.items[1].imageUrl.toString(), contains('900002_common.jpg'));
    // An entry with no cover at all is the only one that reads as cover-less.
    expect(page.items[2].imageUrl, isNull);
  });

  test('maps an unreadable payload to a payload failure', () async {
    final source = _source(
      _QueueAdapter(<Object?>[
        <String, Object?>{'total': 1000},
      ]),
    );

    await expectLater(
      source.fetchPage(1),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });
}

BangumiExploreSource _source(HttpClientAdapter adapter) {
  return BangumiExploreSource(
    dio: Dio(
      BaseOptions(
        followRedirects: false,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    )..httpClientAdapter = adapter,
    coordinator: RequestCoordinator(),
  );
}

Object? _fixture(String name) {
  final text = File('test/fixtures/bangumi/$name').readAsStringSync();
  return jsonDecode(text);
}

/// The request payload as the adapter sees it: Bangumi sources hand Dio a map
/// and let its transformer encode it, so both shapes reach the adapter.
Map<Object?, Object?> _requestBody(RequestOptions options) {
  final data = options.data;
  if (data is Map<Object?, Object?>) return data;
  if (data is String) return jsonDecode(data) as Map<Object?, Object?>;
  throw StateError('unexpected request body: $data');
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
