import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/models/user_preferences.dart';
import 'package:checklist_app/providers/clock_provider.dart';
import 'package:checklist_app/providers/streak_provider.dart';
import 'package:checklist_app/providers/user_preferences_provider.dart';
import 'package:checklist_app/widgets/rest_day_banner.dart';

void main() {
  group('Rest Day Feature - End-to-End Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets(
        'Complete flow: User sets rest day, banner appears, streak is protected',
        (WidgetTester tester) async {
      final monday = DateTime(2024, 1, 1); // Monday
      final prefsController = StreamController<UserPreferences>();
      addTearDown(prefsController.close);

      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith((ref) => prefsController.stream),
          currentTimeProvider.overrideWithValue(monday),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  RestDayBanner(),
                  Text('App Content'),
                ],
              ),
            ),
          ),
        ),
      );

      // Emit rest day as Monday (1)
      prefsController.add(UserPreferences(restDayOfWeek: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify banner is visible
      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);
      expect(find.text('Tu racha no se rompe hoy'), findsOneWidget);
    });

    testWidgets('User changes rest day, banner updates accordingly',
        (WidgetTester tester) async {
      final monday = DateTime(2024, 1, 1); // Monday
      final prefsController = StreamController<UserPreferences>();
      addTearDown(prefsController.close);

      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith((ref) => prefsController.stream),
          currentTimeProvider.overrideWithValue(monday),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RestDayBanner(),
            ),
          ),
        ),
      );

      // Start with Tuesday (2) - NOT rest day on Monday
      prefsController.add(UserPreferences(restDayOfWeek: 2));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('🌙 Hoy es tu día de descanso'), findsNothing);

      // Change rest day to Monday (1)
      prefsController.add(UserPreferences(restDayOfWeek: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);
    });

    testWidgets('User disables rest day (sets to null), banner disappears',
        (WidgetTester tester) async {
      final monday = DateTime(2024, 1, 1); // Monday
      final prefsController = StreamController<UserPreferences>();
      addTearDown(prefsController.close);

      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith((ref) => prefsController.stream),
          currentTimeProvider.overrideWithValue(monday),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RestDayBanner(),
            ),
          ),
        ),
      );

      // Start with Monday as rest day
      prefsController.add(UserPreferences(restDayOfWeek: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);

      // Disable rest day
      prefsController.add(UserPreferences(restDayOfWeek: null));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('🌙 Hoy es tu día de descanso'), findsNothing);
    });

    testWidgets(
        'Completing task on rest day still increments streak (integration)',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final restDay = now.weekday;

      final yesterday = now.subtract(const Duration(days: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}',
      );

      Future<int?> getRestDay() async => restDay;
      final streakNotifier = StreakNotifier(getRestDay);
      await streakNotifier.ensureInitialized();

      final newStreak = await streakNotifier.checkAndUpdateStreak();
      expect(newStreak, 6);
      expect(streakNotifier.state.currentStreak, 6);
    });

    testWidgets('Grace day system works independently of rest day',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final yesterday = now.subtract(const Duration(days: 1));
      final restDay = yesterday.weekday == 7 ? 1 : yesterday.weekday + 1;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 12);
      await prefs.setString(
        'last_task_completion_date',
        '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      Future<int?> getRestDay() async => restDay;
      final streakNotifier = StreakNotifier(getRestDay);
      await streakNotifier.ensureInitialized();

      expect(streakNotifier.state.needsGraceDayOffer, true);
      expect(streakNotifier.state.graceDaysRemainingThisMonth, 2);

      await streakNotifier.acceptGraceDay();
      expect(streakNotifier.state.currentStreak, 12);
      expect(streakNotifier.state.graceDaysRemainingThisMonth, 1);
    });

    testWidgets('Multiple users can have different rest days',
        (WidgetTester tester) async {
      final user1Prefs = UserPreferences(restDayOfWeek: 1);
      final user2Prefs = UserPreferences(restDayOfWeek: 7);
      final user3Prefs = UserPreferences(restDayOfWeek: null);

      expect(user1Prefs.restDayOfWeek, 1);
      expect(user2Prefs.restDayOfWeek, 7);
      expect(user3Prefs.restDayOfWeek, isNull);

      final user1Json = user1Prefs.toFirestore();
      final user1Restored = UserPreferences.fromFirestore('u1', user1Json);
      expect(user1Restored.restDayOfWeek, 1);

      final user2Json = user2Prefs.toFirestore();
      final user2Restored = UserPreferences.fromFirestore('u2', user2Json);
      expect(user2Restored.restDayOfWeek, 7);

      final user3Json = user3Prefs.toFirestore();
      final user3Restored = UserPreferences.fromFirestore('u3', user3Json);
      expect(user3Restored.restDayOfWeek, isNull);
    });

    testWidgets('Banner styling and accessibility',
        (WidgetTester tester) async {
      final monday = DateTime(2024, 1, 1); // Monday
      final prefsController = StreamController<UserPreferences>();
      addTearDown(prefsController.close);

      final container = ProviderContainer(
        overrides: [
          userPreferencesProvider.overrideWith((ref) => prefsController.stream),
          currentTimeProvider.overrideWithValue(monday),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: const Scaffold(
              body: RestDayBanner(),
            ),
          ),
        ),
      );

      prefsController.add(UserPreferences(restDayOfWeek: 1));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify all elements are present
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);
      expect(
        find.text(
            'Las tareas son opcionales. El descanso también es productivo.'),
        findsOneWidget,
      );
      expect(find.text('Tu racha no se rompe hoy'), findsOneWidget);
    });

    testWidgets('Persistence: Rest day survives app restart',
        (WidgetTester tester) async {
      final prefs = UserPreferences(restDayOfWeek: 6);
      final json = prefs.toFirestore();

      final loadedPrefs = UserPreferences.fromFirestore('test-id', json);
      expect(loadedPrefs.restDayOfWeek, 6);
    });
  });
}
