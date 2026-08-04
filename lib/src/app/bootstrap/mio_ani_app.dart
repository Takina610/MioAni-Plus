import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/routing/mio_back_shortcuts.dart';
import 'package:mio_ani/src/app/theme/mio_ani_theme.dart';
import 'package:mio_ani/src/core/config/app_config.dart';
import 'package:mio_ani/src/core/persistence/legacy_migration.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';

class MioAniApp extends ConsumerWidget {
  const MioAniApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick the one-shot Vue migration at bootstrap and surface diagnostics only.
    // C3 does not own library UI; outcomes stay out of feature widgets.
    ref.listen<
      AsyncValue<LegacyMigrationOutcome>
    >(legacyMigrationOutcomeProvider, (previous, next) {
      final outcome = next.asData?.value;
      if (outcome == null) return;
      if (outcome.kind == LegacyMigrationOutcomeKind.failed) {
        debugPrint(
          'MioAni legacy migration failed: ${outcome.diagnosticMessage}',
        );
        return;
      }
      debugPrint(
        'MioAni legacy migration ${outcome.kind.name}'
        '${outcome.fingerprint == null ? '' : ' fingerprint=${outcome.fingerprint}'}'
        ' entries=${outcome.migratedEntries}',
      );
    });
    // Ensure the FutureProvider starts even when no listener fires yet.
    ref.watch(legacyMigrationOutcomeProvider);

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
