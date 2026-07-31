import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/routing/mio_back_shortcuts.dart';
import 'package:mio_ani/src/app/theme/mio_ani_theme.dart';
import 'package:mio_ani/src/core/config/app_config.dart';

class MioAniApp extends StatelessWidget {
  const MioAniApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.name,
      debugShowCheckedModeBanner: false,
      theme: MioAniTheme.dark(),
      routerConfig: router,
      builder: (context, child) {
        return MioBackShortcuts(
          router: router,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
