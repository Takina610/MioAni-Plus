import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/app/routing/app_router.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/schedule/application/schedule_providers.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';
import 'package:mio_ani/src/features/schedule/presentation/schedule_page.dart';

import '../../support/fake_catalog_repository.dart';
import '../../support/fake_home_repository.dart';
import '../../support/fake_schedule_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('renders seven days with timed and untimed items', (
    tester,
  ) async {
    final repository = FakeScheduleRepository(
      watchFactory: () => Stream.value(
        testScheduleSnapshot(
          DateTime(2026, 8, 4),
          items: <ScheduleSourceItem>[
            ScheduleSourceItem(
              anime: testAnimeSummary,
              weekday: ScheduleWeekday.monday,
              airTime: ScheduleTime.fromHourMinute(22, 30),
            ),
          ],
        ),
      ),
    );

    await _pumpPage(tester, repository);
    await tester.pump();

    expect(find.text('周一'), findsOneWidget);
    expect(find.text('周二'), findsOneWidget);
    expect(find.text('周日'), findsOneWidget);
    expect(find.text('22:30'), findsOneWidget);
    expect(find.text('测试动画'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale cache banner offers a retry', (tester) async {
    final repository = FakeScheduleRepository(
      watchFactory: () => Stream.value(
        CatalogSnapshot(
          value: testScheduleSnapshot(DateTime(2026, 8, 4)).value,
          fetchedAt: DateTime.utc(2026, 8, 4, 8),
          isStale: true,
          refreshFailure: const OfflineFailure(),
        ),
      ),
    );

    await _pumpPage(tester, repository);
    await tester.pump();

    expect(find.textContaining('当前显示离线缓存'), findsOneWidget);
    expect(repository.calls, 1);
    await tester.tap(find.text('重试更新'));
    await tester.pump();
    expect(repository.calls, 2);
  });

  testWidgets('full failure shows an explicit retry state', (tester) async {
    final repository = FakeScheduleRepository(failure: const OfflineFailure());

    await _pumpPage(tester, repository);
    await tester.pump();
    await tester.pump();

    expect(find.text('当前处于离线状态'), findsOneWidget);
    expect(repository.calls, 1);
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(repository.calls, 2);
  });

  testWidgets('week navigation updates the date query', (tester) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter(
      initialLocation: '/schedule?date=2026-08-11',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(
        router: router,
        providerOverrides: [
          scheduleRepositoryProvider.overrideWithValue(
            FakeScheduleRepository(),
          ),
          homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/schedule');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['date'],
      '2026-08-11',
    );
    expect(find.text('8/10 – 8/16'), findsOneWidget);

    await tester.tap(find.byTooltip('上一周'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['date'],
      '2026-08-03',
    );
    expect(find.text('8/3 – 8/9'), findsOneWidget);

    await tester.tap(find.byTooltip('下一周'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters['date'],
      '2026-08-10',
    );
  });

  testWidgets('schedule item opens the anime detail page', (tester) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter(initialLocation: '/schedule');
    addTearDown(router.dispose);
    final schedule = FakeScheduleRepository(
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

    await tester.pumpWidget(
      MioAniRoot(
        router: router,
        providerOverrides: [
          scheduleRepositoryProvider.overrideWithValue(schedule),
          homeRepositoryProvider.overrideWithValue(FakeHomeRepository()),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('测试动画').first);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/anime/bgm-1');
    expect(find.text('动画详情'), findsOneWidget);
  });

  for (final size in <Size>[
    const Size(390, 844),
    const Size(800, 900),
    const Size(1440, 900),
  ]) {
    testWidgets('supports ${size.width.toInt()}px layout at 200% text scale', (
      tester,
    ) async {
      await configureTestViewport(tester, size: size, textScaleFactor: 2);
      final repository = FakeScheduleRepository();
      await _pumpPage(tester, repository);
      await tester.pump();

      expect(find.text('周一'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpPage(WidgetTester tester, FakeScheduleRepository repository) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
      retry: disableProviderRetry,
      child: MaterialApp(home: SchedulePage(initialDate: DateTime(2026, 8, 4))),
    ),
  );
}
