import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/image/image_memory_cache.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';

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

  testWidgets('waits for bytes as a skeleton block, not a spinner', (
    tester,
  ) async {
    final completer = Completer<Uint8List>();
    await _pumpImage(
      tester,
      MioImage(imageUrl: uri, semanticLabel: '海报'),
      overrides: [
        imageBytesProvider(uri).overrideWith((ref) => completer.future),
      ],
    );

    // A cover on its way is drawn as the skeleton block the rest of the app
    // loads with — a grid of spinners is noise, and a poster-sized block of the
    // tile's own colour is a hole in the grid.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('海报：图片加载中'), findsOneWidget);
    expect(find.byType(MioPlaceholder), findsOneWidget);

    completer.complete(_transparentPng);
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(MioPlaceholder), findsNothing);
  });

  testWidgets('a cover waiting for its bytes shimmers like the rest', (
    tester,
  ) async {
    final completer = Completer<Uint8List>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imageBytesProvider(uri).overrideWith((ref) => completer.future),
        ],
        retry: disableProviderRetry,
        child: MaterialApp(
          home: MioSkeletonScope(
            child: Scaffold(
              body: SizedBox.square(
                dimension: 200,
                child: MioImage(imageUrl: uri, semanticLabel: '海报'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('海报：图片加载中'), findsOneWidget);
    // The cover's block is waiting, so the shared sweep is running: a grid of
    // covers arriving is the longest wait a reader sits through.
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    completer.complete(_transparentPng);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('paints a cover this run has already read without asking again', (
    tester,
  ) async {
    final store = ImageMemoryCache()..store(uri, _transparentPng);
    await _pumpImage(
      tester,
      MioImage(imageUrl: uri, semanticLabel: '海报'),
      overrides: [
        imageMemoryCacheProvider.overrideWithValue(store),
        // Reading these bytes again would fail the test through this.
        imageBytesProvider(uri).overrideWith(
          (ref) => Future<Uint8List>.error(StateError('read again')),
        ),
      ],
    );

    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
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
