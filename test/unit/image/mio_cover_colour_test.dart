import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/image/mio_cover_colour.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';

/// The colour a cover is at a glance: the one thing a page can draw while the
/// cover itself is still on its way.
void main() {
  test('a cover of one colour is that colour', () async {
    final bytes = await _cover(const Color(0xff2b6cb0));

    expect(await MioCoverColour.of(bytes), const Color(0xff2b6cb0));
  });

  test('a cover is read as its vivid part, not as its average', () async {
    final bytes = await _cover(
      const Color(0xffff0000),
      and: const Color(0xff000000),
    );

    // A cover is usually mostly dark, and the part a reader would name it after
    // is the part that is not: half black and half red is read as red, rather
    // than as the dark red a plain average of the two would make of it.
    final colour = await MioCoverColour.of(bytes);
    expect(colour, isNotNull);
    expect((colour!.r * 0xff).round(), closeTo(204, 2));
    expect((colour.g * 0xff).round(), 0);
    expect((colour.b * 0xff).round(), 0);
  });

  test('bytes that are not a picture have no colour', () async {
    expect(
      await MioCoverColour.of(Uint8List.fromList(<int>[1, 2, 3, 4])),
      isNull,
    );
  });

  test(
    'the colour of a cover is read from the bytes behind its address',
    () async {
      final rendition = Uri.parse('https://lain.bgm.tv/pic/cover/m/read.png');
      final container = ProviderContainer(
        overrides: [
          imageBytesProvider(
            rendition,
          ).overrideWith((ref) async => _cover(const Color(0xff2b6cb0))),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(coverColourProvider(rendition).future),
        const Color(0xff2b6cb0),
      );
    },
  );
}

/// A sixteen-by-sixteen picture: [colour] down the left half and right half, or
/// [and] down the right half when a two-coloured cover is what the test is
/// about. Sixteen is the width the colour is read at, so the decode is the
/// picture itself rather than a resampling of it.
Future<Uint8List> _cover(Color colour, {Color? and}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 8, 16), Paint()..color = colour);
  canvas.drawRect(Rect.fromLTWH(8, 0, 8, 16), Paint()..color = and ?? colour);
  final image = await recorder.endRecording().toImage(16, 16);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
