import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// The lists a cover stands on, each named for the tag its cards carry.
///
/// A tag has to name one picture on screen, not one work: the home page can be
/// showing the same work in its carousel, its season grid and its feed at once,
/// and a branch behind it can be showing it again. The place is what keeps two
/// pictures of one work from claiming the same tag.
abstract final class AnimeCoverPlace {
  static const String homeHero = 'home-hero';
  static const String homeSeason = 'home-season';
  static const String homeExplore = 'home-explore';
  static const String discover = 'discover';
}

/// The tag a work's cover carries on [place].
///
/// A list offers a work once, so this names one card on screen; the detail page
/// draws its poster under the tag the tapped card was carrying, which is what
/// makes those two widgets the ends of one flight.
String animeCoverTag({required String place, required AnimeSourceId id}) {
  return 'anime-cover/$place/${id.value}';
}

/// One picture on its way from a list to the detail page.
///
/// A tap carries an id and nothing else, so the page it opens is told about the
/// list twice over: what the list knew goes through the preview store, and the
/// picture itself goes through here — the bytes the card was already drawing,
/// the shape its corners were in, and the tag that pairs the card with the
/// poster it lands on.
final class AnimeCoverFlight {
  AnimeCoverFlight._({
    required this.tag,
    required this.animeId,
    required this.coverUri,
    required this.radius,
  });

  /// The picture as a list tile draws it: the rendition the source publishes
  /// for lists, which is what the tile was showing.
  factory AnimeCoverFlight.tile({
    required AnimeSummary anime,
    required String place,
    double radius = MioRadii.md,
  }) {
    return AnimeCoverFlight._(
      tag: animeCoverTag(place: place, id: anime.id),
      animeId: anime.id.value,
      coverUri: anime.thumbnailUrl ?? anime.imageUrl,
      radius: radius,
    );
  }

  /// The picture as the hero carousel draws it, which is the full-size cover.
  factory AnimeCoverFlight.cover({
    required AnimeSummary anime,
    required String place,
    double radius = MioRadii.lg,
  }) {
    return AnimeCoverFlight._(
      tag: animeCoverTag(place: place, id: anime.id),
      animeId: anime.id.value,
      coverUri: anime.imageUrl,
      radius: radius,
    );
  }

  /// What the two ends of this flight match on.
  final String tag;

  /// The work the flight belongs to. A detail page only lands the flight that
  /// is about the work it is drawing.
  final String animeId;

  /// The picture in the air. A work the source has no cover for has nothing to
  /// fly, so both ends draw themselves and no flight is started.
  final Uri? coverUri;

  /// The corner radius the picture had the moment it left the list.
  final double radius;
}

/// The cover the reader last tapped, waiting for the page that will land on it.
///
/// One slot rather than a map, because a tap replaces whatever the last one
/// left and a detail page reads it once. The last cover is kept rather than
/// cleared on the way out: a work opened from a row that has no picture of its
/// own still flies from the list that is showing one.
final class AnimeCoverFlightStore {
  AnimeCoverFlight? _latest;

  AnimeCoverFlight? get latest => _latest;

  /// Begins a flight from [cover], replacing whatever was in the air before.
  void begin(AnimeCoverFlight cover) => _latest = cover;

  /// The flight a detail page for [animeId] should land, or null when the last
  /// cover a reader tapped belongs to some other work.
  AnimeCoverFlight? forAnime(String animeId) {
    final cover = _latest;
    return cover != null && cover.animeId == animeId ? cover : null;
  }
}

final animeCoverFlightStoreProvider = Provider<AnimeCoverFlightStore>((ref) {
  return AnimeCoverFlightStore();
});

/// The cover of a work on a page a reader can open: the picture flies from
/// here to the detail page's poster.
///
/// It draws the work exactly as the card around it would have, so a card is
/// free to put it in whatever shape it wants; what it adds is the tag the
/// flight matches on, and the shape the picture has while it is away.
class AnimeCoverSource extends StatelessWidget {
  const AnimeCoverSource({
    required this.flight,
    required this.semanticLabel,
    super.key,
  });

  final AnimeCoverFlight flight;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final uri = flight.coverUri;
    final picture = MioImage(
      imageUrl: uri,
      semanticLabel: semanticLabel,
      borderRadius: flight.radius,
    );
    if (uri == null) return picture;
    return Hero(
      tag: flight.tag,
      // A back gesture is a reader taking the page back by hand, and the
      // picture has to fly home for it like any other way back. A gesture only
      // picks up the ends that say they are willing.
      transitionOnUserGestures: true,
      createRectTween: _straightLine,
      curve: _evenPace,
      flightShuttleBuilder: _coverFlightShuttle,
      child: _CoverPicture(uri: uri, radius: flight.radius, child: picture),
    );
  }
}

/// The poster of a detail page: where the cover a reader tapped lands.
///
/// Which cover that is belongs to the tap and not to the page, so it is read
/// once, as the page is built, and kept: a reader who opens a related work from
/// this page must not move this page's poster.
class AnimeCoverDestination extends ConsumerStatefulWidget {
  const AnimeCoverDestination({
    required this.animeId,
    required this.child,
    this.radius = MioRadii.md,
    super.key,
  });

  /// The work this page is about.
  final String animeId;

  /// The poster, drawn by the page.
  final Widget child;

  /// Corner radius of the poster frame the picture lands in.
  final double radius;

