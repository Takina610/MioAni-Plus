import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';

void main() {
  final uri = Uri.parse('https://lain.bgm.tv/pic/cover/test.png');

  testWidgets('renders a stable missing-image state', (tester) async {
    await _pumpImage(
      tester,
      const MioImage(imageUrl: null, semanticLabel: '海报'),
    );

    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('海报：暂无图片'), findsOneWidget);
  });

  testWidgets('renders loading and successful byte states', (tester) async {
    final completer = Completer<Uint8List>();
    await _pumpImage(
      tester,
      MioImage(imageUrl: uri, semanticLabel: '海报'),
      overrides: [
        imageBytesProvider(uri).overrideWith((ref) => completer.future),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete(_transparentPng);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('renders a stable provider failure state', (tester) async {
    await _pumpImage(
      tester,
      MioImage(imageUrl: uri, semanticLabel: '海报'),
      overrides: [
        imageBytesProvider(uri).overrideWith(
          (ref) => Future<Uint8List>.error(StateError('expected')),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('海报：图片加载失败'), findsOneWidget);
  });
}

Future<void> _pumpImage(
  WidgetTester tester,
  Widget image, {
  List<Override> overrides = const <Override>[],
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: disableProviderRetry,
      child: MaterialApp(
        home: Scaffold(body: SizedBox.square(dimension: 200, child: image)),
      ),
    ),
  );
}

final _transparentPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
);
