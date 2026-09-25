import 'package:flutter/material.dart';

abstract final class MioColors {
  /// Canvas of every screen: a green-black in the accent's own hue rather than
  /// a neutral one, so the dark theme carries the brand even where no accent
  /// is painted. Held dark enough to stay a background behind [textPrimary],
  /// which keeps its AA contrast on it.
  static const Color background = Color(0xFF0D1409);
  static const Color surface = Color(0xFF141914);
  static const Color surfaceHigh = Color(0xFF202720);

  /// Fill of a block standing in for content the page is still reading: a
  /// poster that has not arrived, the rows of a section that has not answered.
  ///
  /// Lighter than every surface the app paints on, so a skeleton reads as a
  /// shape the page is holding open rather than as a hole in it — which is what
  /// a poster-sized block of [surfaceHigh] looked like on a dark grid.
  static const Color skeleton = Color(0xFF2F3A31);

  /// The highlight that sweeps across a waiting block, in the same hue one step
  /// lighter than [skeleton]. Its transparent end lives with the painter.
  static const Color skeletonHighlight = Color(0xFF3D4B40);

  static const Color accent = Color(0xFFB8FF3D);
  static const Color onAccent = Color(0xFF132000);
  static const Color textPrimary = Color(0xFFF2F7F0);
  static const Color textSecondary = Color(0xFFADB8AD);
  static const Color error = Color(0xFFFF7272);
  static const Color warning = Color(0xFFF4CC62);
  static const Color focus = Color(0xFFD9FF8E);
  static const Color outline = Color(0xFF667066);

  /// Ambient halo drawn across the top of [MioBackdrop], in the accent's hue.
  /// A flat near-black canvas reads as unpainted; a wash of the app's own
  /// colour is what makes the dark surface feel like MioAni. Held at a low
  /// alpha so it stays a wash behind the header rather than a band of colour.
  static const Color backdropGlow = Color(0x1FB8FF3D);

  /// The same accent, fully transparent: the far stop of the backdrop halo.
  /// Interpolating to transparent *accent* keeps the fade in the glow's own
  /// hue, where `Colors.transparent` would pull the edge towards black.
  static const Color backdropGlowEnd = Color(0x00B8FF3D);
}

abstract final class MioSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class MioRadii {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 22;
}

abstract final class MioSizes {
  static const double minimumTouchTarget = 48;
  static const double mediumRailWidth = 80;
  static const double expandedRailWidth = 248;
  static const double contentMaxWidth = 1440;
}

abstract final class MioDurations {
  static const Duration short = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 240);
  static const Duration long = Duration(milliseconds: 340);
}
