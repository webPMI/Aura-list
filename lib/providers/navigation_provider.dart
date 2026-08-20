import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available routes in the app
enum AppRoute { dashboard, tasks, finance, notes, calendar, settings, profile }

/// Extension to get route metadata
extension AppRouteExtension on AppRoute {
  String get label {
    return switch (this) {
      AppRoute.dashboard => 'Inicio',
      AppRoute.tasks => 'Mis Tareas',
      AppRoute.finance => 'Finanzas',
      AppRoute.notes => 'Notas',
      AppRoute.calendar => 'Calendario',
      AppRoute.settings => 'Ajustes',
      AppRoute.profile => 'Mi Perfil',
    };
  }

  String get icon {
    return switch (this) {
      AppRoute.dashboard => 'dashboard',
      AppRoute.tasks => 'checklist',
      AppRoute.finance => 'payments',
      AppRoute.notes => 'note',
      AppRoute.calendar => 'calendar_today',
      AppRoute.settings => 'settings',
      AppRoute.profile => 'person',
    };
  }

  int get index {
    return switch (this) {
      AppRoute.dashboard => 0,
      AppRoute.tasks => 1,
      AppRoute.finance => 2,
      AppRoute.notes => 3,
      AppRoute.calendar => 4,
      AppRoute.settings => 5,
      AppRoute.profile => 6, // Profile is a detail screen, not in main nav
    };
  }

  static AppRoute fromIndex(int index) {
    return switch (index) {
      0 => AppRoute.dashboard,
      1 => AppRoute.tasks,
      2 => AppRoute.finance,
      3 => AppRoute.notes,
      4 => AppRoute.calendar,
      5 => AppRoute.settings,
      6 => AppRoute.profile,
      _ => AppRoute.dashboard,
    };
  }
}

/// Provider for current selected route
final selectedRouteProvider = StateProvider<AppRoute>(
  (ref) => AppRoute.dashboard,
);

/// Provider for selected task type in tasks screen
final selectedTaskTypeProvider = StateProvider<String>((ref) => 'daily');

/// Task types available
class TaskTypes {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';
  static const String once = 'once';

  static const List<TaskTypeInfo> all = [
    TaskTypeInfo(
      type: daily,
      label: 'Hoy',
      shortLabel: 'DIA',
      icon: 'wb_sunny',
    ),
    TaskTypeInfo(
      type: weekly,
      label: 'Semana',
      shortLabel: 'SEM',
      icon: 'calendar_view_week',
    ),
    TaskTypeInfo(
      type: monthly,
      label: 'Mes',
      shortLabel: 'MES',
      icon: 'calendar_month',
    ),
    TaskTypeInfo(type: yearly, label: 'Ano', shortLabel: 'ANO', icon: 'event'),
    TaskTypeInfo(
      type: once,
      label: 'Unicas',
      shortLabel: 'UNI',
      icon: 'push_pin',
    ),
  ];

  static TaskTypeInfo getInfo(String type) {
    return all.firstWhere((t) => t.type == type, orElse: () => all.first);
  }
}

/// Information about a task type
class TaskTypeInfo {
  final String type;
  final String label;
  final String shortLabel;
  final String icon;

  const TaskTypeInfo({
    required this.type,
    required this.label,
    required this.shortLabel,
    required this.icon,
  });
}

/// Provider to track if drawer is open (for responsive layouts)
final drawerOpenProvider = StateProvider<bool>((ref) => false);

/// Provider for currently selected task (for master-detail view)
final selectedTaskIdProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

/// Provider for search query in tasks screen
final taskSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Provider to track if search mode is active
final isSearchActiveProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Provider for navigation history (for back navigation)
final navigationHistoryProvider =
    StateNotifierProvider<NavigationHistoryNotifier, List<AppRoute>>((ref) {
      return NavigationHistoryNotifier(ref);
    });

/// Provider indicating whether we can navigate back in the AppRoute history
final canGoBackProvider = Provider<bool>((ref) {
  return ref.watch(navigationHistoryProvider).length > 1;
});

class NavigationHistoryNotifier extends StateNotifier<List<AppRoute>> {
  final Ref _ref;

  NavigationHistoryNotifier(this._ref) : super([AppRoute.dashboard]);

  /// Navigates to a new route, appending to history if different from current
  void goTo(AppRoute route, {bool replace = false}) {
    if (replace) {
      if (state.isNotEmpty) {
        state = [...state.sublist(0, state.length - 1), route];
      } else {
        state = [route];
      }
    } else {
      if (state.isEmpty || state.last != route) {
        // If navigating back to dashboard, we can keep dashboard as the root
        if (route == AppRoute.dashboard) {
          state = [AppRoute.dashboard];
        } else {
          // Avoid duplicate consecutive entries
          state = [...state, route];
        }
      }
    }
    _ref.read(selectedRouteProvider.notifier).state = route;
  }

  /// Pops the top route from history and navigates to the previous route.
  /// Returns true if navigation occurred, false if at root.
  bool goBack() {
    if (state.length > 1) {
      final updatedHistory = state.sublist(0, state.length - 1);
      state = updatedHistory;
      final previousRoute = updatedHistory.last;
      _ref.read(selectedRouteProvider.notifier).state = previousRoute;
      return true;
    }
    return false;
  }

  /// Clears history and resets to given route (defaults to dashboard)
  void reset([AppRoute route = AppRoute.dashboard]) {
    state = [route];
    _ref.read(selectedRouteProvider.notifier).state = route;
  }

  bool get canGoBack => state.length > 1;
}



