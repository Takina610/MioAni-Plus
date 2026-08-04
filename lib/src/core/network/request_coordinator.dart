import 'dart:async';
import 'dart:collection';

import 'package:mio_ani/src/core/failures/app_failure.dart';

enum NetworkSource { bangumiApi, bangumiImages, anilistApi, anilistImages }

typedef RequestWait = Future<void> Function(Duration duration);
typedef RequestNow = DateTime Function();

final class RequestPolicy {
  const RequestPolicy({
    this.deadline = const Duration(seconds: 20),
    this.maximumAutomaticRateLimitDelay = const Duration(seconds: 30),
    this.retryDelays = const <Duration>[
      Duration(milliseconds: 500),
      Duration(milliseconds: 1500),
    ],
  });

  final Duration deadline;
  final Duration maximumAutomaticRateLimitDelay;
  final List<Duration> retryDelays;
}

final class RequestCoordinator {
  RequestCoordinator({
    RequestWait? wait,
    RequestNow? now,
    this.maxConcurrentPerSource = 4,
  }) : _wait = wait ?? Future<void>.delayed,
       _now = now ?? DateTime.now;

  final RequestWait _wait;
  final RequestNow _now;
  final int maxConcurrentPerSource;
  final Map<String, Future<Object?>> _inFlight = <String, Future<Object?>>{};
  final Map<String, _RequestGenerationState> _generationStates =
      <String, _RequestGenerationState>{};
  final Map<NetworkSource, _AsyncPermitPool> _pools =
      <NetworkSource, _AsyncPermitPool>{};

  Future<T> execute<T>({
    required NetworkSource source,
    required String key,
    required Future<T> Function() operation,
    bool retryEligible = false,
    bool forceNewGeneration = false,
    RequestPolicy policy = const RequestPolicy(),
  }) {
    final requestKey = '${source.name}:$key';
    final existing = _inFlight[requestKey];
    if (!forceNewGeneration && existing != null) {
      return existing.then((value) => value as T);
    }

    final generationState = _generationStates.putIfAbsent(
      requestKey,
      _RequestGenerationState.new,
    );
    if (forceNewGeneration) generationState.current += 1;
    final generation = generationState.current;
    generationState.active += 1;
    final future = _discardSuperseded<T>(
      _run<T>(source, operation, retryEligible, policy),
      requestKey,
      generationState,
      generation,
    );
    _inFlight[requestKey] = future;
    unawaited(
      future.then<void>(
        (_) {
          _completeRequest(requestKey, future, generationState);
        },
        onError: (Object _, StackTrace _) {
          _completeRequest(requestKey, future, generationState);
        },
      ),
    );
    return future;
  }

  Future<T> _discardSuperseded<T>(
    Future<T> future,
    String requestKey,
    _RequestGenerationState generationState,
    int generation,
  ) async {
    try {
      final value = await future;
      if (generationState.current != generation) {
        throw const CancelledFailure();
      }
      return value;
    } on Object catch (error, stackTrace) {
      if (generationState.current != generation) {
        throw const CancelledFailure();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _completeRequest(
    String requestKey,
    Future<Object?> future,
    _RequestGenerationState generationState,
  ) {
    if (identical(_inFlight[requestKey], future)) {
      _inFlight.remove(requestKey);
    }
    generationState.active -= 1;
    assert(generationState.active >= 0, 'request generation completed twice');
    if (generationState.active == 0 &&
        identical(_generationStates[requestKey], generationState)) {
      _generationStates.remove(requestKey);
    }
  }

  Future<T> _run<T>(
    NetworkSource source,
    Future<T> Function() operation,
    bool retryEligible,
    RequestPolicy policy,
  ) async {
    final startedAt = _now();
    var attempt = 0;
    while (true) {
      final remainingBeforePermit =
          policy.deadline - _now().difference(startedAt);
      if (remainingBeforePermit <= Duration.zero) {
        throw const TimeoutFailure();
      }

      final pool = _pools.putIfAbsent(
        source,
        () => _AsyncPermitPool(maxConcurrentPerSource),
      );
      final acquire = pool.acquire();
      late final _ReleasePermit release;
      try {
        release = await acquire.timeout(
          remainingBeforePermit,
          onTimeout: () => throw const TimeoutFailure(),
        );
      } on TimeoutFailure {
        unawaited(acquire.then<void>((lateRelease) => lateRelease()));
        rethrow;
      }

      final remaining = policy.deadline - _now().difference(startedAt);
      if (remaining <= Duration.zero) {
        release();
        throw const TimeoutFailure();
      }
      AppFailure? failure;
      try {
        return await operation().timeout(
          remaining,
          onTimeout: () => throw const TimeoutFailure(),
        );
      } on AppFailure catch (error) {
        failure = error;
      } finally {
        release();
      }

      final caughtFailure = failure;
      if (!retryEligible ||
          !_isRetryable(caughtFailure) ||
          attempt >= policy.retryDelays.length) {
        throw caughtFailure;
      }

      final configuredDelay = policy.retryDelays[attempt];
      final delay = caughtFailure is RateLimitedFailure
          ? caughtFailure.retryAfter ?? configuredDelay
          : configuredDelay;
      if (caughtFailure is RateLimitedFailure &&
          delay > policy.maximumAutomaticRateLimitDelay) {
        throw caughtFailure;
      }
      if (_now().difference(startedAt) + delay >= policy.deadline) {
        throw const TimeoutFailure();
      }
      attempt += 1;
      await _wait(delay);
    }
  }

  bool _isRetryable(AppFailure failure) {
    return switch (failure.kind) {
      AppFailureKind.offline ||
      AppFailureKind.timeout ||
      AppFailureKind.upstream ||
      AppFailureKind.rateLimited => true,
      AppFailureKind.cancelled ||
      AppFailureKind.notFound ||
      AppFailureKind.forbidden ||
      AppFailureKind.requestRejected ||
      AppFailureKind.invalidPayload ||
      AppFailureKind.browserPolicy ||
      AppFailureKind.unknown => false,
    };
  }
}

typedef _ReleasePermit = void Function();

final class _RequestGenerationState {
  int current = 0;
  int active = 0;
}

final class _AsyncPermitPool {
  _AsyncPermitPool(this.capacity) : _available = capacity;

  final int capacity;
  int _available;
  final Queue<Completer<_ReleasePermit>> _waiting =
      Queue<Completer<_ReleasePermit>>();

  Future<_ReleasePermit> acquire() {
    if (_available > 0) {
      _available -= 1;
      return Future<_ReleasePermit>.value(_releaseOnce());
    }
    final completer = Completer<_ReleasePermit>();
    _waiting.add(completer);
    return completer.future;
  }

  _ReleasePermit _releaseOnce() {
    var released = false;
    return () {
      if (released) return;
      released = true;
      if (_waiting.isNotEmpty) {
        _waiting.removeFirst().complete(_releaseOnce());
      } else {
        _available += 1;
        assert(_available <= capacity, 'permit pool released too many times');
      }
    };
  }
}
