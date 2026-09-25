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

  testWidgets('a rendition stands in for a cover that has not arrived', (
    tester,
  ) async {
    final never = Completer<Uint8List>();
    await _pumpImage(
      tester,
      MioImage(imageUrl: uri, previewUrl: _renditionUri, semanticLabel: '海报'),
      overrides: [
        imageBytesProvider(uri).overrideWith((ref) => never.future),
        imageBytesProvider(
          _renditionUri,
        ).overrideWith((ref) async => _transparentPng),
      ],
    );
    await tester.pumpAndSettle();

    // The reader came from a list that was showing this work, so the poster has
    // the picture already: a block where the cover is about to be is the work
    // disappearing at the moment it is handed over.
    expect(_drawnBytes(tester), same(_transparentPng));
    expect(find.byType(MioPlaceholder), findsNothing);
  });

  testWidgets('the full cover takes the frame the rendition was holding', (
    tester,
  ) async {
    final cover = Completer<Uint8List>();
    await _pumpImage(
      tester,
      MioImage(imageUrl: uri, previewUrl: _renditionUri, semanticLabel: '海报'),
      overrides: [
        imageBytesProvider(uri).overrideWith((ref) => cover.future),
        imageBytesProvider(
          _renditionUri,
        ).overrideWith((ref) async => _transparentPng),
      ],
    );
    await tester.pumpAndSettle();
    expect(_drawnBytes(tester), same(_transparentPng));

    cover.complete(_otherPng);
    await tester.pumpAndSettle();

    // Nothing on screen says the full cover arrived: it is the same picture at
    // more pixels, and the frame it lands in was never empty.
    expect(_drawnBytes(tester), same(_otherPng));
    expect(find.byType(MioPlaceholder), findsNothing);
  });
  testWidgets('a band whose cover has not arrived is painted in its colour', (
    tester,
  ) async {
    final cover = Completer<Uint8List>();
    await _pumpImage(
      tester,
      MioImageBackdrop(imageUrl: uri, previewUrl: _renditionUri),
      overrides: [
        imageBytesProvider(uri).overrideWith((ref) => cover.future),
        coverColourProvider(
          _renditionUri,
        ).overrideWith((ref) async => _bandColour),
      ],
    );
    await tester.pumpAndSettle();

    // The page a reader opened is about a work, and the work has a colour even
    // while its cover is on its way: a band left empty is a hole in the page
    // that fills itself in a moment later.
    expect(find.byType(Image), findsNothing);
    expect(_paintedColour(tester), _bandColour);
  });

  testWidgets('the cover resolves into the colour the band stands on', (
    tester,
  ) async {
    final cover = Completer<Uint8List>();
    await _pumpImage(
      tester,
      MioImageBackdrop(imageUrl: uri, previewUrl: _renditionUri),
      overrides: [
        imageBytesProvider(uri).overrideWith((ref) => cover.future),
        coverColourProvider(
          _renditionUri,
        ).overrideWith((ref) async => _bandColour),
      ],
    );
    await tester.pumpAndSettle();
    expect(_paintedColour(tester), _bandColour);

    cover.complete(_transparentPng);
    await tester.pump();
    await tester.pump();

    // The band the cover arrives into is not empty, so this is the band's own
    // colour becoming its own picture rather than a picture appearing out of
    // the page.
    expect(_paintedColour(tester), _bandColour);
    expect(_artOpacity(tester), lessThan(1));

    await tester.pumpAndSettle();
    expect(_artOpacity(tester), 1);
  });

  testWidgets('a band whose cover is already on hand is simply there', (
    tester,
  ) async {
    await _pumpImage(
      tester,
      MioImageBackdrop(imageUrl: uri, previewUrl: _renditionUri),
      overrides: [
        imageMemoryCacheProvider.overrideWithValue(
          ImageMemoryCache()..store(uri, _transparentPng),
        ),
        // Reading these bytes again would fail the test through this.
        imageBytesProvider(uri).overrideWith(
          (ref) => Future<Uint8List>.error(StateError('read again')),
        ),
        coverColourProvider(
          _renditionUri,
        ).overrideWith((ref) async => _bandColour),
      ],
    );
    await tester.pumpAndSettle();

    // A page arrives whole: art this run has already read is drawn as it always
    // was, and is not faded in as though it were still being read.
    expect(find.byType(Image), findsOneWidget);
    expect(_artOpacity(tester), 1);
  });
}

/// The colour the band on screen is painted in, if any.
Color? _paintedColour(WidgetTester tester) {
  final band = find.descendant(
    of: find.byType(MioImageBackdrop),
    matching: find.byType(ColoredBox),
  );
  if (band.evaluate().isEmpty) return null;
  return tester.widget<ColoredBox>(band.first).color;
}

/// How strongly the band's art is drawn: less than one while it is arriving, and
/// one when there is no arriving left to do — a cover drawn where it belongs
/// from the first frame is not wrapped in anything.
double _artOpacity(WidgetTester tester) {
  final fade = find.ancestor(
    of: find.byType(Image),
    matching: find.byType(Opacity),
  );
  if (fade.evaluate().isEmpty) return 1;
  return tester.widget<Opacity>(fade).opacity;
}

final _bandColour = Color(0xff2b6cb0);
Uint8List? _drawnBytes(WidgetTester tester) {
  // A cover is decoded at the width its box asks for, which wraps the bytes in
  // a resize step; the bytes themselves are underneath it.
  var provider = tester.widget<Image>(find.byType(Image)).image;
  if (provider is ResizeImage) provider = provider.imageProvider;
  return provider is MemoryImage ? provider.bytes : null;
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

final _renditionUri = Uri.parse('https://lain.bgm.tv/pic/cover/test-small.png');

final _transparentPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
);

final _otherPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);
