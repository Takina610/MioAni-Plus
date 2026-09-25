import 'package:flutter/material.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// The brand canvas a screen is painted on: [MioColors.background] with the
/// accent's own hue washed across the top.
///
/// The floor and the wash are two paints, and the floor is opaque: a canvas is
/// what everything else on the screen stands on, so a screen that moves its
/// canvas over another screen — the detail page arriving as a drawer over the
/// list — has to be bringing a floor with it, not a wash with the list showing
/// through. (One [BoxDecoration] carrying both would not do: a gradient is a
/// paint shader, and a paint with a shader ignores its own colour, so the canvas
/// would be exactly as solid as its transparent-to-almost-nothing wash.)
///
/// It is still flat and still free to rebuild: two paints, drawn once, and
/// nothing here reads anything that scrolls under it. Screens either paint it
/// themselves or leave their `Scaffold` transparent and let the shell's copy
/// show through.
class MioBackdrop extends StatelessWidget {
  const MioBackdrop({required this.child, super.key});

  final Widget child;

  /// The halo is anchored above the top edge and reaches a little past the
  /// width, so a phone keeps a soft band of brand colour across its header
  /// instead of a visible disc.
  static const RadialGradient _halo = RadialGradient(
    center: Alignment(0, -1.05),
    radius: 1.15,
    colors: <Color>[MioColors.backdropGlow, MioColors.backdropGlowEnd],
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MioColors.background,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: _halo),
        child: child,
      ),
    );
  }
}
