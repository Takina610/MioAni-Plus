enum AppFailureKind {
  cancelled,
  offline,
  timeout,
  rateLimited,
  notFound,
  forbidden,
  requestRejected,
  upstream,
  invalidPayload,
  browserPolicy,
  unknown,
}

sealed class AppFailure {
  const AppFailure({required this.kind, required this.userMessage});

  final AppFailureKind kind;
  final String userMessage;
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure()
    : super(kind: AppFailureKind.cancelled, userMessage: '操作已取消');
}

final class OfflineFailure extends AppFailure {
  const OfflineFailure()
    : super(kind: AppFailureKind.offline, userMessage: '当前处于离线状态');
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure()
    : super(kind: AppFailureKind.timeout, userMessage: '请求超时，请稍后重试');
}

final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({this.retryAfter})
    : super(kind: AppFailureKind.rateLimited, userMessage: '请求过于频繁，请稍后再试');

  final Duration? retryAfter;
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure()
    : super(kind: AppFailureKind.notFound, userMessage: '没有找到请求的内容');
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure()
    : super(kind: AppFailureKind.forbidden, userMessage: '当前无法访问此内容');
}

final class RequestRejectedFailure extends AppFailure {
  const RequestRejectedFailure()
    : super(kind: AppFailureKind.requestRejected, userMessage: '内容来源拒绝了此请求');
}

final class UpstreamFailure extends AppFailure {
  const UpstreamFailure()
    : super(kind: AppFailureKind.upstream, userMessage: '内容来源暂时不可用');
}

final class InvalidPayloadFailure extends AppFailure {
  const InvalidPayloadFailure()
    : super(kind: AppFailureKind.invalidPayload, userMessage: '收到的内容格式无法识别');
}

final class BrowserPolicyFailure extends AppFailure {
  const BrowserPolicyFailure()
    : super(kind: AppFailureKind.browserPolicy, userMessage: '浏览器策略阻止了此操作');
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure()
    : super(kind: AppFailureKind.unknown, userMessage: '发生未知错误，请稍后重试');
}
