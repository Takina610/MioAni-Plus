import 'package:flutter/material.dart';
import 'package:mio_ani/src/shared/design_system/mio_motion.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// The page's small print: the kicker over a title, the label on a fact, the
/// count beside a block heading.
///
/// The reference draws all of these as tracked monospace caps. MioAni keeps its
/// own face — swapping in a monospace family for five labels is a different app
/// — but takes the shape: a size below the body text, a weight heavy enough to
/// hold at that size, and the open tracking that makes two characters read as a
/// label rather than as a word that lost its sentence.
class DetailMicroLabel extends StatelessWidget {
  const DetailMicroLabel(
    this.text, {
    this.color = MioColors.accent,
    this.size = 11,
    super.key,
  });

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // A label is a line: one that wrapped would stop reading as a label and
      // start pushing whatever it names out of the way.
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * 0.12,
        height: 1.2,
      ),
    );
  }
}

/// The fill and the rim of a block that holds something: a fact, a card, a
/// section's worth of them.
///
/// Both are translucent on purpose. A detail page is a stack of these over the
/// header art, and a solid tile turns the art behind it into a hard-edged hole;
/// a wash of the surface colour keeps the page reading as one surface with
/// things on it. [accent] is the same block in the app's own colour, which is
/// what the score and a tag are: the few places a reader's eye should go first.
BoxDecoration detailBlock({bool accent = false, double radius = MioRadii.md}) {
  return BoxDecoration(
    color: accent
        ? MioColors.accent.withValues(alpha: 0.08)
        : MioColors.surface.withValues(alpha: 0.62),
    border: Border.all(
      color: accent
          ? MioColors.accent.withValues(alpha: 0.22)
          : MioColors.outline.withValues(alpha: 0.18),
    ),
    borderRadius: BorderRadius.circular(radius),
  );
}

/// A card arriving with the rest of its batch.
///
/// The reference staggers the items it appends by 28ms each, and the reason is
/// worth keeping: a section that opens onto twelve cards at once reads as a
/// jump cut, while the same twelve arriving in order read as a list filling up.
/// Each card runs the same 340ms rise; [index] only decides when it starts, and
/// the wait is capped so the twentieth card is not still waiting half a second
/// after the first.
class DetailEnter extends StatelessWidget {
  const DetailEnter({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  static const Duration _rise = Duration(milliseconds: 340);
  static const Duration _stagger = Duration(milliseconds: 28);

  /// Last index that still delays its card: past this a batch is long enough
  /// that the tail should be moving with the head.
  static const int _lastStaggered = 10;

  @override
  Widget build(BuildContext context) {
    final delay = _stagger * index.clamp(0, _lastStaggered);
    final total = _rise + delay;
    final duration = MioMotion.resolve(context, total);
    // Reduced motion, or a batch of one: the card is simply there.
    if (duration == Duration.zero || delay == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, _riseOffset * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  /// How far below its place a card starts.
  static const double _riseOffset = 12;
}

/// The panel under the tabs, switched when the reader picks another tab.
///
/// The sections are different lengths, so the page cannot hand the swap to a
/// page view: the panel grows and shrinks with what it holds, and the incoming
/// one rises into place while the outgoing one fades out where it stands.
class DetailSoftSwitch extends StatelessWidget {
  const DetailSoftSwitch({
    required this.panelKey,
    required this.child,
    super.key,
  });

  /// What the panel is of: a new key is what makes the switch a switch.
  final Key panelKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = MioMotion.resolve(context, MioDurations.medium);
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      // A zero duration still runs the layout switch, so the reduced-motion
      // path swaps panels outright rather than cross-fading them.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[...previous, ?current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: panelKey, child: child),
    );
  }
}

/// The tab bar: one recessed track whose held pill travels between the labels.
///
/// The pills are measured out evenly rather than by their text, which is what
/// lets the traveling pill be a single animated box instead of a measurement of
/// every label — and on the window this app runs in, four labels of Chinese
/// measure out evenly anyway.
class DetailPillTabs extends StatelessWidget {
  const DetailPillTabs({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// Inset of the track around the pills, and the height of a pill inside it.
  /// Together they leave a tab the height of the app's other touch targets.
  static const double inset = 4;
  static const double pillHeight = 44;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    final duration = MioMotion.resolve(context, MioDurations.medium);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MioColors.surface.withValues(alpha: 0.72),
        border: Border.all(color: MioColors.outline.withValues(alpha: 0.16)),
        borderRadius: BorderRadius.circular(MioRadii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(inset),
        child: SizedBox(
          height: pillHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth / labels.length;
              return Stack(
                children: <Widget>[
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    left: width * index,
                    top: 0,
                    bottom: 0,
                    width: width,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: MioColors.accent,
                        borderRadius: BorderRadius.circular(MioRadii.sm),
                      ),
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      for (final (position, label) in labels.indexed)
                        Expanded(
                          child: _Pill(
                            label: label,
                            selected: position == index,
                            onTap: () => onChanged(position),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MioRadii.sm),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: MioMotion.resolve(context, MioDurations.short),
              style: TextStyle(
                color: selected ? MioColors.onAccent : MioColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
