import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';

void main() {
  testWidgets('bootstrap installs ProviderScope without external I/O', (
    tester,
  ) async {
    await tester.pumpWidget(const MioAniRoot());
    await tester.pump();

    expect(find.byType(ProviderScope), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('MioAni'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('application-level provider retry is disabled', () {
    expect(
      disableProviderRetry(0, StateError('expected test failure')),
      isNull,
    );
  });
}
