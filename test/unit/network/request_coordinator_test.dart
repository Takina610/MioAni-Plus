import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';

void main() {
  test('coalesces concurrent consumers for the same logical request', () async {
    final coordinator = RequestCoordinator();
    final completer = Completer<int>();
    var calls = 0;

    Future<int> operation() {
      calls += 1;
      return completer.future;
    }

    final first = coordinator.execute<int>(
      source: NetworkSource.bangumiApi,
      key: 'calendar',
      operation: operation,
    );
    final second = coordinator.execute<int>(
      source: NetworkSource.bangumiApi,
      key: 'calendar',
      operation: operation,
    );
    completer.complete(42);

    expect(await Future.wait(<Future<int>>[first, second]), <int>[42, 42]);
    expect(calls, 1);
  });

  test('retries only retryable application failures within policy', () async {
    final waits = <Duration>[];
    final coordinator = RequestCoordinator(
      wait: (duration) async => waits.add(duration),
    );
    var calls = 0;

    final value = await coordinator.execute<int>(
      source: NetworkSource.bangumiApi,
      key: 'detail:2',
      retryEligible: true,
      operation: () async {
        calls += 1;
        if (calls < 3) throw const UpstreamFailure();
        return 2;
      },
    );

    expect(value, 2);
    expect(calls, 3);
    expect(waits, <Duration>[
      const Duration(milliseconds: 500),
      const Duration(milliseconds: 1500),
    ]);

    await expectLater(
      coordinator.execute<int>(
        source: NetworkSource.bangumiApi,
        key: 'missing',
        operation: () async => throw const NotFoundFailure(),
      ),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('does not retry when the request is not retry eligible', () async {
    final waits = <Duration>[];
    final coordinator = RequestCoordinator(
      wait: (duration) async => waits.add(duration),
    );
    var calls = 0;

    await expectLater(
      coordinator.execute<void>(
        source: NetworkSource.bangumiApi,
        key: 'non-idempotent',
        retryEligible: false,
        operation: () async {
          calls += 1;
          throw const UpstreamFailure();
        },
      ),
      throwsA(isA<UpstreamFailure>()),
    );

    expect(calls, 1);
    expect(waits, isEmpty);
  });

  test('a new generation discards the older in-flight result', () async {
    final coordinator = RequestCoordinator();
    final firstResult = Completer<int>();
    final secondResult = Completer<int>();
    var calls = 0;

    final first = coordinator.execute<int>(
      source: NetworkSource.bangumiApi,
      key: 'calendar-generation',
      operation: () {
        calls += 1;
        return firstResult.future;
      },
    );
    final firstExpectation = expectLater(
      first,
      throwsA(isA<CancelledFailure>()),
    );
    final second = coordinator.execute<int>(
      source: NetworkSource.bangumiApi,
      key: 'calendar-generation',
      forceNewGeneration: true,
      operation: () {
        calls += 1;
        return secondResult.future;
      },
    );

    secondResult.complete(2);
    expect(await second, 2);
    await Future<void>.delayed(Duration.zero);
    expect(
      await coordinator.execute<int>(
        source: NetworkSource.bangumiApi,
        key: 'calendar-generation',
        operation: () async {
          calls += 1;
          return 3;
        },
      ),
      3,
    );

    firstResult.complete(1);
    await firstExpectation;
    expect(calls, 3);
  });

  test(
    'different keys are not coalesced and completed keys run again',
    () async {
      final coordinator = RequestCoordinator();
      var calls = 0;

      Future<int> execute(String key) {
        return coordinator.execute<int>(
          source: NetworkSource.bangumiApi,
          key: key,
          operation: () async => ++calls,
        );
      }

      expect(
        await Future.wait(<Future<int>>[execute('a'), execute('b')]),
        <int>[1, 2],
      );
      expect(await execute('a'), 3);
    },
  );

  test('limits concurrent operations per source', () async {
    final coordinator = RequestCoordinator(maxConcurrentPerSource: 2);
    final releases = <Completer<void>>[];
    var active = 0;
    var peak = 0;

    Future<int> operation(int value) async {
      active += 1;
      peak = active > peak ? active : peak;
      final release = Completer<void>();
      releases.add(release);
      await release.future;
      active -= 1;
      return value;
    }

    final futures = List<Future<int>>.generate(
      4,
      (index) => coordinator.execute<int>(
        source: NetworkSource.bangumiApi,
        key: 'request:$index',
        operation: () => operation(index),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(releases, hasLength(2));
    releases[0].complete();
    releases[1].complete();
    await Future<void>.delayed(Duration.zero);
    expect(releases, hasLength(4));
    releases[2].complete();
    releases[3].complete();

    expect(await Future.wait(futures), <int>[0, 1, 2, 3]);
    expect(peak, 2);
  });

  test('defaults to four concurrent operations per source', () {
    expect(RequestCoordinator().maxConcurrentPerSource, 4);
  });

  test('retry backoff does not hold a source permit', () async {
    final retryWaitStarted = Completer<void>();
    final releaseRetryWait = Completer<void>();
    final coordinator = RequestCoordinator(
      maxConcurrentPerSource: 1,
      wait: (_) {
        retryWaitStarted.complete();
        return releaseRetryWait.future;
      },
    );
    var retryCalls = 0;
    var secondStarted = false;

    final retrying = coordinator.execute<int>(
      source: NetworkSource.bangumiApi,
      key: 'retrying',
      retryEligible: true,
      operation: () async {
        retryCalls += 1;
        if (retryCalls == 1) throw const OfflineFailure();
        return 1;
      },
    );
    await retryWaitStarted.future;

    final second = coordinator.execute<int>(
      source: NetworkSource.bangumiApi,
      key: 'second',
      operation: () async {
        secondStarted = true;
        return 2;
      },
    );
    expect(await second, 2);
    expect(secondStarted, isTrue);

    releaseRetryWait.complete();
    expect(await retrying, 1);
  });

  test(
    'does not automatically wait for rate limits above 30 seconds',
    () async {
      var waits = 0;
      final coordinator = RequestCoordinator(wait: (_) async => waits += 1);

      await expectLater(
        coordinator.execute<void>(
          source: NetworkSource.bangumiApi,
          key: 'limited',
          retryEligible: true,
          operation: () async =>
              throw const RateLimitedFailure(retryAfter: Duration(seconds: 31)),
        ),
        throwsA(isA<RateLimitedFailure>()),
      );
      expect(waits, 0);
    },
  );

  test('does not start a retry that exceeds the absolute deadline', () async {
    var waits = 0;
    var calls = 0;
    final coordinator = RequestCoordinator(
      wait: (_) async {
        waits += 1;
      },
    );

    await expectLater(
      coordinator.execute<void>(
        source: NetworkSource.bangumiApi,
        key: 'deadline',
        retryEligible: true,
        policy: const RequestPolicy(
          deadline: Duration(milliseconds: 400),
          retryDelays: <Duration>[Duration(milliseconds: 500)],
        ),
        operation: () async {
          calls += 1;
          throw const OfflineFailure();
        },
      ),
      throwsA(isA<TimeoutFailure>()),
    );
    expect(calls, 1);
    expect(waits, 0);
  });

  test('permit queue time counts toward the absolute deadline', () async {
    final coordinator = RequestCoordinator(maxConcurrentPerSource: 1);
    final releaseFirst = Completer<void>();
    final first = coordinator.execute<void>(
      source: NetworkSource.bangumiApi,
      key: 'holds-permit',
      operation: () => releaseFirst.future,
    );
    await Future<void>.delayed(Duration.zero);

    final queued = coordinator.execute<int>(
      source: NetworkSource.bangumiApi,
      key: 'queued-past-deadline',
      policy: const RequestPolicy(deadline: Duration(milliseconds: 30)),
      operation: () async => 2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));
    releaseFirst.complete();

    await expectLater(queued, throwsA(isA<TimeoutFailure>()));
    await first;
    expect(
      await coordinator.execute<int>(
        source: NetworkSource.bangumiApi,
        key: 'permit-remains-usable',
        operation: () async => 3,
      ),
      3,
    );
  });
}
