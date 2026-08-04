import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/home/data/drift_home_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_repository.dart';
import 'package:mio_ani/src/features/home/data/home_repository_impl.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/schedule/application/schedule_providers.dart';
import 'package:mio_ani/src/features/schedule/data/bangumi_calendar_source.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    calendarSource: BangumiCalendarSource(
      dio: ref.watch(dioProvider),
      coordinator: ref.watch(requestCoordinatorProvider),
    ),
    scheduleRepository: ref.watch(scheduleRepositoryProvider),
    cache: DriftHomeCacheStore(database: ref.watch(catalogDatabaseProvider)),
    now: DateTime.now,
  );
});

final homeRefreshGenerationProvider = StateProvider<int>((ref) => 0);

final homeStreamProvider = StreamProvider<HomeSnapshot>((ref) {
  final generation = ref.watch(homeRefreshGenerationProvider);
  return ref
      .watch(homeRepositoryProvider)
      .watchHome(forceRefresh: generation > 0);
});

final class HomeController extends Notifier<HomeSnapshot> {
  @override
  HomeSnapshot build() {
    final async = ref.watch(homeStreamProvider);
    return async.value ?? const HomeSnapshot();
  }

  void refresh() {
    ref.read(homeRefreshGenerationProvider.notifier).state += 1;
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeSnapshot>(
  HomeController.new,
);
