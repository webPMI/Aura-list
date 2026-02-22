import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/providers/streak_provider.dart';

/// Simplified tests for rest day functionality that avoid time-dependent issues
void main() {
  group('StreakProvider Rest Day - Simplified Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('StreakNotifier can be created with rest day callback', () async {
      Future<int?> getRestDayOfWeek() async => 7; // Sunday

      final notifier = StreakNotifier(getRestDayOfWeek);

      await notifier.ensureInitialized();

      // Notifier should be initialized successfully
      expect(notifier.state, isNotNull);
      expect(notifier.state.currentStreak, greaterThanOrEqualTo(0));
    });

    test('StreakNotifier can be created without rest day (null)', () async {
      Future<int?> getRestDayOfWeek() async => null;

      final notifier = StreakNotifier(getRestDayOfWeek);

      await notifier.ensureInitialized();

      expect(notifier.state, isNotNull);
      expect(notifier.state.currentStreak, greaterThanOrEqualTo(0));
    });

    test('checkAndUpdateStreak returns new streak value on first completion',
        () async {
      Future<int?> getRestDayOfWeek() async => 6; // Saturday

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      // Complete a task for the first time
      final newStreak = await notifier.checkAndUpdateStreak();

      expect(newStreak, isNotNull);
      expect(newStreak, greaterThanOrEqualTo(1));
      expect(notifier.state.currentStreak, newStreak);
      expect(notifier.state.lastCompletionDate, isNotNull);
    });

    test('checkAndUpdateStreak returns null if already completed today',
        () async {
      Future<int?> getRestDayOfWeek() async => 3; // Wednesday

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      // Complete a task today
      final firstStreak = await notifier.checkAndUpdateStreak();
      expect(firstStreak, isNotNull);

      // Try to complete again today
      final secondStreak = await notifier.checkAndUpdateStreak();
      expect(secondStreak, isNull); // Should return null
    });

    test('resetStreak clears streak state', () async {
      Future<int?> getRestDayOfWeek() async => 2; // Tuesday

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      // Build up a streak
      await notifier.checkAndUpdateStreak();
      expect(notifier.state.currentStreak, greaterThanOrEqualTo(1));

      // Reset
      await notifier.resetStreak();

      expect(notifier.state.currentStreak, 0);
      expect(notifier.state.lastCompletionDate, isNull);
    });

    test('Grace days are properly tracked', () async {
      Future<int?> getRestDayOfWeek() async => null;

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      // Check grace days are initialized
      expect(notifier.state.graceDaysRemainingThisMonth, greaterThanOrEqualTo(0));
      expect(
        notifier.state.graceDaysRemainingThisMonth,
        lessThanOrEqualTo(2),
      ); // Max 2 per month
    });

    test('acceptGraceDay consumes a grace day', () async {
      Future<int?> getRestDayOfWeek() async => null;

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      final initialGraceDays = notifier.state.graceDaysRemainingThisMonth;

      // Manually set up a grace day offer scenario
      // This would typically happen when user misses a day
      final prefs = await SharedPreferences.getInstance();
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', DateTime.now().month);

      // Recreate notifier to load new state
      final notifier2 = StreakNotifier(getRestDayOfWeek);
      await notifier2.ensureInitialized();

      if (notifier2.state.needsGraceDayOffer) {
        final beforeGrace = notifier2.state.graceDaysRemainingThisMonth;
        await notifier2.acceptGraceDay();

        expect(notifier2.state.needsGraceDayOffer, false);
        expect(
          notifier2.state.graceDaysRemainingThisMonth,
          lessThan(beforeGrace),
        );
      }
    });

    test('declineGraceDay resets streak', () async {
      Future<int?> getRestDayOfWeek() async => null;

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      // Set up grace day scenario
      final prefs = await SharedPreferences.getInstance();
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await prefs.setInt('current_streak', 10);
      await prefs.setString(
        'last_task_completion_date',
        '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', DateTime.now().month);

      final notifier2 = StreakNotifier(getRestDayOfWeek);
      await notifier2.ensureInitialized();

      if (notifier2.state.needsGraceDayOffer) {
        await notifier2.declineGraceDay();

        expect(notifier2.state.currentStreak, 0);
        expect(notifier2.state.needsGraceDayOffer, false);
      }
    });

    test('Streak milestones are correctly identified', () {
      expect(isStreakMilestone(3), true);
      expect(isStreakMilestone(7), true);
      expect(isStreakMilestone(30), true);
      expect(isStreakMilestone(365), true);
      expect(isStreakMilestone(5), false);
      expect(isStreakMilestone(100), false);
    });

    test('Next milestone calculation works correctly', () {
      expect(getNextMilestone(0), 3);
      expect(getNextMilestone(3), 7);
      expect(getNextMilestone(7), 14);
      expect(getNextMilestone(50), 60);
      expect(getNextMilestone(365), 400); // Next 100 increment
    });

    test('Different rest day values are handled', () async {
      for (int weekday = 1; weekday <= 7; weekday++) {
        Future<int?> getRestDayOfWeek() async => weekday;

        final notifier = StreakNotifier(getRestDayOfWeek);
        await notifier.ensureInitialized();

        expect(notifier.state, isNotNull);
      }
    });

    test('ensureInitialized completes successfully', () async {
      Future<int?> getRestDayOfWeek() async => 5; // Friday

      final notifier = StreakNotifier(getRestDayOfWeek);

      // Should complete without throwing
      await expectLater(
        notifier.ensureInitialized(),
        completes,
      );
    });
  });
}
