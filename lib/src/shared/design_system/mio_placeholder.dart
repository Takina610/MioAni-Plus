import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// The shimmer that runs across the app's skeleton blocks.
///
/// One controller drives every block on screen rather than one per block: a
/// grid of placeholders is dozens of blocks, and dozens of tickers to move a
/// highlight is work the page cannot spare. It also runs *only* while a block is
/// actually waiting — a page that has finished loading repaints nothing, and a
/// test that settles on finished content settles at once instead of waiting on
/// an animation that never ends.
///
/// It is installed once, above the app's screens.
class MioSkeletonScope extends StatefulWidget {
  const MioSkeletonScope({required this.child, super.key});

  final Widget child;

  /// The shimmer above [context], or null when the tree has none.
  ///
  /// A block with no scope above it is drawn still rather than animated: the app
  /// installs one, and a screen built on its own — a widget test, a preview —
  /// does not start an endless animation behind the test's back.
  static Animation<double>? maybeOf(BuildContext context) {
    return _registrationOf(context)?.animation;
  }

  static _MioSkeletonRegistration? _registrationOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_MioSkeletonRegistration>();
  }

  @override
  State<MioSkeletonScope> createState() => _MioSkeletonScopeState();
}

class _MioSkeletonScopeState extends State<MioSkeletonScope>
    with SingleTickerProviderStateMixin {
  /// One sweep of the highlight. Long enough to read as a slow wave rather than
  /// a flicker, short enough that a screen does not feel stuck.
  static const Duration _period = Duration(milliseconds: 1400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  /// Blocks waiting on the shimmer right now.
  int _waiting = 0;
  bool _motionAllowed = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A reader who has asked the system for reduced motion gets the blocks
    // without the sweep.
    _motionAllowed = !MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  void _register() {
    _waiting += 1;
    _sync();
  }

  void _unregister() {
    _waiting -= 1;
    assert(_waiting >= 0, 'a skeleton block was released twice');
    _sync();
  }

  void _sync() {
    if (_motionAllowed && _waiting > 0) {
      if (!_controller.isAnimating) _controller.repeat();
      return;
    }
    _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MioSkeletonRegistration(
      animation: _controller,
      register: _register,
      unregister: _unregister,
      child: widget.child,
    );
  }
}

class _MioSkeletonRegistration extends InheritedWidget {
  const _MioSkeletonRegistration({
    required this.animation,
    required this.register,
    required this.unregister,
    required super.child,
  });

  final Animation<double> animation;
  final VoidCallback register;
  final VoidCallback unregister;

  @override
  bool updateShouldNotify(_MioSkeletonRegistration oldWidget) {
    return oldWidget.animation != animation;
  }
}

/// A block of the shape content will take, drawn in place of content that has
/// not arrived: a poster that is still being read, the rows of a section whose
/// answer is on its way.
///
/// This is what the app loads with. Nowhere in MioAni does a screen, a section
/// or a single cover spin: the page stands up in its own shape, the blocks are
/// filled with [MioColors.skeleton], and a highlight sweeps across them while
/// the content is on its way — the one sign of life a page that has nothing to
/// show is allowed. The sweep is shared (see [MioSkeletonScope]) and stops with
/// the last block.
class MioPlaceholder extends StatefulWidget {
  const MioPlaceholder({
    this.width,
    this.height,
    this.radius = MioRadii.md,
    super.key,
  });

  /// A block the width of the space it is given.
  const MioPlaceholder.fill({this.height, this.radius = MioRadii.md, super.key})
    : width = double.infinity;

  /// A block that takes the whole space it is given, both ways: how a poster
  /// holds the frame it will land in.
  const MioPlaceholder.expand({this.radius = MioRadii.md, super.key})
    : width = double.infinity,
      height = double.infinity;

  /// How wide the block is, in logical pixels. Leaving it out means the block
  /// takes the width it is offered, which is what a line standing in for a
  /// paragraph wants — [MioPlaceholderLines] leaves it out for every line but
  /// the last.
  final double? width;
  final double? height;
  final double radius;

  @override
  State<MioPlaceholder> createState() => _MioPlaceholderState();
}

class _MioPlaceholderState extends State<MioPlaceholder> {
  _MioSkeletonRegistration? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A block on a page another page has covered is not waiting for anyone:
    // its route is muted, so it goes off the books — which is also what keeps a
    // stack of loading screens from painting behind the visible one.
    final next = TickerMode.valuesOf(context).enabled
        ? MioSkeletonScope._registrationOf(context)
        : null;
    if (identical(next, _scope)) return;
    _scope?.unregister();
    _scope = next;
    _scope?.register();
  }

  @override
  void dispose() {
    _scope?.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        // A block with no width of its own is as wide as it is allowed to be.
        // The box it goes in constrains it — a column hands it the page width,
        // an `Expanded` hands it a share — where a null width would have left
        // the painted block at zero and the skeleton invisible.
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: CustomPaint(
          painter: _SkeletonPainter(
            radius: widget.radius,
            shimmer: MioSkeletonScope.maybeOf(context),
          ),
        ),
      ),
    );
  }
}

