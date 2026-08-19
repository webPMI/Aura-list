import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklist_app/widgets/rest_day_banner.dart';
import 'package:checklist_app/models/user_preferences.dart';
import 'package:checklist_app/providers/clock_provider.dart';
import 'package:checklist_app/providers/user_preferences_provider.dart';

void main() {
  group('RestDayBanner Widget Tests', () {
    testWidgets('Banner is hidden when no rest day is configured', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith(
            (ref) => Stream.value(UserPreferences(restDayOfWeek: null)),
          ),
          currentTimeProvider.overrideWithValue(DateTime(2024, 1, 1)), // Monday
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: RestDayBanner())),
        ),
      );

      await tester.pumpAndSettle();

      // Banner should not be visible
      expect(find.text('🌙 Hoy es tu día de descanso'), findsNothing);
    });

    testWidgets('Banner is hidden when today is NOT the rest day', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith(
            (ref) => Stream.value(UserPreferences(restDayOfWeek: 2)),
          ), // Tuesday
          currentTimeProvider.overrideWithValue(DateTime(2024, 1, 1)), // Monday
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: RestDayBanner())),
        ),
      );

      await tester.pumpAndSettle();

      // Banner should not be visible
      expect(find.text('🌙 Hoy es tu día de descanso'), findsNothing);
    });

    testWidgets('Banner is visible when today IS the rest day', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith(
            (ref) => Stream.value(UserPreferences(restDayOfWeek: 1)),
          ), // Monday
          currentTimeProvider.overrideWithValue(DateTime(2024, 1, 1)), // Monday
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: RestDayBanner())),
        ),
      );

      await tester.pumpAndSettle();

      // Banner should be visible with correct text
      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);
      expect(
        find.text(
          'Las tareas son opcionales. El descanso también es productivo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tu racha no se rompe hoy'), findsOneWidget);
    });

    testWidgets('Banner displays correct icons and styling', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith(
            (ref) => Stream.value(UserPreferences(restDayOfWeek: 1)),
          ), // Monday
          currentTimeProvider.overrideWithValue(DateTime(2024, 1, 1)), // Monday
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: RestDayBanner())),
        ),
      );

      await tester.pumpAndSettle();

      // Check for self_improvement icon
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);

      // Check for favorite icon
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Verify Container is present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Banner updates when preferences change', (
      WidgetTester tester,
    ) async {
      final controller = StreamController<UserPreferences>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith(
            (ref) => controller.stream,
          ),
          currentTimeProvider.overrideWithValue(DateTime(2024, 1, 1)), // Monday
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: RestDayBanner())),
        ),
      );

      // Set to Tuesday (not rest day on Monday)
      controller.add(UserPreferences(restDayOfWeek: 2));
      await tester.pump();
      await tester.pumpAndSettle();

      // Banner should not be visible initially
      expect(find.text('🌙 Hoy es tu día de descanso'), findsNothing);

      // Update to Monday (today IS rest day)
      controller.add(UserPreferences(restDayOfWeek: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // Banner should now be visible
      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);
    });

    testWidgets('Banner handles all weekdays correctly', (
      WidgetTester tester,
    ) async {
      for (int weekday = 1; weekday <= 7; weekday++) {
        final container = ProviderContainer(
          overrides: [
            userPreferencesProvider.overrideWith(
              (ref) => Stream.value(UserPreferences(restDayOfWeek: weekday)),
            ),
            currentTimeProvider.overrideWithValue(DateTime(2024, 1, weekday)),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: Scaffold(body: RestDayBanner())),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('🌙 Hoy es tu día de descanso'),
          findsOneWidget,
          reason:
              'Weekday $weekday should show banner when matches current day',
        );

        container.dispose();
      }
    });
  });
}
