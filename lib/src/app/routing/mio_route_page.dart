import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/shared/design_system/mio_motion.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// How a page about a work opens over the list it was tapped in.
///
/// The page itself does not fade and does not slide as one piece. Both would put
/// the list and the page on screen at once as two pictures of the same thing,
/// and the reader's eye would be asked to sort out which one it is following. So
/// the route only carries the time: the picture the reader tapped flies on it,
/// and the page comes up from the bottom edge of its own accord, as a drawer the
/// detail page draws around the frame that picture is landing in.
///
/// The duration is what the flight has to work with, which is why it is the
/// page's own motion rather than nothing at all.
Page<void> buildMioDetailPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final duration = MioMotion.resolve(context, MioDurations.medium);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
  );
}
