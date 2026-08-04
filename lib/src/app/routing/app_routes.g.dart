// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $mioShellRouteData,
  $animeDetailRouteData,
  $characterDetailRouteData,
  $personDetailRouteData,
];

RouteBase get $mioShellRouteData => StatefulShellRouteData.$route(
  factory: $MioShellRouteDataExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/',
          hasOverriddenOnExit: false,
          factory: $HomeRouteData._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/discover',
          hasOverriddenOnExit: false,
          factory: $DiscoverRouteData._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/schedule',
          hasOverriddenOnExit: false,
          factory: $ScheduleRouteData._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/library',
          hasOverriddenOnExit: false,
          factory: $LibraryRouteData._fromState,
        ),
      ],
    ),
  ],
);

extension $MioShellRouteDataExtension on MioShellRouteData {
  static MioShellRouteData _fromState(GoRouterState state) =>
      const MioShellRouteData();
}

mixin $HomeRouteData on GoRouteData {
  static HomeRouteData _fromState(GoRouterState state) => const HomeRouteData();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DiscoverRouteData on GoRouteData {
  static DiscoverRouteData _fromState(GoRouterState state) =>
      const DiscoverRouteData();

  @override
  String get location => GoRouteData.$location('/discover');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ScheduleRouteData on GoRouteData {
  static ScheduleRouteData _fromState(GoRouterState state) =>
      ScheduleRouteData(date: state.uri.queryParameters['date']);

  ScheduleRouteData get _self => this as ScheduleRouteData;

  @override
  String get location => GoRouteData.$location(
    '/schedule',
    queryParams: {if (_self.date != null) 'date': _self.date},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LibraryRouteData on GoRouteData {
  static LibraryRouteData _fromState(GoRouterState state) =>
      const LibraryRouteData();

  @override
  String get location => GoRouteData.$location('/library');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $animeDetailRouteData => GoRouteData.$route(
  path: '/anime/:id',
  hasOverriddenOnExit: false,
  factory: $AnimeDetailRouteData._fromState,
);

mixin $AnimeDetailRouteData on GoRouteData {
  static AnimeDetailRouteData _fromState(GoRouterState state) =>
      AnimeDetailRouteData(id: state.pathParameters['id']!);

  AnimeDetailRouteData get _self => this as AnimeDetailRouteData;

  @override
  String get location =>
      GoRouteData.$location('/anime/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $characterDetailRouteData => GoRouteData.$route(
  path: '/character/:id',
  hasOverriddenOnExit: false,
  factory: $CharacterDetailRouteData._fromState,
);

mixin $CharacterDetailRouteData on GoRouteData {
  static CharacterDetailRouteData _fromState(GoRouterState state) =>
      CharacterDetailRouteData(id: state.pathParameters['id']!);

  CharacterDetailRouteData get _self => this as CharacterDetailRouteData;

  @override
  String get location =>
      GoRouteData.$location('/character/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $personDetailRouteData => GoRouteData.$route(
  path: '/person/:id',
  hasOverriddenOnExit: false,
  factory: $PersonDetailRouteData._fromState,
);

mixin $PersonDetailRouteData on GoRouteData {
  static PersonDetailRouteData _fromState(GoRouterState state) =>
      PersonDetailRouteData(id: state.pathParameters['id']!);

  PersonDetailRouteData get _self => this as PersonDetailRouteData;

  @override
  String get location =>
      GoRouteData.$location('/person/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
