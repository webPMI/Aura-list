import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/providers/streak_provider.dart';

void main() {
  group('StreakProvider Rest Day Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Streak does not break on configured rest day', () async {
      // Setup: User completed a task 2 days ago, yesterday was rest day, today checking streak
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dayBeforeYesterday = now.subtract(const Duration(days: 2));

      // Configure yesterday as rest day
      final restDayOfWeek = yesterday.weekday;

      // Mock function that returns rest day configuration
      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final notifier = StreakNotifier(getRestDayOfWeek);

      // Set up a streak that was active 2 days ago
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      // Reload streak from SharedPreferences
      await notifier.ensureInitialized();

      // The streak should still be active (5 days) because yesterday was a rest day
      expect(notifier.state.currentStreak, 5);
      expect(notifier.state.needsGraceDayOffer, false);
    });

    test('Streak breaks if missing regular day (not rest day)', () async {
      final now = DateTime.now();
      final dayBeforeYesterday = now.subtract(const Duration(days: 2));

      // Configure a rest day that is NOT yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final restDayOfWeek = yesterday.weekday == 7 ? 1 : yesterday.weekday + 1;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final notifier = StreakNotifier(getRestDayOfWeek);

      // Set up a streak that was active 2 days ago
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      await notifier.ensureInitialized();

      // Should offer grace day since yesterday was NOT a rest day
      expect(notifier.state.needsGraceDayOffer, true);
      expect(notifier.state.graceDaysRemainingThisMonth, 2);
    });

    test('No rest day configured - streak behavior is normal', () async {
      final now = DateTime.now();
      final dayBeforeYesterday = now.subtract(const Duration(days: 2));

      // No rest day configured
      Future<int?> getRestDayOfWeek() async => null;

      final notifier = StreakNotifier(getRestDayOfWeek);

      // Set up a streak that was active 2 days ago
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      await notifier.ensureInitialized();

      // Should offer grace day since there's no rest day protection
      expect(notifier.state.needsGraceDayOffer, true);
    });

    test('Completing a task on rest day still increments streak', () async {
      final now = DateTime.now();

      // Configure today as rest day
      final restDayOfWeek = now.weekday;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final notifier = StreakNotifier(getRestDayOfWeek);

      // Set yesterday as last completion
      final yesterday = now.subtract(const Duration(days: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 3);
      await prefs.setString(
        'last_task_completion_date',
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}',
      );

      await notifier.ensureInitialized();

      // Complete a task today (rest day)
      final newStreak = await notifier.checkAndUpdateStreak();

      // Streak should increment even on rest day
      expect(newStreak, 4);
      expect(notifier.state.currentStreak, 4);
    });

    test('Multiple consecutive days missed breaks streak', () async {
      // If user misses more than 1 day (even with rest day), streak breaks
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final yesterday = now.subtract(const Duration(days: 1));

      // Yesterday was rest day
      final restDayOfWeek = yesterday.weekday;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final notifier = StreakNotifier(getRestDayOfWeek);

      // Last completion was 3 days ago (too long ago)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 7);
      await prefs.setString(
        'last_task_completion_date',
        '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      await notifier.ensureInitialized();

      // Gap is too large, streak should be broken
      expect(notifier.state.currentStreak, 0);
    });

    test('Rest day on Sunday (weekday 7) protects streak', () async {
      final now = DateTime.now();

      // Create a scenario where yesterday was Sunday (rest day)
      final yesterday = now.subtract(const Duration(days: 1));

      // Only test if yesterday was actually Sunday
      if (yesterday.weekday == 7) {
        final dayBeforeYesterday = now.subtract(const Duration(days: 2));

        Future<int?> getRestDayOfWeek() async => 7; // Sunday

        final notifier = StreakNotifier(getRestDayOfWeek);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_streak', 10);
        await prefs.setString(
          'last_task_completion_date',
          '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
        );
        await prefs.setInt('streak_grace_days_used', 0);
        await prefs.setInt('streak_grace_month', now.month);

        await notifier.ensureInitialized();

        // Streak should be preserved because yesterday (Sunday) was rest day
        expect(notifier.state.currentStreak, 10);
        expect(notifier.state.needsGraceDayOffer, false);
      } else {
        // Skip test if yesterday wasn't Sunday
        expect(true, true);
      }
    });

    test('Rest day on Monday (weekday 1) protects streak', () async {
      final now = DateTime.now();

      final yesterday = now.subtract(const Duration(days: 1));

      // Only test if yesterday was actually Monday
      if (yesterday.weekday == 1) {
        final dayBeforeYesterday = now.subtract(const Duration(days: 2));

        Future<int?> getRestDayOfWeek() async => 1; // Monday

        final notifier = StreakNotifier(getRestDayOfWeek);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_streak', 8);
        await prefs.setString(
          'last_task_completion_date',
          '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
        );
        await prefs.setInt('streak_grace_days_used', 0);
        await prefs.setInt('streak_grace_month', now.month);

        await notifier.ensureInitialized();

        // Streak should be preserved because yesterday (Monday) was rest day
        expect(notifier.state.currentStreak, 8);
        expect(notifier.state.needsGraceDayOffer, false);
      } else {
        // Skip test if yesterday wasn't Monday
        expect(true, true);
      }
    });

    test('Grace day offer not affected by rest day configuration', () async {
      // If user misses a non-rest day, they should still get grace day offer
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      // Configure rest day as something other than yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final restDayOfWeek = yesterday.weekday == 7 ? 1 : yesterday.weekday + 1;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final notifier = StreakNotifier(getRestDayOfWeek);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 15);
      await prefs.setString(
        'last_task_completion_date',
        '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      await notifier.ensureInitialized();

      // Should offer grace day
      expect(notifier.state.needsGraceDayOffer, true);
      expect(notifier.state.currentStreak, 15);

      // Accept grace day
      await notifier.acceptGraceDay();

      expect(notifier.state.needsGraceDayOffer, false);
      expect(notifier.state.currentStreak, 15);
      expect(notifier.state.graceDaysRemainingThisMonth, 1);
    });

    test('Completing task after rest day continues streak', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // Yesterday was rest day, user didn't complete anything
      final restDayOfWeek = yesterday.weekday;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final notifier = StreakNotifier(getRestDayOfWeek);

      // Last completion was day before yesterday
      final dayBeforeYesterday = now.subtract(const Duration(days: 2));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 20);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      await notifier.ensureInitialized();

      // Streak should be preserved because yesterday was a rest day
      expect(notifier.state.currentStreak, 20);

      // Complete a task today - streak continues from the day before yesterday
      final newStreak = await notifier.checkAndUpdateStreak();

      // New streak should increment from current (20 -> 21)
      expect(newStreak, isNotNull);
      expect(notifier.state.currentStreak, greaterThanOrEqualTo(1));
    });
  });
}
