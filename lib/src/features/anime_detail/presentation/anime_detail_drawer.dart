import 'package:flutter/material.dart';
import 'package:mio_ani/src/shared/design_system/mio_backdrop.dart';
import 'package:mio_ani/src/shared/design_system/mio_motion.dart';

/// The way the detail page arrives: as a drawer, from below.
///
/// A reader taps a poster to open a work, and the picture they tapped is already
/// on its way to the frame this page keeps for it — so the page arrives *around*
/// that frame rather than over it. Its canvas and its words come up from below
/// the fold together, as one piece sliding up over the list, and the frame the
/// picture lands in stays where it is: the picture is moving, the page is
/// arriving, and neither waits for the other.
///
/// The same drawer takes the page back: the page sinks away over the list on the
/// way out, and every piece of it goes down together — see
/// [AnimeDetailDrawerHold], which is what the frame the picture lands in and the
/// way out of the page are wrapped in.
///
/// Nothing here fades. A page that arrives at half strength reads as one screen
/// dissolving into another, which is the one thing a reader who tapped a work is
/// not being told: the work is on screen the whole time, and the page about it
/// comes up underneath it.
class AnimeDetailDrawer extends StatefulWidget {
  const AnimeDetailDrawer({required this.child, super.key});

  /// Everything the page draws, over the canvas this arrives on.
  final Widget child;

  /// The drawer in place: what a page reads when there is no entrance to ride —
  /// a reader who asked the platform for no animation, or a page drawn some
  /// other way than through its route. The page is simply there.
  static const Animation<double> _inPlace = AlwaysStoppedAnimation<double>(1);

  /// How far below where it belongs the drawer starts: one window, which puts
  /// the page's own top edge — the art band above the words — exactly at the
  /// fold for the first frame, so a reader keeps looking at the list they tapped
  /// in until the page starts to come up over it.
  static double riseOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  @override
  State<AnimeDetailDrawer> createState() => _AnimeDetailDrawerState();
}

class _AnimeDetailDrawerState extends State<AnimeDetailDrawer> {
  Animation<double> _entrance = AnimeDetailDrawer._inPlace;

