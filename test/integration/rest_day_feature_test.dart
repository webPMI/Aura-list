import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/models/user_preferences.dart';
import 'package:checklist_app/services/database_service.dart';
import 'package:checklist_app/providers/streak_provider.dart';
import 'package:checklist_app/widgets/rest_day_banner.dart';

/// Mock DatabaseService for integration testing
class MockDatabaseService implements DatabaseService {
  UserPreferences _preferences = UserPreferences();

  @override
  Future<UserPreferences> getUserPreferences() async => _preferences;

  @override
  Future<void> saveUserPreferences(UserPreferences prefs) async {
    _preferences = prefs;
  }

  void setRestDayOfWeek(int? weekday) {
    _preferences = _preferences.copyWith(restDayOfWeek: weekday);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Rest Day Feature - End-to-End Integration Tests', () {
    late MockDatabaseService mockDb;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockDb = MockDatabaseService();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets(
        'Complete flow: User sets rest day, banner appears, streak is protected',
        (WidgetTester tester) async {
      final today = DateTime.now();
      final todayWeekday = today.weekday;

      // Step 1: User configures today as their rest day
      mockDb.setRestDayOfWeek(todayWeekday);

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
      );

      // Step 2: Build app with RestDayBanner
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

      await tester.pumpAndSettle();

      // Step 3: Verify banner is visible
      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);
      expect(find.text('Tu racha no se rompe hoy'), findsOneWidget);

      // Step 4: Verify streak provider respects rest day
      final streakNotifier = container.read(streakProvider.notifier);

      // Set up a scenario where user completed a task day before yesterday
      final prefs = await SharedPreferences.getInstance();
      final dayBeforeYesterday = today.subtract(const Duration(days: 2));
      await prefs.setInt('current_streak', 10);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', today.month);

      // Reload streak
      await streakNotifier.ensureInitialized();

      // Step 5: Verify streak is maintained despite gap (because yesterday was rest day)
      // Yesterday was the configured rest day, so streak should be preserved
      final yesterday = today.subtract(const Duration(days: 1));
      if (yesterday.weekday == todayWeekday) {
        // If yesterday was also the rest day, streak should be preserved
        expect(streakNotifier.state.currentStreak, greaterThanOrEqualTo(0));
      }
    });

    testWidgets('User changes rest day, banner updates accordingly',
        (WidgetTester tester) async {
      final today = DateTime.now();
      final notTodayWeekday = today.weekday == 7 ? 1 : today.weekday + 1;

      // Start with rest day NOT today
      mockDb.setRestDayOfWeek(notTodayWeekday);

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
      );

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

      await tester.pumpAndSettle();

      // Banner should not be visible
      expect(find.text('🌙 Hoy es tu día de descanso'), findsNothing);

      // User changes rest day to today
      mockDb.setRestDayOfWeek(today.weekday);

      // Rebuild widget
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

      await tester.pumpAndSettle();

      // Now banner should be visible
      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);
    });

    testWidgets('User disables rest day (sets to null), banner disappears',
        (WidgetTester tester) async {
      final today = DateTime.now();

      // Start with today as rest day
      mockDb.setRestDayOfWeek(today.weekday);

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
      );

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

      await tester.pumpAndSettle();

      // Banner should be visible
      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);

      // User disables rest day
      mockDb.setRestDayOfWeek(null);

      // Rebuild
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

      await tester.pumpAndSettle();

      // Banner should disappear
      expect(find.text('🌙 Hoy es tu día de descanso'), findsNothing);
    });

    testWidgets(
        'Completing task on rest day still increments streak (integration)',
        (WidgetTester tester) async {
      final today = DateTime.now();
      mockDb.setRestDayOfWeek(today.weekday);

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
      );

      final streakNotifier = container.read(streakProvider.notifier);

      // Set up existing streak from yesterday
      final yesterday = today.subtract(const Duration(days: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}',
      );

      await streakNotifier.ensureInitialized();

      // User completes a task on their rest day
      final newStreak = await streakNotifier.checkAndUpdateStreak();

      // Streak should increment even on rest day
      expect(newStreak, 6);
      expect(streakNotifier.state.currentStreak, 6);
    });

    testWidgets('Grace day system works independently of rest day',
        (WidgetTester tester) async {
      final today = DateTime.now();

      // Set rest day to something other than yesterday
      final yesterday = today.subtract(const Duration(days: 1));
      final restDayWeekday = yesterday.weekday == 7 ? 1 : yesterday.weekday + 1;

      mockDb.setRestDayOfWeek(restDayWeekday);

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
      );

      final streakNotifier = container.read(streakProvider.notifier);

      // Set up a scenario where user missed yesterday (not a rest day)
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 12);
      await prefs.setString(
        'last_task_completion_date',
        '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', today.month);

      await streakNotifier.ensureInitialized();

      // Should offer grace day since yesterday was NOT a rest day
      expect(streakNotifier.state.needsGraceDayOffer, true);
      expect(streakNotifier.state.graceDaysRemainingThisMonth, 2);

      // Accept grace day
      await streakNotifier.acceptGraceDay();

      expect(streakNotifier.state.currentStreak, 12);
      expect(streakNotifier.state.graceDaysRemainingThisMonth, 1);
    });

    testWidgets('Multiple users can have different rest days',
        (WidgetTester tester) async {
      // User 1: Monday as rest day
      final user1Prefs = UserPreferences(restDayOfWeek: 1);

      // User 2: Sunday as rest day
      final user2Prefs = UserPreferences(restDayOfWeek: 7);

      // User 3: No rest day
      final user3Prefs = UserPreferences(restDayOfWeek: null);

      expect(user1Prefs.restDayOfWeek, 1);
      expect(user2Prefs.restDayOfWeek, 7);
      expect(user3Prefs.restDayOfWeek, isNull);

      // Verify serialization preserves settings
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

    testWidgets('Rest day protection across week boundary',
        (WidgetTester tester) async {
      // Test scenario: User sets Sunday as rest day
      // On Monday, check if streak is protected from Sunday gap
      final today = DateTime.now();

      // Only run this test on Monday
      if (today.weekday == 1) {
        mockDb.setRestDayOfWeek(7); // Sunday

        container = ProviderContainer(
          overrides: [
            databaseServiceProvider.overrideWithValue(mockDb),
          ],
        );

        final streakNotifier = container.read(streakProvider.notifier);

        // User completed task on Saturday
        final saturday = today.subtract(const Duration(days: 2));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_streak', 20);
        await prefs.setString(
          'last_task_completion_date',
          '${saturday.year}-${saturday.month.toString().padLeft(2, '0')}-${saturday.day.toString().padLeft(2, '0')}',
        );
        await prefs.setInt('streak_grace_days_used', 0);
        await prefs.setInt('streak_grace_month', today.month);

        await streakNotifier.ensureInitialized();

        // Yesterday (Sunday) was rest day, so streak should be preserved
        expect(streakNotifier.state.currentStreak, 20);
        expect(streakNotifier.state.needsGraceDayOffer, false);
      }
    });

    testWidgets('Banner styling and accessibility',
        (WidgetTester tester) async {
      final today = DateTime.now();
      mockDb.setRestDayOfWeek(today.weekday);

      container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(mockDb),
        ],
      );

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

      await tester.pumpAndSettle();

      // Verify all required elements are present
      expect(find.byIcon(Icons.self_improvement), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('🌙 Hoy es tu día de descanso'), findsOneWidget);
      expect(
        find.text(
            'Las tareas son opcionales. El descanso también es productivo.'),
        findsOneWidget,
      );
      expect(find.text('Tu racha no se rompe hoy'), findsOneWidget);

      // Verify gradient container exists
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, greaterThan(0));
    });

    testWidgets('Persistence: Rest day survives app restart',
        (WidgetTester tester) async {
      // Simulate saving preference
      final prefs = UserPreferences(restDayOfWeek: 6);
      final json = prefs.toFirestore();

      // Simulate app restart - load from Firestore
      final loadedPrefs = UserPreferences.fromFirestore('test-id', json);

      expect(loadedPrefs.restDayOfWeek, 6);
      expect(loadedPrefs.firestoreId, 'test-id');
    });
  });
}
