import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_app.dart';
import 'package:mio_ani/src/app/routing/app_router.dart';

Duration? disableProviderRetry(int retryCount, Object error) {
  return null;
}

class MioAniRoot extends StatefulWidget {
  const MioAniRoot({this.router, super.key});

  final GoRouter? router;

  @override
  State<MioAniRoot> createState() => _MioAniRootState();
}

class _MioAniRootState extends State<MioAniRoot> {
  late GoRouter _router;
  late bool _ownsRouter;

  @override
  void initState() {
    super.initState();
    _setRouter(widget.router);
  }

  @override
  void didUpdateWidget(covariant MioAniRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      if (_ownsRouter) {
        _router.dispose();
      }
      _setRouter(widget.router);
    }
  }

  void _setRouter(GoRouter? injectedRouter) {
    _ownsRouter = injectedRouter == null;
    _router = injectedRouter ?? createMioAniRouter();
  }

  @override
  void dispose() {
    if (_ownsRouter) {
      _router.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      retry: disableProviderRetry,
      child: MioAniApp(router: _router),
    );
  }
}
