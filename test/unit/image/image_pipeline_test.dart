import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';

void main() {
  test('validates image hosts and caches successful bytes in memory', () async {
    final adapter = _BytesAdapter(<int>[1, 2, 3]);
    final dio = Dio()..httpClientAdapter = adapter;
    final pipeline = DioImagePipeline(
      dio: dio,
      coordinator: RequestCoordinator(),
    );
    final uri = Uri.parse('https://lain.bgm.tv/pic/cover/test.jpg');

    expect(await pipeline.load(uri), Uint8List.fromList(<int>[1, 2, 3]));
    expect(await pipeline.load(uri), Uint8List.fromList(<int>[1, 2, 3]));
    expect(adapter.calls, 1);

    expect(
      () => pipeline.load(Uri.parse('https://example.com/test.jpg')),
      throwsA(isA<BrowserPolicyFailure>()),
    );
    expect(adapter.calls, 1);
  });

  test('maps empty image responses to an application failure', () async {
    final dio = Dio()..httpClientAdapter = _BytesAdapter(const <int>[]);
    final pipeline = DioImagePipeline(
      dio: dio,
      coordinator: RequestCoordinator(),
    );

    await expectLater(
      pipeline.load(Uri.parse('https://lain.bgm.tv/pic/cover/empty.jpg')),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });
}

final class _BytesAdapter implements HttpClientAdapter {
  _BytesAdapter(this.bytes);

  final List<int> bytes;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    return ResponseBody.fromBytes(bytes, 200);
  }

  @override
  void close({bool force = false}) {}
}
