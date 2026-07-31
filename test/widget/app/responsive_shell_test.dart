import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/app/routing/app_router.dart';

import '../../support/test_viewport.dart';

void main() {
  testWidgets('compact layout uses bottom navigation at 200% text scale', (
    tester,
  ) async {
    await configureTestViewport(
      tester,
      size: const Size(390, 844),
      textScaleFactor: 2,
    );
    final router = createMioAniRouter(initialLocation: '/discover');
    addTearDown(router.dispose);

    await tester.pumpWidget(MioAniRoot(router: router));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium layout uses a compact navigation rail', (tester) async {
    await configureTestViewport(tester, size: const Size(800, 600));
    final router = createMioAniRouter(initialLocation: '/discover');
    addTearDown(router.dispose);

    await tester.pumpWidget(MioAniRoot(router: router));
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('expanded layout uses an extended navigation rail', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(1440, 900));
    final router = createMioAniRouter(initialLocation: '/discover');
    addTearDown(router.dispose);

    await tester.pumpWidget(MioAniRoot(router: router));
    await tester.pumpAndSettle();

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(tester.takeException(), isNull);
  });
}
