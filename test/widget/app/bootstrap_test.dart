import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/app/routing/app_router.dart';

void main() {
  testWidgets('bootstrap installs ProviderScope without external I/O', (
    tester,
  ) async {
    final router = createMioAniRouter(initialLocation: '/discover');
    addTearDown(router.dispose);

    await tester.pumpWidget(MioAniRoot(router: router));
    await tester.pump();

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('发现'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('application-level provider retry is disabled', () {
    expect(
      disableProviderRetry(0, StateError('expected test failure')),
      isNull,
    );
  });
}
