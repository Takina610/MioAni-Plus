import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/catalog/presentation/catalog_tracer_page.dart';

import '../../support/fake_catalog_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('renders loading, content and stale cache states', (
    tester,
  ) async {
    final controller = StreamController<CatalogSnapshot<List<AnimeSummary>>>();
    addTearDown(controller.close);
    final repository = FakeCatalogRepository(catalog: controller.stream);

    await _pumpPage(tester, repository);
    expect(find.text('正在连接 Bangumi'), findsOneWidget);

    controller.add(
      testSnapshot(
        <AnimeSummary>[testAnimeSummary],
        isStale: true,
        refreshFailure: const OfflineFailure(),
      ),
    );
    await tester.pump();

    expect(find.text('本周动画目录'), findsOneWidget);
    expect(find.text('测试动画'), findsOneWidget);
    expect(find.textContaining('当前显示离线缓存'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders an explicit empty state', (tester) async {
    final repository = FakeCatalogRepository(
      catalogFactory: () => Stream.value(testSnapshot(<AnimeSummary>[])),
    );

    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('本期目录为空'), findsOneWidget);
  });

  testWidgets('retries a failed catalog request', (tester) async {
    var attempts = 0;
    final repository = FakeCatalogRepository(
      catalogFactory: () {
        attempts += 1;
        if (attempts == 1) {
          return Stream<CatalogSnapshot<List<AnimeSummary>>>.error(
            const OfflineFailure(),
          );
        }
        return Stream.value(testSnapshot(<AnimeSummary>[testAnimeSummary]));
      },
    );

    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('当前处于离线状态'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('测试动画'), findsOneWidget);
    expect(attempts, 2);
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
      await _pumpPage(tester, FakeCatalogRepository());
      await tester.pumpAndSettle();

      expect(find.text('测试动画'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpPage(WidgetTester tester, FakeCatalogRepository repository) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
      retry: disableProviderRetry,
      child: const MaterialApp(home: CatalogTracerPage()),
    ),
  );
}
