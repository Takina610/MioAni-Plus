import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_page.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';

import '../../support/fake_catalog_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('invalid IDs render not found without calling the repository', (
    tester,
  ) async {
    final repository = FakeCatalogRepository();

    await _pumpPage(tester, repository, 'invalid');
    await tester.pump();

    expect(find.text('页面不存在'), findsOneWidget);
    expect(find.textContaining('无法识别动画 ID'), findsOneWidget);
    expect(repository.detailCalls, 0);
  });

  testWidgets('renders a valid detail and stale state at 200% text scale', (
    tester,
  ) async {
    await configureTestViewport(
      tester,
      size: const Size(390, 844),
      textScaleFactor: 2,
    );
    final repository = FakeCatalogRepository(
      detailFactory: () =>
          Stream.value(testSnapshot(testAnimeDetail, isStale: true)),
    );

    await _pumpPage(tester, repository, 'bgm-1');
    await tester.pumpAndSettle();

    expect(find.text('测试动画'), findsOneWidget);
    expect(find.text('评分 8.2'), findsOneWidget);
    expect(find.text('12 集'), findsOneWidget);
    expect(find.textContaining('已缓存的详情'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders loading and not-found source states', (tester) async {
    final controller = StreamController<CatalogSnapshot<AnimeDetail>>();
    addTearDown(controller.close);
    final loadingRepository = FakeCatalogRepository(detail: controller.stream);
    await _pumpPage(tester, loadingRepository, 'bgm-1');
    expect(find.text('正在加载动画详情'), findsOneWidget);

    final missingRepository = FakeCatalogRepository(
      detailFactory: () =>
          Stream<CatalogSnapshot<AnimeDetail>>.error(const NotFoundFailure()),
    );
    await _pumpPage(tester, missingRepository, 'bgm-1');
    await tester.pumpAndSettle();
    expect(find.textContaining('Bangumi 中不存在'), findsOneWidget);
  });

  testWidgets('stale refresh failures expose a manual retry', (tester) async {
    final repository = FakeCatalogRepository(
      detailFactory: () => Stream.value(
        testSnapshot(
          testAnimeDetail,
          isStale: true,
          refreshFailure: const OfflineFailure(),
        ),
      ),
    );

    await _pumpPage(tester, repository, 'bgm-1');
    await tester.pumpAndSettle();

    expect(find.textContaining('当前处于离线状态'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '重试更新'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '重试更新'));
    await tester.pumpAndSettle();

    expect(repository.detailCalls, 2);
    expect(repository.lastDetailForceRefresh, isTrue);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  FakeCatalogRepository repository,
  String id,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
      retry: disableProviderRetry,
      child: MaterialApp(home: AnimeDetailPage(sourceId: id)),
    ),
  );
}
