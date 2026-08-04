import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/routing/app_paths.dart';
import 'package:mio_ani/src/app/routing/mio_route_page.dart';
import 'package:mio_ani/src/app/shell/foundation_pages.dart';
import 'package:mio_ani/src/app/shell/mio_ani_shell.dart';
import 'package:mio_ani/src/app/shell/mio_destination.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_page.dart';
import 'package:mio_ani/src/features/discover/presentation/discover_page.dart';
import 'package:mio_ani/src/features/home/presentation/home_page.dart';
import 'package:mio_ani/src/features/schedule/application/schedule_route_intent.dart';
import 'package:mio_ani/src/features/schedule/presentation/schedule_page.dart';

part 'app_routes.g.dart';

@TypedStatefulShellRoute<MioShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<HomeShellBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<HomeRouteData>(path: AppPaths.home),
      ],
    ),
    TypedStatefulShellBranch<DiscoverShellBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<DiscoverRouteData>(path: AppPaths.discover),
      ],
    ),
    TypedStatefulShellBranch<ScheduleShellBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ScheduleRouteData>(path: AppPaths.schedule),
      ],
    ),
    TypedStatefulShellBranch<LibraryShellBranchData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<LibraryRouteData>(path: AppPaths.library),
      ],
    ),
  ],
)
class MioShellRouteData extends StatefulShellRouteData {
  const MioShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return MioAniShell(navigationShell: navigationShell);
  }
}

class HomeShellBranchData extends StatefulShellBranchData {
  const HomeShellBranchData();
}

class DiscoverShellBranchData extends StatefulShellBranchData {
  const DiscoverShellBranchData();
}

class ScheduleShellBranchData extends StatefulShellBranchData {
  const ScheduleShellBranchData();
}

class LibraryShellBranchData extends StatefulShellBranchData {
  const LibraryShellBranchData();
}

class HomeRouteData extends GoRouteData with $HomeRouteData {
  const HomeRouteData();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const HomePage();
  }
}

class DiscoverRouteData extends GoRouteData with $DiscoverRouteData {
  const DiscoverRouteData();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return DiscoverPage(initialUri: state.uri);
  }
}

class ScheduleRouteData extends GoRouteData with $ScheduleRouteData {
  const ScheduleRouteData({this.date});

  final String? date;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SchedulePage(initialDate: normalizeScheduleDate(date));
  }
}

class LibraryRouteData extends GoRouteData with $LibraryRouteData {
  const LibraryRouteData();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const FoundationDestinationPage(destination: MioDestination.library);
  }
}

@TypedGoRoute<AnimeDetailRouteData>(path: AppPaths.animeDetail)
class AnimeDetailRouteData extends GoRouteData with $AnimeDetailRouteData {
  const AnimeDetailRouteData({required this.id});

  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildMioDetailPage(
      context: context,
      state: state,
      child: AnimeDetailPage(sourceId: id),
    );
  }
}

@TypedGoRoute<CharacterDetailRouteData>(path: AppPaths.characterDetail)
class CharacterDetailRouteData extends GoRouteData
    with $CharacterDetailRouteData {
  const CharacterDetailRouteData({required this.id});

  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildMioDetailPage(
      context: context,
      state: state,
      child: FoundationDetailPage(title: '角色详情', sourceId: id),
    );
  }
}

@TypedGoRoute<PersonDetailRouteData>(path: AppPaths.personDetail)
class PersonDetailRouteData extends GoRouteData with $PersonDetailRouteData {
  const PersonDetailRouteData({required this.id});

  final String id;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildMioDetailPage(
      context: context,
      state: state,
      child: FoundationDetailPage(title: '人物详情', sourceId: id),
    );
  }
}
