import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The colour a cover is, at a glance.
///
/// A page that wants a cover's presence before its pixels have nothing to draw
/// with: a byte list is a picture, and a picture is not a colour. This reads one
/// out of it — the smallest decode that still carries the cover's own colours,
/// averaged with the vivid pixels counted for more than the quiet ones, because
/// a cover is usually mostly dark and the part a reader would name it after is
/// the part that is not.
abstract final class MioCoverColour {
  /// Width the cover is decoded at to be read. Enough pixels that the colour is
  /// the picture's rather than the compression's, few enough that reading it
  /// costs less than drawing it.
  static const int _sampleWidth = 16;

  /// How much a pixel counts towards the colour: a quiet pixel still counts,
  /// and a vivid one counts for more.
  static const double _quietShare = 0.25;

  /// The colour of the cover in [bytes], or null when they do not decode — a
  /// cover that cannot be read has no colour to give, and the caller drawing it
  /// has the picture's own failure to show instead.
  static Future<Color?> of(Uint8List bytes) async {
    final image = await _sample(bytes);
    if (image == null) return null;
    try {
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return pixels == null ? null : _average(pixels);
    } finally {
      image.dispose();
    }
  }

  /// The cover in [bytes], decoded down to [_sampleWidth] pixels across.
  static Future<ui.Image?> _sample(Uint8List bytes) async {
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes, targetWidth: _sampleWidth);
      final frame = await codec.getNextFrame();
      return frame.image;
    } on Object catch (_) {
      // Bytes that are not a picture: the band is decoration, and decoration
      // that cannot be read draws nothing at all.
      return null;
    } finally {
      codec?.dispose();
    }
  }

  /// The one colour that stands for every pixel in [pixels].
  static Color _average(ByteData pixels) {
    var red = 0.0;
    var green = 0.0;
    var blue = 0.0;
    var share = 0.0;
    for (var offset = 0; offset + 3 < pixels.lengthInBytes; offset += 4) {
      final r = pixels.getUint8(offset).toDouble();
      final g = pixels.getUint8(offset + 1).toDouble();
      final b = pixels.getUint8(offset + 2).toDouble();
      final alpha = pixels.getUint8(offset + 3) / 0xff;
      if (alpha == 0) continue;
      final weight = alpha * _shareOf(r, g, b);
      red += r * weight;
      green += g * weight;
      blue += b * weight;
      share += weight;
    }
    if (share == 0) return const Color(0x00000000);
    return Color.fromARGB(
      0xff,
      (red / share).round(),
      (green / share).round(),
      (blue / share).round(),
    );
  }

  /// How much a pixel counts: a flat pixel counts [_quietShare] of itself, and
  /// the rest is the pixel's own vividness — how far its strongest channel is
  /// from its weakest, which is the part of a cover a reader remembers.
  static double _shareOf(double red, double green, double blue) {
    final high = math.max(red, math.max(green, blue));
    final low = math.min(red, math.min(green, blue));
    final vividness = high == 0 ? 0.0 : (high - low) / high;
    return _quietShare + (1 - _quietShare) * vividness;
  }
}
