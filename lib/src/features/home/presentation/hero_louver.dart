import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The box the slides stand on, from its left edge to its right one. Named so
/// the strip has an address: everything the louver does happens inside it.
const Key heroStripKey = Key('home-hero-strip');

/// Geometry of the home hero louver, kept from the reference home carousel:
/// one landscape card in the middle of the strip, with the neighbouring cards
/// showing through as a narrow slat on either side.
///
/// The reference never re-lays out a card for its slat; the card always keeps
/// its size and the slat is a window onto the middle of it. [HeroWindowClipper]
/// is that window, and the metrics here say how wide it is and where the card
/// has to sit for the slat to land on the strip edge.
///
/// A drag moves the strip one slice at a time rather than one page at a time,
/// so the card slides and resizes continuously: nothing on the strip drops out
/// or pops back in.
///
/// The strip lays every slide out at its slice, rather than scrolling one long
/// row and clipping it: a card the strip has scrolled aside is still on it, and
/// has to keep being drawn while any part of it is, which a lazily built pager
/// cannot promise for a slide narrower than a page.
///
/// Callers pass the width the strip actually receives, so one silhouette holds
/// from compact phones up to wide windows.
final class HeroLouverMetrics {
  const HeroLouverMetrics({
    required this.cardWidth,
    required this.cardHeight,
    required this.slatWidth,
    required this.gap,
    required this.pageWidth,
  });

  /// Metrics for a strip [available] logical pixels wide.
  factory HeroLouverMetrics.forWidth(double available) {
    final width = math.max(available, _minimumStripWidth);
    // The card takes its preferred width and the two slats grow into the
    // slack; only when the window is too narrow for that does the card give
    // way, so the slats never fall below their minimum.
    final slatWidth = clampDouble(
      (width - _preferredCardWidth - 2 * _gap) / 2,
      _minimumSlatWidth,
      _maximumSlatWidth,
    );
    final cardWidth = clampDouble(
      math.min(_preferredCardWidth, width - 2 * (slatWidth + _gap)),
      _minimumCardWidth,
      _preferredCardWidth,
    );
    final strip = cardWidth + 2 * (slatWidth + _gap);
    final pageWidth = math.min(strip, width);
    return HeroLouverMetrics(
      cardWidth: cardWidth,
      cardHeight: _cardHeight,
      slatWidth: slatWidth,
      gap: _gap,
      pageWidth: pageWidth,
    );
  }

  /// Card width in the reference, and the height shared by cards and slats.
  static const double _preferredCardWidth = 300;
  static const double _cardHeight = 213;

  /// Window widths the reference keeps for a neighbour: never narrower than the
  /// smallest slat, never wider than the largest, with the strip centred in
  /// whatever the window has left over.
  static const double _minimumSlatWidth = 40;
  static const double _maximumSlatWidth = 56;

  /// Space between the card and the slats flanking it.
  static const double _gap = 8;

  /// Floor for corner cases so the strip can never ask for a negative card.
  static const double _minimumCardWidth = 120;
  static const double _minimumStripWidth =
      _minimumCardWidth + 2 * (_minimumSlatWidth + _gap);

  final double cardWidth;
  final double cardHeight;
  final double slatWidth;
  final double gap;

  /// Width of the strip the slides stand on: the card plus both slats when the
  /// window can hold them, otherwise the whole window.
  final double pageWidth;

  /// Distance between two neighbouring slices of the strip: from the centred
  /// card to the slat beside it. A drag carries the strip one of these per
  /// slide, so the strip is measured in slices rather than in widths.
  double get sliceSpacing => (pageWidth - slatWidth) / 2;

  /// Where the window of a slide [distance] slices out from the centred one
  /// stands, as a distance from the strip's left edge: dead centre for the
  /// centred card, half a slat from the edge once it is a settled neighbour.
  double windowCenterFor(double distance) {
    return pageWidth / 2 + distance * sliceSpacing;
  }

  /// How centred a slide is: `1` in the middle of the strip, `0` once it has
  /// scrolled fully aside.
  double focusFor(double distance) => clampDouble(1 - distance.abs(), 0, 1);

  /// Width of the window a slide [distance] pages away from the centred one
  /// shows through: the whole card at the centre, a bare slat once it has
  /// scrolled fully aside.
  double windowWidthFor(double distance) {
    return slatWidth + (cardWidth - slatWidth) * focusFor(distance);
  }
}

/// Shows a hero card through the window the louver has room for: the middle
/// band of an always full-size card, rounded by [radius], so a narrow slat
/// reads as a slat of the same card rather than a squeezed copy of it.
final class HeroWindowClipper extends CustomClipper<RRect> {
  const HeroWindowClipper({required this.windowWidth, required this.radius});

  final double windowWidth;

  /// Corner radius of the window, clamped to the window's own size so a slat
  /// narrows towards a capsule the way the reference clamps its item shape.
  final double radius;

  @override
  RRect getClip(Size size) {
    final width = clampDouble(windowWidth, 0, size.width);
    return RRect.fromRectAndRadius(
      Rect.fromLTWH((size.width - width) / 2, 0, width, size.height),
      Radius.circular(clampDouble(radius, 0, math.min(width, size.height) / 2)),
    );
  }

  @override
  bool shouldReclip(HeroWindowClipper oldClipper) {
    return oldClipper.windowWidth != windowWidth || oldClipper.radius != radius;
  }
}
