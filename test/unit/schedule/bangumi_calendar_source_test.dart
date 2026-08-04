import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/schedule/data/bangumi_calendar_source.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

void main() {
  test(
    'fetches the calendar and maps weekday buckets as untimed rows',
    () async {
      final adapter = _QueueAdapter(<Object?>[_fixture('calendar.json')]);
      final source = _source(adapter);

      final items = await source.fetchCalendar();

      expect(
        adapter.requests.single.uri.toString(),
        'https://api.bgm.tv/calendar',
      );
      expect(items, hasLength(1));
      final item = items.single;
      expect(item.weekday, ScheduleWeekday.monday);
      expect(item.airTime, isNull);
      expect(item.anime.id.value, 'bgm-2');
      expect(item.anime.title, '初音岛 S.S.');
      expect(item.anime.sourceTitle, 'D.C.S.S. ～ダ・カーポ セカンドシーズン～');
      expect(item.anime.popularity, 86);
      expect(item.anime.imageUrl!.scheme, 'https');
    },
  );

  test('rejects invalid roots and weekday buckets', () async {
    final invalidRoot = _source(_QueueAdapter(<Object?>[<String, Object?>{}]));
    await expectLater(
      invalidRoot.fetchCalendar(),
      throwsA(isA<InvalidPayloadFailure>()),
    );

    final missingWeekday = _source(
      _QueueAdapter(<Object?>[
        <Object?>[
          <String, Object?>{
            'weekday': <String, Object?>{'id': null},
            'items': <Object?>[],
          },
        ],
      ]),
    );
    await expectLater(
      missingWeekday.fetchCalendar(),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });
}

BangumiCalendarSource _source(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  )..httpClientAdapter = adapter;
  return BangumiCalendarSource(dio: dio, coordinator: RequestCoordinator());
}

Object? _fixture(String name) {
  final text = File('test/fixtures/bangumi/$name').readAsStringSync();
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