  /// Whether the page is on its way out. Read by the pieces that hold their
  /// place for the flight while the page arrives: a piece of the page that is
  /// leaving has no flight left to receive, and goes with the rest of it.
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entrance = _entranceOf(context);
    if (entrance == _entrance) return;
    _entrance.removeStatusListener(_handleStatus);
    _entrance = entrance;
    _entrance.addStatusListener(_handleStatus);
    _leaving = _isLeaving(entrance.status);
  }

  @override
  void dispose() {
    _entrance.removeStatusListener(_handleStatus);
    super.dispose();
  }

  /// The page's own entrance, driven by the route. A page with no route of its
  /// own — or one whose reader asked the platform for no animation — is simply
  /// there, and stays.
  Animation<double> _entranceOf(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || MioMotion.isDisabled(context)) {
      return AnimeDetailDrawer._inPlace;
    }
    return route.animation ?? AnimeDetailDrawer._inPlace;
  }

  /// Whether the page is leaving: a way back that is not the reader's hand runs
  /// the page's own entrance backwards.
  static bool _isLeaving(AnimationStatus status) {
    return status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed;
  }

  void _handleStatus(AnimationStatus status) {
    final leaving = _isLeaving(status);
    if (leaving == _leaving) return;
    setState(() => _leaving = leaving);
  }

  @override
  Widget build(BuildContext context) {
    return _AnimeDetailDrawerScope(
      animation: _entrance,
      leaving: _leaving,
      rise: AnimeDetailDrawer.riseOf(context),
      child: Stack(
        children: <Widget>[
          // The canvas the page is painted on rides the drawer like the words
          // do: it is what comes up over the list, so what a reader watches is
          // the page arriving rather than the list being taken away.
          Positioned.fill(
            child: AnimeDetailDrawerGroup(
              child: const MioBackdrop(child: SizedBox.expand()),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }
}

/// One piece of the page, riding the drawer.
///
/// A piece is anything the page draws on its way in: the canvas, the head's
/// names and lead, the record, the tabs and the sections under them. They ride
/// one motion rather than arriving one at a time as each is read, which is what
/// makes the page arrive as one page. The frame the tapped picture lands in is
/// the one thing on the page that a flight is heading for, and it holds its place
/// for that flight instead — see [AnimeDetailDrawerHold], which is what it and
/// the way out of the page are wrapped in.
///
/// The travel only moves what is drawn: a piece keeps the place the page laid it
/// out in, so anything the reader does the moment the drawer settles — a tap, a
/// scroll, a drag — lands where the layout always said it was.
class AnimeDetailDrawerGroup extends StatelessWidget {
  const AnimeDetailDrawerGroup({required this.child, super.key});

  final Widget child;

  /// The drawer settles: most of the travel is spent getting the page up over
  /// the fold, and the last of it is the landing. A page on its way out reads
  /// the same curve backwards, so it leaves slow and drops away.
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final scope = _AnimeDetailDrawerScope.maybeOf(context);
    if (scope == null || scope.rise == 0) return child;
    return _DrawerRise(
      animation: scope.animation,
      rise: scope.rise,
      child: child,
    );
  }
}

/// A piece of the page that is only a piece on the way out.
///
/// The frame a tapped picture lands in has to hold the place the page laid it
/// out in for as long as the picture is in the air: a target that moved would
/// have the picture chasing it, and the picture is the one thing a reader is
/// following. So while the page is arriving — and once it has arrived and is
/// standing still — this draws exactly where the layout put it, as if there were
/// no entrance at all.
///
/// The way back out has no flight to receive. A piece that held its place there
/// would be left standing over the list it was opened from — a poster frame with
/// nothing in it, hanging over the grid while the page it belongs to is already
/// gone — and then taken away in a single frame when the route is removed, which
/// is what a reader sees as the screen flashing. So on the way out this rides
/// the drawer like everything else the page draws, and is off the screen with it.
class AnimeDetailDrawerHold extends StatelessWidget {
  const AnimeDetailDrawerHold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = _AnimeDetailDrawerScope.maybeOf(context);
    if (scope == null || scope.rise == 0) return child;
    return _DrawerRise(
      // The drawer that is already in place: a held piece rides that one while
      // the page is arriving, and the page's own once the page is leaving.
      animation: scope.leaving ? scope.animation : AnimeDetailDrawer._inPlace,
      rise: scope.rise,
      child: child,
    );
  }
}

/// The drawer's own motion, read by the pieces of the page that ride it.
class _AnimeDetailDrawerScope extends InheritedWidget {
  const _AnimeDetailDrawerScope({
    required this.animation,
    required this.leaving,
    required this.rise,
    required super.child,
  });

  /// The page's own entrance, driven by the route: it is over when the route has
  /// settled, and a way back runs it backwards.
  final Animation<double> animation;

  /// Whether the page is on its way out, and with it everything the page draws
  /// that would otherwise hold its place.
  final bool leaving;

  /// How far below its place the drawer starts, in logical pixels.
  final double rise;

  static _AnimeDetailDrawerScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AnimeDetailDrawerScope>();
  }

  @override
  bool updateShouldNotify(_AnimeDetailDrawerScope oldWidget) {
    return oldWidget.animation != animation ||
        oldWidget.leaving != leaving ||
        oldWidget.rise != rise;
  }
}

/// [child] drawn [rise] pixels below its place, for as much of the drawer as is
/// still to travel.
class _DrawerRise extends StatelessWidget {
  const _DrawerRise({
    required this.animation,
    required this.rise,
    required this.child,
  });

  final Animation<double> animation;
  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          rise * (1 - AnimeDetailDrawerGroup._curve.transform(animation.value)),
        ),
        child: child,
      ),
    );
  }
}
