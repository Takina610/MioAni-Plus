import 'package:flutter/material.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// The brand canvas a screen is painted on: [MioColors.background] with the
/// accent's own hue washed across the top.
///
/// It is one flat decoration, so it costs a single paint and never rebuilds
/// while the content above it scrolls. Screens either paint it themselves or
/// leave their `Scaffold` transparent and let the shell's copy show through.
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: MioColors.background,
        gradient: _halo,
      ),
      child: child,
    );
  }
}
