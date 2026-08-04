import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/data/home_repository.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';

void main() {
  test('controller exposes partition-ready content', () async {
    final repository = FakeHomeRepository();
    final container = ProviderContainer(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final states = <HomeSnapshot>[];
    container.listen(
      homeControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
    await pumpEventQueue();

    expect(states, isNotEmpty);
    final last = states.last;
    expect(last.catalog.status, HomeSectionStatus.ready);
    expect(last.catalog.value!.hero.single.title, '首推');
    expect(last.schedule.status, HomeSectionStatus.ready);
  });

  test('refresh bumps the home generation', () async {
    final repository = FakeHomeRepository();
    final container = ProviderContainer(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.listen(homeControllerProvider, (_, _) {}, fireImmediately: true);
    await pumpEventQueue();
    expect(repository.calls, 1);
    expect(repository.lastForceRefresh, isFalse);

    container.read(homeControllerProvider.notifier).refresh();
    await container.read(homeStreamProvider.future);
    await pumpEventQueue();

    expect(repository.calls, 2);
    expect(repository.lastForceRefresh, isTrue);
  });
}

final class FakeHomeRepository implements HomeRepository {
  int calls = 0;
  bool? lastForceRefresh;

  @override
  Stream<HomeSnapshot> watchHome({bool forceRefresh = false}) {
    calls += 1;
    lastForceRefresh = forceRefresh;
    final content = HomeCatalogContent(
      hero: <AnimeSummary>[
        AnimeSummary(
          id: AnimeSourceId.fromBangumiId(1),
          title: '首推',
          sourceTitle: '',
        ),
      ],
      recommended: const <AnimeSummary>[],
      trending: const <AnimeSummary>[],
    );
    return Stream<HomeSnapshot>.fromIterable(<HomeSnapshot>[
      const HomeSnapshot(),
      const HomeSnapshot().copyWith(
        catalog: HomeSection<HomeCatalogContent>.ready(value: content),
        schedule: const HomeSection<HomeScheduleContent>.ready(
          value: HomeScheduleContent(
            recent: <ScheduleItem>[],
            days: <ScheduleDay>[],
          ),
        ),
      ),
    ]);
  }
}
