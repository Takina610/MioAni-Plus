import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/home_repository.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

HomeSnapshot testHomeSnapshot({HomeSection<HomeCatalogContent>? catalog}) {
  return HomeSnapshot(
    catalog:
        catalog ??
        const HomeSection<HomeCatalogContent>.ready(
          value: HomeCatalogContent(
            hero: <AnimeSummary>[],
            trending: <AnimeSummary>[],
          ),
        ),
  );
}

final class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({Stream<HomeSnapshot> Function()? watchFactory})
    : _watchFactory = watchFactory ?? (() => Stream.value(testHomeSnapshot()));

  final Stream<HomeSnapshot> Function() _watchFactory;
  int calls = 0;
  bool? lastForceRefresh;

  @override
  Stream<HomeSnapshot> watchHome({bool forceRefresh = false}) {
    calls += 1;
    lastForceRefresh = forceRefresh;
    return _watchFactory();
  }
}
