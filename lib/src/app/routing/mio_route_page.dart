import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/shared/design_system/mio_motion.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

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
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(opacity: curvedAnimation, child: child);
    },
  );
}
