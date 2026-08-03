import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/app/routing/app_router.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';

import '../test/support/fake_catalog_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('catalog opens a typed detail and returns to the same branch', (
    tester,
  ) async {
    // Some MIUI/device sessions report a landscape-like test view surface even
    // while the physical display is portrait. Force a compact portrait surface
    // so catalog cards stay hittable under integration_test.
    await tester.binding.setSurfaceSize(const Size(392, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCatalogRepository();
    final router = createMioAniRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MioAniRoot(
        router: router,
        providerOverrides: [
          catalogRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final catalogTitle = find.text('测试动画');
    expect(catalogTitle, findsOneWidget);
    await tester.ensureVisible(catalogTitle);
    await tester.pumpAndSettle();
    await tester.tap(catalogTitle);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/anime/bgm-1');
    expect(find.text('动画详情'), findsOneWidget);
    expect(find.text('用于确定性测试的动画详情。'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(find.text('测试动画'), findsOneWidget);
    expect(repository.catalogCalls, 1);
  });
}
