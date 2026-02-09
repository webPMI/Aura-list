import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/responsive/breakpoints.dart';
import '../../providers/navigation_provider.dart';
import 'app_drawer.dart';

/// Adaptive navigation that switches between bottom nav, rail, and drawer
class AdaptiveNavigation extends ConsumerWidget {
  final Widget child;
  final Widget? floatingActionButton;

  const AdaptiveNavigation({
    super.key,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = context.screenSize;

    return switch (screenSize) {
      ScreenSize.mobile => _MobileNavigation(
        fab: floatingActionButton,
        child: child,
      ),
      ScreenSize.tablet => _TabletNavigation(
        fab: floatingActionButton,
        child: child,
      ),
      ScreenSize.desktop || ScreenSize.widescreen => _DesktopNavigation(
        fab: floatingActionButton,
        child: child,
      ),
    };
  }
}

class _MobileNavigation extends ConsumerWidget {
  final Widget child;
  final Widget? fab;

  const _MobileNavigation({required this.child, this.fab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRoute = ref.watch(selectedRouteProvider);

    return Scaffold(
      drawer: AppDrawer(onNavigate: () => Navigator.pop(context)),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedRoute.index.clamp(0, 3),
        onDestinationSelected: (index) {
          final route = AppRouteExtension.fromIndex(index);
          ref.read(selectedRouteProvider.notifier).state = route;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

class _TabletNavigation extends ConsumerWidget {
  final Widget child;
  final Widget? fab;

  const _TabletNavigation({required this.child, this.fab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRoute = ref.watch(selectedRouteProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: AppDrawer(onNavigate: () => Navigator.pop(context)),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedRoute.index,
            onDestinationSelected: (index) {
              final route = AppRouteExtension.fromIndex(index);
              ref.read(selectedRouteProvider.notifier).state = route;
            },
            labelType: NavigationRailLabelType.selected,
            leading: Column(
              children: [
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle_outline,
                  size: 32,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                // Menu button to open drawer - use Builder to get scaffold context
                Builder(
                  builder: (scaffoldContext) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                    tooltip: 'Menu',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Inicio'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: Text('Tareas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.note_outlined),
                selectedIcon: Icon(Icons.note),
                label: Text('Notas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: Text('Calendario'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Ajustes'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

class _DesktopNavigation extends ConsumerWidget {
  final Widget child;
  final Widget? fab;

  const _DesktopNavigation({required this.child, this.fab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Permanent drawer
          SizedBox(
            width: 280,
            child: AppDrawer(
              onNavigate: () {}, // No-op on desktop
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(child: child),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}

/// Navigation destinations for the app
class NavigationDestinations {
  static const List<NavigationDestination> bottomNav = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: 'Tareas',
    ),
    NavigationDestination(
      icon: Icon(Icons.note_outlined),
      selectedIcon: Icon(Icons.note),
      label: 'Notas',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Calendario',
    ),
  ];

  static const List<NavigationRailDestination> rail = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Inicio'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.checklist_outlined),
      selectedIcon: Icon(Icons.checklist),
      label: Text('Tareas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.note_outlined),
      selectedIcon: Icon(Icons.note),
      label: Text('Notas'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: Text('Calendario'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Ajustes'),
    ),
  ];
}
