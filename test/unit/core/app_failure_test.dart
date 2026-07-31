import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';

void main() {
  test('application failures expose safe user-facing classifications', () {
    const failures = <AppFailure>[
      CancelledFailure(),
      OfflineFailure(),
      TimeoutFailure(),
      RateLimitedFailure(),
      NotFoundFailure(),
      ForbiddenFailure(),
      UpstreamFailure(),
      InvalidPayloadFailure(),
      BrowserPolicyFailure(),
      UnknownFailure(),
    ];

    expect(
      failures.map((failure) => failure.kind).toSet(),
      AppFailureKind.values.toSet(),
    );
    expect(
      failures.every((failure) => failure.userMessage.trim().isNotEmpty),
      isTrue,
    );
  });
}
