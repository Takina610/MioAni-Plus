import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/app/routing/app_router.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/schedule/application/schedule_providers.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

import '../test/support/fake_catalog_repository.dart';
import '../test/support/fake_home_repository.dart';
import '../test/support/fake_schedule_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home → schedule → detail → back keeps the branch and date', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(392, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scheduleRepository = FakeScheduleRepository(
      watchFactory: () => Stream.value(
        testScheduleSnapshot(
          DateTime(2026, 8, 4),
          items: <ScheduleSourceItem>[
            ScheduleSourceItem(
              anime: testAnimeSummary,
              weekday: ScheduleWeekday.monday,
            ),
          ],
        ),
      ),
    );
    final homeRepository = FakeHomeRepository(
      watchFactory: () => Stream.value(
        testHomeSnapshot(
          catalog: HomeSection<HomeCatalogContent>.ready(
            value: HomeCatalogContent(
              hero: <AnimeSummary>[testAnimeSummary],
              recommended: <AnimeSummary>[testAnimeSummary],
              trending: <AnimeSummary>[testAnimeSummary],
            ),
          ),
        ),
      ),
    );
    final router = createMioAniRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(
        router: router,
        providerOverrides: [
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
          homeRepositoryProvider.overrideWithValue(homeRepository),
          scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Home renders the catalog-derived hero/recommended content.
    expect(find.text('本季推荐'), findsOneWidget);
    expect(find.text('测试动画'), findsWidgets);
    expect(router.routeInformationProvider.value.uri.path, '/');

    // Switch to the schedule branch.
    await tester.tap(find.text('日程'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/schedule');
    expect(find.text('放送日程'), findsOneWidget);
    expect(find.text('周一'), findsOneWidget);

    // Open the anime detail from the schedule item.
    await tester.ensureVisible(find.text('测试动画'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试动画').first);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/anime/bgm-1');
    expect(find.text('动画详情'), findsOneWidget);

    // Back returns to the schedule branch with its date/state preserved.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/schedule');
    expect(find.text('放送日程'), findsOneWidget);
    expect(find.text('周一'), findsOneWidget);
    expect(scheduleRepository.calls, 1);
  });
}
