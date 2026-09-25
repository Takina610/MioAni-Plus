import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/discover/application/discover_providers.dart';
import 'package:mio_ani/src/features/discover/presentation/discover_page.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';

import '../../support/fake_discover_repository.dart';

void main() {
  testWidgets('loads a default listing when the page opens', (tester) async {
    final repository = FakeDiscoverRepository();

    await _pumpDiscoverPage(tester, repository);
    await tester.pumpAndSettle();

    expect(repository.fetchPageCalls, 1);
    expect(find.text('测试动画'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing a keyword searches and renders the results', (
    tester,
  ) async {
    final repository = FakeDiscoverRepository();

    await _pumpDiscoverPage(tester, repository);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Naruto');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repository.lastQuery?.keyword, 'Naruto');
    expect(repository.fetchPageCalls, greaterThanOrEqualTo(2));
    expect(find.text('测试动画'), findsOneWidget);
    expect(find.text('没有找到作品'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing search shows the failure view instead of empty', (
    tester,
  ) async {
    final repository = FakeDiscoverRepository(failure: const OfflineFailure());

    await _pumpDiscoverPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('没有找到作品'), findsNothing);
    expect(find.text('重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a search in flight stands up as the grid it will be', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = FakeDiscoverRepository(pageGate: gate);

    await _pumpDiscoverPage(tester, repository);
    await tester.pump();

    // Nothing spins while the search runs: the results grid is already there,
    // holding the shape of the cards that are coming.
    expect(find.byType(MioPlaceholder), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('正在搜索'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('测试动画'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.byType(MioPlaceholder),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a page on its way is drawn as the cards it will bring', (
    tester,
  ) async {
    final repository = FakeDiscoverRepository(hasMore: true);

    await _pumpDiscoverPage(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('测试动画'), findsOneWidget);

    // The second page is held open, so the grid has to stand for it.
    repository.pageGate = Completer<void>();
    await tester.ensureVisible(find.text('加载更多'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('加载更多'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('正在加载更多…'), findsOneWidget);
    expect(find.byType(MioPlaceholder), findsWidgets);

    repository.pageGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDiscoverPage(
  WidgetTester tester,
  FakeDiscoverRepository repository,
) async {
  final router = GoRouter(
    initialLocation: '/discover',
    routes: <RouteBase>[
      GoRoute(
        path: '/discover',
        builder: (context, state) => DiscoverPage(initialUri: state.uri),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [discoverRepositoryProvider.overrideWithValue(repository)],
      retry: disableProviderRetry,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}
