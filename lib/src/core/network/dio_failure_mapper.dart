import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';

AppFailure mapDioFailure(DioException exception, {DateTime? now}) {
  final status = exception.response?.statusCode;
  if (status != null) {
    return switch (status) {
      403 => const ForbiddenFailure(),
      404 => const NotFoundFailure(),
      408 => const TimeoutFailure(),
      429 => RateLimitedFailure(
        retryAfter: _retryAfter(
          exception.response?.headers,
          now ?? DateTime.now(),
        ),
      ),
      >= 500 => const UpstreamFailure(),
      >= 300 && < 400 => const BrowserPolicyFailure(),
      >= 400 && < 500 => const RequestRejectedFailure(),
      _ => const UpstreamFailure(),
    };
  }

  return switch (exception.type) {
    DioExceptionType.cancel => const CancelledFailure(),
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const TimeoutFailure(),
    DioExceptionType.connectionError => const OfflineFailure(),
    DioExceptionType.badCertificate => const BrowserPolicyFailure(),
    DioExceptionType.badResponse => const UpstreamFailure(),
    DioExceptionType.unknown => const UnknownFailure(),
  };
}

Duration? _retryAfter(Headers? headers, DateTime now) {
  final raw = headers?.value('retry-after')?.trim();
  if (raw == null || raw.isEmpty) return null;
  final seconds = int.tryParse(raw);
  if (seconds != null && seconds >= 0) return Duration(seconds: seconds);
  final date = _parseHttpDate(raw) ?? DateTime.tryParse(raw)?.toUtc();
  if (date == null) return null;
  final delay = date.difference(now.toUtc());
  return delay.isNegative ? Duration.zero : delay;
}

DateTime? _parseHttpDate(String value) {
  final match = RegExp(
    r'^[A-Za-z]{3},\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+'
    r'(\d{2}):(\d{2}):(\d{2})\s+GMT$',
  ).firstMatch(value);
  if (match == null) return null;
  const months = <String, int>{
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };
  final month = months[match.group(2)];
  if (month == null) return null;
  try {
    return DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
  } on FormatException {
    return null;
  }
}
