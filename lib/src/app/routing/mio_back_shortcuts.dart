import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

final class MioBackIntent extends Intent {
  const MioBackIntent();
}

class MioBackShortcuts extends StatefulWidget {
  const MioBackShortcuts({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  State<MioBackShortcuts> createState() => _MioBackShortcutsState();
}

class _MioBackShortcutsState extends State<MioBackShortcuts> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'MioBackShortcuts',
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode.canRequestFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
              if (widget.router.canPop()) {
                widget.router.pop();
              }
              return null;
            },
          ),
        },
        child: Focus(focusNode: _focusNode, child: widget.child),
      ),
    );
  }
}
