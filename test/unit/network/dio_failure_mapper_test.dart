import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';

void main() {
  DioException responseFailure(int status, {String? retryAfter}) {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response<Object?>(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: status,
        headers: Headers.fromMap(<String, List<String>>{
          if (retryAfter != null) 'retry-after': <String>[retryAfter],
        }),
      ),
      type: DioExceptionType.badResponse,
    );
  }

  test('maps retry and non-retry HTTP classifications', () {
    expect(mapDioFailure(responseFailure(403)), isA<ForbiddenFailure>());
    expect(mapDioFailure(responseFailure(404)), isA<NotFoundFailure>());
    expect(mapDioFailure(responseFailure(408)), isA<TimeoutFailure>());
    expect(mapDioFailure(responseFailure(422)), isA<RequestRejectedFailure>());
    expect(mapDioFailure(responseFailure(503)), isA<UpstreamFailure>());
    expect(mapDioFailure(responseFailure(302)), isA<BrowserPolicyFailure>());
  });

  test('parses Retry-After seconds and RFC 1123 dates', () {
    final seconds = mapDioFailure(responseFailure(429, retryAfter: '12'));
    expect(
      (seconds as RateLimitedFailure).retryAfter,
      const Duration(seconds: 12),
    );

    final date = mapDioFailure(
      responseFailure(429, retryAfter: 'Fri, 31 Jul 2026 08:00:12 GMT'),
      now: DateTime.utc(2026, 7, 31, 8),
    );
    expect(
      (date as RateLimitedFailure).retryAfter,
      const Duration(seconds: 12),
    );
  });

  test('maps transport failures without leaking Dio exceptions', () {
    DioException failure(DioExceptionType type) => DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: type,
    );

    expect(
      mapDioFailure(failure(DioExceptionType.connectionError)),
      isA<OfflineFailure>(),
    );
    expect(
      mapDioFailure(failure(DioExceptionType.receiveTimeout)),
      isA<TimeoutFailure>(),
    );
    expect(
      mapDioFailure(failure(DioExceptionType.cancel)),
      isA<CancelledFailure>(),
    );
    expect(
      mapDioFailure(failure(DioExceptionType.badCertificate)),
      isA<BrowserPolicyFailure>(),
    );
  });
}