/// Paints the block and runs its highlight across it as a wave.
///
/// The wave is one *period* of a repeating gradient — trough at the block's own
/// colour, crest at [MioColors.skeletonHighlight] — slid across the block, so
/// there is always light on it somewhere and the loop has no seam to see: the
/// pattern is periodic, and a whole cycle moves it by exactly one period, which
/// is a picture of itself. Sweeping a band from one side to the other instead
/// puts the block in the dark at both ends of every cycle, which reads as the
/// light stopping and starting again.
///
/// It paints from the shared animation rather than rebuilding: the offset is a
/// shader moved by the animation's value, so a screen of waiting blocks costs
/// repaints and no widget work at all.
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({required this.radius, required this.shimmer})
    : super(repaint: shimmer);

  final double radius;
  final Animation<double>? shimmer;

  /// Widest the wave's period gets: the length one crest travels before the next
  /// one follows it. A block wider than this carries more than one crest, which
  /// is what a wide poster wants — one light crawling across a 900px hero reads
  /// as a stuck progress bar rather than a shimmer.
  static const double _maximumPeriod = 320;

  /// Narrowest period, so a 40px chip still catches a wave instead of being
  /// washed over whole.
  static const double _minimumPeriod = 96;

  static const List<Color> _waveColors = <Color>[
    MioColors.skeleton,
    MioColors.skeletonHighlight,
    MioColors.skeleton,
  ];

  /// Where the crest sits within the period: mid-way, so the wave is one
  /// smooth rise and fall rather than a pulse with a flat shelf.
  static const double _crest = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final block = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(block, Paint()..color = MioColors.skeleton);

    final shimmer = this.shimmer;
    if (shimmer == null) return;
    // A block carries at least one whole period whatever its width, so there is
    // always a crest on it; a wide poster carries several, so the light crossing
    // it reads as a wave passing rather than one stripe crawling across.
    final period = math.min(
      math.max(size.width * 0.6, _minimumPeriod),
      _maximumPeriod,
    );
    // The gradient is one period wide and slides one period per cycle, so the
    // picture at the end of a cycle is the picture at its start. Tiling carries
    // the wave across the rest of the block.
    final offset = period * shimmer.value;
    canvas.drawRRect(
      block,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _waveColors,
          stops: const <double>[0, _crest, 1],
          tileMode: TileMode.repeated,
        ).createShader(Rect.fromLTWH(-offset, 0, period, size.height)),
    );
  }

  @override
  bool shouldRepaint(_SkeletonPainter oldDelegate) {
    return oldDelegate.radius != radius || oldDelegate.shimmer != shimmer;
  }
}

/// A block of text lines still being read: [lines] bars of [lineHeight], the
/// last one short the way a paragraph ends.
class MioPlaceholderLines extends StatelessWidget {
  const MioPlaceholderLines({
    required this.lines,
    this.lineHeight = 14,
    this.spacing = 8,
    super.key,
  });

  final int lines;
  final double lineHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var index = 0; index < lines; index += 1) ...<Widget>[
            if (index > 0) SizedBox(height: spacing),
            MioPlaceholder(
              width: index == lines - 1 ? 180 : null,
              height: lineHeight,
              radius: MioRadii.sm,
            ),
          ],
        ],
      ),
    );
  }
}
