import 'package:flutter/material.dart';

abstract final class MioColors {
  static const Color background = Color(0xFF090C0A);
  static const Color surface = Color(0xFF141914);
  static const Color surfaceHigh = Color(0xFF202720);
  static const Color accent = Color(0xFFB8FF3D);
  static const Color onAccent = Color(0xFF132000);
  static const Color textPrimary = Color(0xFFF2F7F0);
  static const Color textSecondary = Color(0xFFADB8AD);
  static const Color error = Color(0xFFFF7272);
  static const Color warning = Color(0xFFF4CC62);
  static const Color focus = Color(0xFFD9FF8E);
  static const Color outline = Color(0xFF667066);
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
