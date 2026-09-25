import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';

import '../../support/fake_home_repository.dart';

void main() {
  test('opens the feed with its first page', () async {
    final repository = FakeHomeRepository(explorePages: testExploreRanking());
    final container = _container(repository);
    addTearDown(container.dispose);

    final states = <HomeExploreState>[];
    container.listen(
      homeExploreControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    await pumpEventQueue();

    expect(states.first.status, HomeExploreStatus.loading);
    final last = states.last;
    expect(last.status, HomeExploreStatus.ready);
    expect(last.items, hasLength(20));
    expect(last.items.first.title, '探索1-1');
    expect(last.page, 1);
    expect(last.hasMore, isTrue);
    expect(repository.lastExploreForceRefresh, isFalse);
  });

  test('a failed head leaves the section failed with its failure', () async {
    final repository = FakeHomeRepository(
      explorePages: testExploreRanking(),
      exploreFailure: const OfflineFailure(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    container.listen(homeExploreControllerProvider, (_, _) {});
    await pumpEventQueue();

    final state = container.read(homeExploreControllerProvider);
    expect(state.status, HomeExploreStatus.failed);
    expect(state.failure, isA<OfflineFailure>());
    expect(state.items, isEmpty);
  });

  test('a retry after a failed head recovers the feed', () async {
    final repository = FakeHomeRepository(
      explorePages: testExploreRanking(),
      exploreFailure: const OfflineFailure(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    container.listen(homeExploreControllerProvider, (_, _) {});
    await pumpEventQueue();
    repository.exploreFailure = null;

    container.read(homeExploreControllerProvider.notifier).refresh();
    await pumpEventQueue();

    final state = container.read(homeExploreControllerProvider);
    expect(state.status, HomeExploreStatus.ready);
    expect(state.items, hasLength(20));
  });

  test(
    'loadMore appends the next page without dropping what is shown',
    () async {
      final repository = FakeHomeRepository(
        explorePages: testExploreRanking(pages: 3),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      container.listen(homeExploreControllerProvider, (_, _) {});
      await pumpEventQueue();
      expect(
        container.read(homeExploreControllerProvider).items,
        hasLength(20),
      );

      container.read(homeExploreControllerProvider.notifier).loadMore();
      expect(
        container.read(homeExploreControllerProvider).status,
        HomeExploreStatus.loadingMore,
      );
      await pumpEventQueue();

      final state = container.read(homeExploreControllerProvider);
      expect(state.status, HomeExploreStatus.ready);
      expect(state.items, hasLength(40));
      expect(state.items.last.title, '探索2-20');
      expect(state.page, 2);
      expect(state.hasMore, isTrue);
      expect(repository.lastExplorePage, 2);
    },
  );

  test('loadMore stops at the end of the ranking', () async {
    final repository = FakeHomeRepository(explorePages: testExploreRanking());
    final container = _container(repository);
    addTearDown(container.dispose);

    container.listen(homeExploreControllerProvider, (_, _) {});
    await pumpEventQueue();

    container.read(homeExploreControllerProvider.notifier).loadMore();
    await pumpEventQueue();

    final state = container.read(homeExploreControllerProvider);
    expect(state.items, hasLength(40));
    expect(state.hasMore, isFalse);

    // A footer that is still on screen must not keep asking for pages the
    // ranking does not have.
    container.read(homeExploreControllerProvider.notifier).loadMore();
    await pumpEventQueue();
    expect(repository.exploreRequests, 2);
  });

  test('a failed page keeps the feed and reports itself', () async {
    final repository = FakeHomeRepository(
      explorePages: testExploreRanking(pages: 2),
      explorePageFailure: const OfflineFailure(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    container.listen(homeExploreControllerProvider, (_, _) {});
    await pumpEventQueue();

    container.read(homeExploreControllerProvider.notifier).loadMore();
    await pumpEventQueue();

    final state = container.read(homeExploreControllerProvider);
    expect(state.status, HomeExploreStatus.ready);
    expect(state.items, hasLength(20));
    expect(state.hasMore, isTrue);
    expect(state.loadMoreFailure, isA<OfflineFailure>());
  });

  test('loadMore clears a previous page failure before it retries', () async {
    final repository = FakeHomeRepository(
      explorePages: testExploreRanking(pages: 2),
      explorePageFailure: const OfflineFailure(),
    );
    final container = _container(repository);
    addTearDown(container.dispose);

    container.listen(homeExploreControllerProvider, (_, _) {});
    await pumpEventQueue();
    container.read(homeExploreControllerProvider.notifier).loadMore();
    await pumpEventQueue();
    repository.explorePageFailure = null;

    container.read(homeExploreControllerProvider.notifier).loadMore();
    await pumpEventQueue();

    final state = container.read(homeExploreControllerProvider);
    expect(state.loadMoreFailure, isNull);
    expect(state.items, hasLength(40));
  });

  test(
    'refresh re-reads the head and keeps the pages already scrolled',
    () async {
      final repository = FakeHomeRepository(
        explorePages: testExploreRanking(pages: 3),
      );
      final container = _container(repository);
      addTearDown(container.dispose);

      container.listen(homeExploreControllerProvider, (_, _) {});
      await pumpEventQueue();
      container.read(homeExploreControllerProvider.notifier).loadMore();
      await pumpEventQueue();
      expect(
        container.read(homeExploreControllerProvider).items,
        hasLength(40),
      );

      container.read(homeExploreControllerProvider.notifier).refresh();
      await pumpEventQueue();

      final state = container.read(homeExploreControllerProvider);
      expect(repository.lastExploreForceRefresh, isTrue);
      expect(state.items, hasLength(40));
      expect(state.page, 2);
    },
  );
}

ProviderContainer _container(FakeHomeRepository repository) {
  return ProviderContainer(
    overrides: [homeRepositoryProvider.overrideWithValue(repository)],
  );
}
