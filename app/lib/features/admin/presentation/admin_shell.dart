import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/presentation/bloc/session_cubit.dart';

/// Width at which the side [NavigationRail] replaces the drawer.
const double kAdminRailMinWidth = 840;

/// Width at which the rail is extended to show labels beside icons.
const double kAdminRailExtendedMinWidth = 1200;

/// One admin navigation destination; order defines the selected index.
typedef _AdminDestination = ({String path, IconData icon, IconData selectedIcon});

const List<_AdminDestination> _destinations = [
  (path: '/admin', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard),
  (path: '/admin/sites', icon: Icons.location_city_outlined, selectedIcon: Icons.location_city),
  (path: '/admin/users', icon: Icons.people_outline, selectedIcon: Icons.people),
];

/// Index of the destination owning [location]: the longest destination path
/// that equals it or is a segment prefix of it. Overview is the fallback.
int _indexFor(String location) {
  for (var i = _destinations.length - 1; i > 0; i--) {
    final path = _destinations[i].path;
    if (location == path || location.startsWith('$path/')) {
      return i;
    }
  }
  return 0;
}

/// Responsive admin frame around the `/admin/*` routes: a side
/// [NavigationRail] on wide windows, a [NavigationDrawer] on compact ones.
/// Direction comes from the locale, so both mirror automatically in RTL.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.navOverview, l10n.navSites, l10n.navUsers];
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final selected = _indexFor(GoRouterState.of(context).matchedLocation);
    final appBar = AppBar(
      title: Text(l10n.adminHomeTitle),
      actions: [
        IconButton(
          tooltip: l10n.logoutButton,
          onPressed: () => context.read<SessionCubit>().signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kAdminRailMinWidth) {
          final extended = constraints.maxWidth >= kAdminRailExtendedMinWidth;
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  selectedIndex: selected,
                  onDestinationSelected: (index) => context.go(_destinations[index].path),
                  destinations: [
                    for (final (i, d) in _destinations.indexed)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(labels[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: appBar,
          drawer: Builder(
            builder: (drawerContext) => NavigationDrawer(
              selectedIndex: selected,
              onDestinationSelected: (index) {
                Navigator.of(drawerContext).pop();
                context.go(_destinations[index].path);
              },
              children: [
                SizedBox(height: spacing.lg),
                for (final (i, d) in _destinations.indexed)
                  NavigationDrawerDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(labels[i]),
                  ),
              ],
            ),
          ),
          body: child,
        );
      },
    );
  }
}
