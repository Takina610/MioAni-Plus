import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/routing/app_paths.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/app/shell/foundation_pages.dart';

GoRouter createMioAniRouter({String initialLocation = AppPaths.home}) {
  // Every imperative route in MioAni is a generated, path-only public route.
  // Reflecting it in the browser URL preserves ADR 0006/0009 history semantics.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    initialLocation: initialLocation,
    routes: $appRoutes,
    errorBuilder: (context, state) {
      return FoundationNotFoundPage(location: state.uri.toString());
    },
  );
}
