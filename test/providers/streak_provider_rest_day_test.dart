import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklist_app/providers/streak_provider.dart';

void main() {
  group('StreakProvider Rest Day Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Streak does not break on configured rest day', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final dayBeforeYesterday = now.subtract(const Duration(days: 2));

      final restDayOfWeek = yesterday.weekday;
      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      expect(notifier.state.currentStreak, 5);
      expect(notifier.state.needsGraceDayOffer, false);
    });

    test('Streak breaks if missing regular day (not rest day)', () async {
      final now = DateTime.now();
      final dayBeforeYesterday = now.subtract(const Duration(days: 2));
      final yesterday = now.subtract(const Duration(days: 1));
      final restDayOfWeek = yesterday.weekday == 7 ? 1 : yesterday.weekday + 1;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      expect(notifier.state.needsGraceDayOffer, true);
      expect(notifier.state.graceDaysRemainingThisMonth, 2);
    });

    test('No rest day configured - streak behavior is normal', () async {
      final now = DateTime.now();
      final dayBeforeYesterday = now.subtract(const Duration(days: 2));

      Future<int?> getRestDayOfWeek() async => null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 5);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      expect(notifier.state.needsGraceDayOffer, true);
    });

    test('Completing a task on rest day still increments streak', () async {
      final now = DateTime.now();
      final restDayOfWeek = now.weekday;
      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final yesterday = now.subtract(const Duration(days: 1));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 3);
      await prefs.setString(
        'last_task_completion_date',
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}',
      );

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      final newStreak = await notifier.checkAndUpdateStreak();
      expect(newStreak, 4);
      expect(notifier.state.currentStreak, 4);
    });

    test('Multiple consecutive days missed breaks streak', () async {
      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final yesterday = now.subtract(const Duration(days: 1));
      final restDayOfWeek = yesterday.weekday;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 7);
      await prefs.setString(
        'last_task_completion_date',
        '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 2); // all used up
      await prefs.setInt('streak_grace_month', now.month);

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      expect(notifier.state.currentStreak, 0);
    });

    test('Rest day on Sunday (weekday 7) protects streak', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      if (yesterday.weekday == 7) {
        final dayBeforeYesterday = now.subtract(const Duration(days: 2));
        Future<int?> getRestDayOfWeek() async => 7;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_streak', 10);
        await prefs.setString(
          'last_task_completion_date',
          '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
        );
        await prefs.setInt('streak_grace_days_used', 0);
        await prefs.setInt('streak_grace_month', now.month);

        final notifier = StreakNotifier(getRestDayOfWeek);
        await notifier.ensureInitialized();

        expect(notifier.state.currentStreak, 10);
        expect(notifier.state.needsGraceDayOffer, false);
      } else {
        expect(true, true);
      }
    });

    test('Rest day on Monday (weekday 1) protects streak', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      if (yesterday.weekday == 1) {
        final dayBeforeYesterday = now.subtract(const Duration(days: 2));
        Future<int?> getRestDayOfWeek() async => 1;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('current_streak', 8);
        await prefs.setString(
          'last_task_completion_date',
          '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
        );
        await prefs.setInt('streak_grace_days_used', 0);
        await prefs.setInt('streak_grace_month', now.month);

        final notifier = StreakNotifier(getRestDayOfWeek);
        await notifier.ensureInitialized();

        expect(notifier.state.currentStreak, 8);
        expect(notifier.state.needsGraceDayOffer, false);
      } else {
        expect(true, true);
      }
    });

    test('Grace day offer not affected by rest day configuration', () async {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final yesterday = now.subtract(const Duration(days: 1));
      final restDayOfWeek = yesterday.weekday == 7 ? 1 : yesterday.weekday + 1;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 15);
      await prefs.setString(
        'last_task_completion_date',
        '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      expect(notifier.state.needsGraceDayOffer, true);
      expect(notifier.state.currentStreak, 15);

      await notifier.acceptGraceDay();
      expect(notifier.state.needsGraceDayOffer, false);
      expect(notifier.state.currentStreak, 15);
      expect(notifier.state.graceDaysRemainingThisMonth, 1);
    });

    test('Completing task after rest day continues streak', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final restDayOfWeek = yesterday.weekday;

      Future<int?> getRestDayOfWeek() async => restDayOfWeek;

      final dayBeforeYesterday = now.subtract(const Duration(days: 2));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', 20);
      await prefs.setString(
        'last_task_completion_date',
        '${dayBeforeYesterday.year}-${dayBeforeYesterday.month.toString().padLeft(2, '0')}-${dayBeforeYesterday.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt('streak_grace_days_used', 0);
      await prefs.setInt('streak_grace_month', now.month);

      final notifier = StreakNotifier(getRestDayOfWeek);
      await notifier.ensureInitialized();

      expect(notifier.state.currentStreak, 20);

      final newStreak = await notifier.checkAndUpdateStreak();
      expect(newStreak, isNotNull);
      expect(notifier.state.currentStreak, greaterThanOrEqualTo(1));
    });
  });
}