  @override
  ConsumerState<AnimeCoverDestination> createState() =>
      _AnimeCoverDestinationState();
}

class _AnimeCoverDestinationState extends ConsumerState<AnimeCoverDestination> {
  AnimeCoverFlight? _flight;

  @override
  void initState() {
    super.initState();
    _flight = ref.read(animeCoverFlightStoreProvider).forAnime(widget.animeId);
  }

  @override
  Widget build(BuildContext context) {
    final flight = _flight;
    if (flight == null || flight.coverUri == null) return widget.child;
    return Hero(
      tag: flight.tag,
      transitionOnUserGestures: true,
      createRectTween: _straightLine,
      curve: _evenPace,
      flightShuttleBuilder: _coverFlightShuttle,
      child: _CoverPicture(
        uri: flight.coverUri,
        radius: widget.radius,
        child: widget.child,
      ),
    );
  }
}

/// The picture travels in a straight line.
///
/// [MaterialApp] hands its [HeroController] a `MaterialRectArcTween`, which
/// swings a picture between two boxes of different shapes along a curve. A
/// reader watching a poster they tapped does not see an arc: they see it cross
/// the screen to the frame it belongs in, and anything else reads as the picture
/// wandering on the way.
RectTween _straightLine(Rect? begin, Rect? end) {
  return RectTween(begin: begin, end: end);
}

/// and it travels at one pace: every frame of the flight covers the same part of
/// the way, so the picture is never speeding up or settling as it arrives.
const Curve _evenPace = Curves.linear;

/// The picture taking part in a flight, and the shape it is flying in.
///
/// The flight draws its own copy between the two ends, and that copy needs what
/// the ends know: which picture it is (the tapped list's, whose bytes the card
/// has already drawn, so the flight never shows a cover arriving as a block)
/// and how round its corners are at each end. Both are read from here rather
/// than carried along the route, so a card is the only widget that has to know
/// it is a card.
class _CoverPicture extends StatelessWidget {
  const _CoverPicture({
    required this.uri,
    required this.radius,
    required this.child,
  });

  final Uri? uri;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// The picture a flight is drawing, named so that a test can measure where the
/// flight has got to. Nothing on screen reads it.
@visibleForTesting
const Key animeCoverFlightKey = ValueKey<String>('anime-cover-in-flight');

/// Draws the picture while it is between the two pages.
///
/// [Hero] would hand its own shuttle the destination's widget — the poster,
/// which is measured again at every size the flight passes through and decodes
/// its cover again on the way. This draws the bytes the tapped list was already
/// showing, decoded once at the widest size the flight reaches, and walks the
/// corners from the shape the picture left in to the shape it lands in.
Widget _coverFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final source = _pictureOf(fromHeroContext);
  final landing = _pictureOf(toHeroContext);
  if (source == null) return _landingPicture(toHeroContext);

  return Consumer(
    key: animeCoverFlightKey,
    builder: (context, ref, _) {
      final cache = ref.watch(imageMemoryCacheProvider);
      final sourceUri = source.uri;
      final landingUri = landing?.uri;
      final bytes =
          (sourceUri == null ? null : cache.read(sourceUri)) ??
          (landingUri == null ? null : cache.read(landingUri));
      if (bytes == null) return _landingPicture(toHeroContext);
      final left = BorderRadius.circular(source.radius);
      final landed = BorderRadius.circular(landing?.radius ?? source.radius);
      // Where the picture is between the two boxes: the flight's own animation
      // runs from the one it is leaving towards the one it is landing in on the
      // way out of a page, and the other way round on the way in, so the corners
      // are read off it facing the same way the picture is travelling.
      final way = direction == HeroFlightDirection.pop
          ? 1 - animation.value
          : animation.value;
      return AnimatedBuilder(
        animation: animation,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          cacheWidth: _shuttleDecodeWidth(
            flightContext,
            fromHeroContext,
            toHeroContext,
          ),
          gaplessPlayback: true,
          // The flight is the same picture the reader just tapped and the same
          // one it is landing on: the ends already carry its name for anyone
          // listening, and a third announcement in the middle of a gesture is
          // noise.
          excludeFromSemantics: true,
        ),
        builder: (context, child) => ClipRRect(
          borderRadius: BorderRadius.lerp(left, landed, way) ?? left,
          child: child,
        ),
      );
    },
  );
}

/// The picture [heroContext] is carrying, when it is one of ours.
_CoverPicture? _pictureOf(BuildContext heroContext) {
  final hero = heroContext.widget;
  final child = hero is Hero ? hero.child : null;
  return child is _CoverPicture ? child : null;
}

/// What flies when the picture itself cannot be drawn: the widget the flight
/// was already going to land on, in the arc the framework would have given it.
Widget _landingPicture(BuildContext toHeroContext) {
  final hero = toHeroContext.widget;
  return hero is Hero ? hero.child : const SizedBox.shrink();
}

/// Physical width to decode the flying picture at: the widest box it is drawn
/// in at either end, so the flight is never softer than the pages it joins, and
/// never decodes more pixels than those pages could have shown.
int? _shuttleDecodeWidth(
  BuildContext flightContext,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final widths = <double>[
    for (final context in <BuildContext>[fromHeroContext, toHeroContext])
      if (context.findRenderObject() case final RenderBox box when box.hasSize)
        box.size.width,
  ];
  if (widths.isEmpty) return null;
  return MioImage.decodeWidthFor(flightContext, widths.reduce(math.max));
}
