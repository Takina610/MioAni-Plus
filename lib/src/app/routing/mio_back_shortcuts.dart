import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

final class MioBackIntent extends Intent {
  const MioBackIntent();
}

class MioBackShortcuts extends StatelessWidget {
  const MioBackShortcuts({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): MioBackIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
            MioBackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          MioBackIntent: CallbackAction<MioBackIntent>(
            onInvoke: (intent) {
              if (router.canPop()) {
                router.pop();
              }
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
