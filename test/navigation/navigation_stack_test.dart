import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/providers/navigation_provider.dart';

void main() {
  group('NavigationHistoryNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state starts at dashboard with canGoBack == false', () {
      final history = container.read(navigationHistoryProvider);
      final selectedRoute = container.read(selectedRouteProvider);
      final canGoBack = container.read(canGoBackProvider);

      expect(history, [AppRoute.dashboard]);
      expect(selectedRoute, AppRoute.dashboard);
      expect(canGoBack, false);
    });

    test('goTo pushes new route and updates selectedRouteProvider and canGoBack', () {
      final notifier = container.read(navigationHistoryProvider.notifier);

      notifier.goTo(AppRoute.finance);

      expect(container.read(navigationHistoryProvider), [
        AppRoute.dashboard,
        AppRoute.finance,
      ]);
      expect(container.read(selectedRouteProvider), AppRoute.finance);
      expect(container.read(canGoBackProvider), true);

      notifier.goTo(AppRoute.profile);

      expect(container.read(navigationHistoryProvider), [
        AppRoute.dashboard,
        AppRoute.finance,
        AppRoute.profile,
      ]);
      expect(container.read(selectedRouteProvider), AppRoute.profile);
      expect(container.read(canGoBackProvider), true);
    });

    test('goTo does not duplicate consecutive routes', () {
      final notifier = container.read(navigationHistoryProvider.notifier);

      notifier.goTo(AppRoute.tasks);
      notifier.goTo(AppRoute.tasks);

      expect(container.read(navigationHistoryProvider), [
        AppRoute.dashboard,
        AppRoute.tasks,
      ]);
      expect(container.read(selectedRouteProvider), AppRoute.tasks);
    });

    test('goBack pops top route and returns to previous route', () {
      final notifier = container.read(navigationHistoryProvider.notifier);

      notifier.goTo(AppRoute.tasks);
      notifier.goTo(AppRoute.settings);

      expect(container.read(selectedRouteProvider), AppRoute.settings);

      final poppedFirst = notifier.goBack();
      expect(poppedFirst, true);
      expect(container.read(selectedRouteProvider), AppRoute.tasks);
      expect(container.read(navigationHistoryProvider), [
        AppRoute.dashboard,
        AppRoute.tasks,
      ]);
      expect(container.read(canGoBackProvider), true);

      final poppedSecond = notifier.goBack();
      expect(poppedSecond, true);
      expect(container.read(selectedRouteProvider), AppRoute.dashboard);
      expect(container.read(navigationHistoryProvider), [AppRoute.dashboard]);
      expect(container.read(canGoBackProvider), false);

      // Third pop should fail because at root
      final poppedThird = notifier.goBack();
      expect(poppedThird, false);
      expect(container.read(selectedRouteProvider), AppRoute.dashboard);
      expect(container.read(canGoBackProvider), false);
    });

    test('goTo dashboard resets history stack to root', () {
      final notifier = container.read(navigationHistoryProvider.notifier);

      notifier.goTo(AppRoute.notes);
      notifier.goTo(AppRoute.calendar);
      notifier.goTo(AppRoute.profile);

      expect(container.read(canGoBackProvider), true);

      notifier.goTo(AppRoute.dashboard);

      expect(container.read(navigationHistoryProvider), [AppRoute.dashboard]);
      expect(container.read(selectedRouteProvider), AppRoute.dashboard);
      expect(container.read(canGoBackProvider), false);
    });

    test('reset clears and sets new root', () {
      final notifier = container.read(navigationHistoryProvider.notifier);

      notifier.goTo(AppRoute.finance);
      notifier.goTo(AppRoute.settings);

      notifier.reset(AppRoute.tasks);

      expect(container.read(navigationHistoryProvider), [AppRoute.tasks]);
      expect(container.read(selectedRouteProvider), AppRoute.tasks);
      expect(container.read(canGoBackProvider), false);
    });
  });
}
