import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/home/presentation/home_page.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

import '../../support/fake_home_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('renders brand hero and all ready sections', (tester) async {
    await configureTestViewport(tester, size: const Size(800, 2400));
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(_readySnapshot()),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    expect(find.text('MioAni'), findsOneWidget);
    expect(find.text('本季推荐'), findsOneWidget);
    expect(find.text('热门动画'), findsOneWidget);
    expect(find.text('最近更新'), findsOneWidget);
    expect(find.text('放送预览'), findsOneWidget);
    expect(find.text('首推动画'), findsWidgets);
    expect(find.text('热门动画A'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog failure does not block the schedule section', (
    tester,
  ) async {
    final snapshot = HomeSnapshot(
      catalog: const HomeSection<HomeCatalogContent>.failed(OfflineFailure()),
      schedule: const HomeSection<HomeScheduleContent>.ready(
        value: HomeScheduleContent(
          recent: <ScheduleItem>[],
          days: <ScheduleDay>[],
        ),
      ),
    );
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(snapshot),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    expect(find.text('当前处于离线状态'), findsOneWidget);
    expect(find.text('放送预览'), findsOneWidget);
    expect(find.text('查看完整日程'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale offline banner offers a retry', (tester) async {
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(
        testHomeSnapshot(
          catalog: HomeSection<HomeCatalogContent>.ready(
            value: const HomeCatalogContent(
              hero: <AnimeSummary>[],
              recommended: <AnimeSummary>[],
              trending: <AnimeSummary>[],
            ),
            isStale: true,
            fetchedAt: DateTime.utc(2026, 8, 4, 8),
            refreshFailure: const OfflineFailure(),
          ),
        ),
      ),
    );

    await _pumpHome(tester, repository);
    await tester.pump();

    expect(find.textContaining('当前显示离线缓存'), findsOneWidget);
    expect(repository.calls, 1);

    await tester.tap(find.text('重试更新'));
    await tester.pump();
    expect(repository.calls, 2);
  });

  testWidgets('hero carousel auto-advances and pauses on demand', (
    tester,
  ) async {
    final hero = <AnimeSummary>[_anime(1, '首推动画'), _anime(2, '第二部')];
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(
        testHomeSnapshot(
          catalog: HomeSection<HomeCatalogContent>.ready(
            value: HomeCatalogContent(
              hero: hero,
              recommended: hero,
              trending: hero,
            ),
          ),
        ),
      ),
    );

    await _pumpHome(tester, repository);
    await tester.pump();
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller!.page, 0);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 350));
    expect(pageView.controller!.page, closeTo(1, 0.01));

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.pump(const Duration(seconds: 12));
    expect(pageView.controller!.page, closeTo(1, 0.01));
  });

  testWidgets('reduced motion keeps the carousel static', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      () => tester.platformDispatcher.clearAccessibilityFeaturesTestValue(),
    );
    final hero = <AnimeSummary>[_anime(1, '首推动画'), _anime(2, '第二部')];
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(
        testHomeSnapshot(
          catalog: HomeSection<HomeCatalogContent>.ready(
            value: HomeCatalogContent(
              hero: hero,
              recommended: hero,
              trending: hero,
            ),
          ),
        ),
      ),
    );

    await _pumpHome(tester, repository);
    await tester.pump();
    final pageView = tester.widget<PageView>(find.byType(PageView));
    await tester.pump(const Duration(seconds: 12));
    expect(pageView.controller!.page, 0);
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
      final repository = FakeHomeRepository(
        watchFactory: () => Stream.value(_readySnapshot()),
      );

      await _pumpHome(tester, repository);
      await tester.pump();

      expect(find.text('本季推荐'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpHome(WidgetTester tester, FakeHomeRepository repository) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [homeRepositoryProvider.overrideWithValue(repository)],
      retry: disableProviderRetry,
      child: const MaterialApp(home: HomePage()),
    ),
  );
}

HomeSnapshot _readySnapshot() {
  final anime = <AnimeSummary>[_anime(1, '首推动画'), _anime(2, '热门动画A')];
  final days = buildWeekSchedule(<ScheduleSourceItem>[
    ScheduleSourceItem(
      anime: _anime(3, '周三动画'),
      weekday: ScheduleWeekday.wednesday,
      airTime: ScheduleTime.fromHourMinute(22, 30),
    ),
  ], DateTime(2026, 8, 4));
  final recent = flattenRecentSchedule(days, 10);
  return testHomeSnapshot(
    catalog: HomeSection<HomeCatalogContent>.ready(
      value: HomeCatalogContent(
        hero: anime,
        recommended: anime,
        trending: anime,
      ),
    ),
    schedule: HomeSection<HomeScheduleContent>.ready(
      value: HomeScheduleContent(recent: recent, days: days),
    ),
  );
}

AnimeSummary _anime(int id, String title) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: title,
    sourceTitle: '',
  );
}
