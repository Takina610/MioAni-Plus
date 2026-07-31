import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/shell/mio_destination.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

class MioAniShell extends StatelessWidget {
  const MioAniShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final windowClass = MioBreakpoints.windowClassFor(constraints.maxWidth);
        if (windowClass == MioWindowClass.compact) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _selectDestination,
              destinations: [
                for (final destination in MioDestination.values)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    label: destination.label,
                  ),
              ],
            ),
          );
        }

        final extended = windowClass == MioWindowClass.expanded;
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: extended,
                minWidth: MioSizes.mediumRailWidth,
                minExtendedWidth: MioSizes.expandedRailWidth,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _selectDestination,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: MioSpacing.lg),
                  child: Text(
                    extended ? 'MioAni' : 'M',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                destinations: [
                  for (final destination in MioDestination.values)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: navigationShell),
            ],
          ),
        );
      },
    );
  }
}
