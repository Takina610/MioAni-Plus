import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/app/routing/app_router.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/app/routing/mio_back_shortcuts.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';

import '../../support/fake_catalog_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('back shortcuts defer root focus until after layout', (
    tester,
  ) async {
    final router = createMioAniRouter(initialLocation: '/discover');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MioBackShortcuts(router: router, child: const SizedBox.expand()),
      ),
    );

    final shortcutFocus = find.descendant(
      of: find.byType(MioBackShortcuts),
      matching: find.byType(Focus),
    );
    expect(
      tester.widgetList<Focus>(shortcutFocus).where((focus) => focus.autofocus),
      isEmpty,
    );
  });

  testWidgets('four typed branches share a single router stack', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter(initialLocation: '/discover');
    addTearDown(router.dispose);
    final repository = FakeCatalogRepository();

    await tester.pumpWidget(
      MioAniRoot(
        router: router,
        providerOverrides: [
          catalogRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/discover');
    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/discover');

    await tester.tap(find.text('日程'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/schedule');

    await tester.tap(find.text('追番'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/library');
  });

  testWidgets('detail route pushes above a branch and pops back to it', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final router = createMioAniRouter(initialLocation: '/discover');
    addTearDown(router.dispose);
    final repository = FakeCatalogRepository();

    await tester.pumpWidget(
      MioAniRoot(
        router: router,
        providerOverrides: [
          catalogRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    unawaited(
      AnimeDetailRouteData(id: 'bgm-1').push<void>(
        tester.element(find.text('基础外壳已就绪，内容将在后续纵向切片接入。').hitTestable()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('动画详情'), findsOneWidget);
    expect(find.text('测试动画'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/anime/bgm-1');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/discover');
  });

  testWidgets('direct detail links and unknown paths are explicit', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(800, 600));
    final detailRouter = createMioAniRouter(
      initialLocation: '/person/bgm-person-1',
    );
    addTearDown(detailRouter.dispose);

    await tester.pumpWidget(MioAniRoot(router: detailRouter));
    await tester.pumpAndSettle();
    expect(find.text('人物详情'), findsOneWidget);
    expect(find.text('bgm-person-1'), findsOneWidget);

    final notFoundRouter = createMioAniRouter(
      initialLocation: '/does-not-exist',
    );
    addTearDown(notFoundRouter.dispose);
    await tester.pumpWidget(MioAniRoot(router: notFoundRouter));
    await tester.pumpAndSettle();
    expect(find.text('页面不存在'), findsOneWidget);
  });

  testWidgets('desktop shortcuts delegate back navigation to the router', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(1280, 800));
    final router = createMioAniRouter(initialLocation: '/schedule');
    addTearDown(router.dispose);

    await tester.pumpWidget(MioAniRoot(router: router));
    await tester.pumpAndSettle();
    const characterRoute = CharacterDetailRouteData(id: 'bgm-character-1');
    expect(characterRoute.location, '/character/bgm-character-1');
    unawaited(router.push<void>(characterRoute.location));
    await tester.pumpAndSettle();
    expect(find.text('角色详情'), findsOneWidget);
    expect(find.text('bgm-character-1'), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.path,
      '/character/bgm-character-1',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/schedule');
    expect(find.text('角色详情'), findsNothing);

    unawaited(router.push<void>(characterRoute.location));
    await tester.pumpAndSettle();
    expect(find.text('角色详情'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/schedule');
    expect(find.text('角色详情'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/schedule');
  });
}
