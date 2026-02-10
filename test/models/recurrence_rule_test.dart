import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/recurrence_rule.dart';

void main() {
  group('RecurrenceFrequency', () {
    test('should have correct RFC 5545 codes', () {
      expect(RecurrenceFrequency.daily.rfc5545Code, 'DAILY');
      expect(RecurrenceFrequency.weekly.rfc5545Code, 'WEEKLY');
      expect(RecurrenceFrequency.monthly.rfc5545Code, 'MONTHLY');
      expect(RecurrenceFrequency.yearly.rfc5545Code, 'YEARLY');
    });

    test('should have correct Spanish names', () {
      expect(RecurrenceFrequency.daily.spanishName, 'Diario');
      expect(RecurrenceFrequency.weekly.spanishName, 'Semanal');
      expect(RecurrenceFrequency.monthly.spanishName, 'Mensual');
      expect(RecurrenceFrequency.yearly.spanishName, 'Anual');
    });

    test('should parse from RFC 5545 code', () {
      expect(RecurrenceFrequencyExtension.fromRfc5545Code('DAILY'), RecurrenceFrequency.daily);
      expect(RecurrenceFrequencyExtension.fromRfc5545Code('weekly'), RecurrenceFrequency.weekly);
    });
  });

  group('WeekDay', () {
    test('should have correct ISO values (1-7)', () {
      expect(WeekDay.monday.isoValue, 1);
      expect(WeekDay.tuesday.isoValue, 2);
      expect(WeekDay.wednesday.isoValue, 3);
      expect(WeekDay.thursday.isoValue, 4);
      expect(WeekDay.friday.isoValue, 5);
      expect(WeekDay.saturday.isoValue, 6);
      expect(WeekDay.sunday.isoValue, 7);
    });

    test('should have correct RFC 5545 codes', () {
      expect(WeekDay.monday.rfc5545Code, 'MO');
      expect(WeekDay.tuesday.rfc5545Code, 'TU');
      expect(WeekDay.wednesday.rfc5545Code, 'WE');
      expect(WeekDay.thursday.rfc5545Code, 'TH');
      expect(WeekDay.friday.rfc5545Code, 'FR');
      expect(WeekDay.saturday.rfc5545Code, 'SA');
      expect(WeekDay.sunday.rfc5545Code, 'SU');
    });

    test('should have correct Spanish names', () {
      expect(WeekDay.monday.spanishName, 'Lunes');
      expect(WeekDay.friday.spanishName, 'Viernes');
      expect(WeekDay.sunday.spanishName, 'Domingo');
    });

    test('should parse from ISO value', () {
      expect(WeekDayExtension.fromIsoValue(1), WeekDay.monday);
      expect(WeekDayExtension.fromIsoValue(7), WeekDay.sunday);
    });

    test('should throw on invalid ISO value', () {
      expect(() => WeekDayExtension.fromIsoValue(0), throwsArgumentError);
      expect(() => WeekDayExtension.fromIsoValue(8), throwsArgumentError);
    });

    test('should parse from RFC 5545 code', () {
      expect(WeekDayExtension.fromRfc5545Code('MO'), WeekDay.monday);
      expect(WeekDayExtension.fromRfc5545Code('su'), WeekDay.sunday);
    });
  });

  group('WeekParity', () {
    test('should have correct Spanish names', () {
      expect(WeekParity.a.spanishName, 'Semana A');
      expect(WeekParity.b.spanishName, 'Semana B');
    });

    test('should have correct short names', () {
      expect(WeekParity.a.shortName, 'A');
      expect(WeekParity.b.shortName, 'B');
    });
  });

  group('RecurrenceRule - Daily', () {
    test('should create daily recurrence', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule.frequency, RecurrenceFrequency.daily);
      expect(rule.interval, 1);
    });

    test('should calculate next occurrence for daily', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
      );

      final next = rule.nextOccurrence(DateTime(2024, 1, 1));
      expect(next, DateTime(2024, 1, 1));

      final next2 = rule.nextOccurrence(DateTime(2024, 1, 2));
      expect(next2, DateTime(2024, 1, 2));
    });

    test('should calculate next occurrence with interval', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 3,
        startDate: DateTime(2024, 1, 1),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 4);
      expect(occurrences, [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 7),
        DateTime(2024, 1, 10),
      ]);
    });

    test('should filter by byDays for daily', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        byDays: [WeekDay.monday, WeekDay.wednesday, WeekDay.friday],
        startDate: DateTime(2024, 1, 1), // Monday
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 3);
      // Jan 1 = Monday, Jan 3 = Wednesday, Jan 5 = Friday
      expect(occurrences, [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5),
      ]);
    });
  });

  group('RecurrenceRule - Weekly', () {
    test('should create weekly recurrence with multiple days', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.tuesday, WeekDay.thursday],
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule.byDays, contains(WeekDay.tuesday));
      expect(rule.byDays, contains(WeekDay.thursday));
    });

    test('should calculate weekly with Tuesday and Thursday', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.tuesday, WeekDay.thursday],
        startDate: DateTime(2024, 1, 1),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 4);
      // Jan 2 = Tuesday, Jan 4 = Thursday, Jan 9 = Tuesday, Jan 11 = Thursday
      expect(occurrences, [
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 9),
        DateTime(2024, 1, 11),
      ]);
    });

    test('should calculate bi-weekly', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        startDate: DateTime(2024, 1, 1), // Monday
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 3);
      expect(occurrences, [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 29),
      ]);
    });
  });

  group('RecurrenceRule - Monthly', () {
    test('should create monthly by day of month', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        byMonthDays: [15],
        startDate: DateTime(2024, 1, 15),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 3);
      expect(occurrences, [
        DateTime(2024, 1, 15),
        DateTime(2024, 2, 15),
        DateTime(2024, 3, 15),
      ]);
    });

    test('should handle last day of month (-1)', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        byMonthDays: [-1],
        startDate: DateTime(2024, 1, 31),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 3);
      expect(occurrences, [
        DateTime(2024, 1, 31),
        DateTime(2024, 2, 29), // 2024 is leap year
        DateTime(2024, 3, 31),
      ]);
    });

    test('should calculate first Monday of month', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        byDays: [WeekDay.monday],
        weekPosition: 1,
        startDate: DateTime(2024, 1, 1),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 3);
      expect(occurrences, [
        DateTime(2024, 1, 1), // First Monday of Jan
        DateTime(2024, 2, 5), // First Monday of Feb
        DateTime(2024, 3, 4), // First Monday of Mar
      ]);
    });

    test('should calculate last Friday of month', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        byDays: [WeekDay.friday],
        weekPosition: -1,
        startDate: DateTime(2024, 1, 1),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 3);
      expect(occurrences, [
        DateTime(2024, 1, 26), // Last Friday of Jan
        DateTime(2024, 2, 23), // Last Friday of Feb
        DateTime(2024, 3, 29), // Last Friday of Mar
      ]);
    });

    test('should handle day 31 in short months', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        byMonthDays: [31],
        startDate: DateTime(2024, 1, 31),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 4);
      expect(occurrences, [
        DateTime(2024, 1, 31),
        DateTime(2024, 2, 29), // Feb 2024 has 29 days (leap year)
        DateTime(2024, 3, 31),
        DateTime(2024, 4, 30), // April has 30 days
      ]);
    });
  });

  group('RecurrenceRule - Yearly', () {
    test('should calculate yearly on specific date', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        byMonths: [3],
        byMonthDays: [15],
        startDate: DateTime(2024, 3, 15),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 3);
      expect(occurrences, [
        DateTime(2024, 3, 15),
        DateTime(2025, 3, 15),
        DateTime(2026, 3, 15),
      ]);
    });

    test('should handle Feb 29 birthday in leap years', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.yearly,
        byMonths: [2],
        byMonthDays: [29],
        startDate: DateTime(2024, 2, 29),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 3);
      // Should get Feb 29 in 2024, then Feb 28 in 2025, 2026
      expect(occurrences[0], DateTime(2024, 2, 29));
      expect(occurrences[1], DateTime(2025, 2, 28)); // Non-leap year
      expect(occurrences[2], DateTime(2026, 2, 28)); // Non-leap year
    });
  });

  group('RecurrenceRule - Constraints', () {
    test('should respect startDate', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 15),
      );

      final next = rule.nextOccurrence(DateTime(2024, 1, 1));
      expect(next, DateTime(2024, 1, 15));
    });

    test('should respect endDate', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 10);
      expect(occurrences.length, 5);
      expect(occurrences.last, DateTime(2024, 1, 5));
    });

    test('should respect count limit', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
        count: 3,
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 10);
      expect(occurrences.length, 3);
    });

    test('should skip exception dates', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
        exceptionDates: [DateTime(2024, 1, 3)],
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 4);
      expect(occurrences, [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
        // Jan 3 skipped
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 5),
      ]);
    });

    test('should filter by week parity', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.monday],
        weekParity: WeekParity.a,
        startDate: DateTime(2024, 1, 1),
      );

      final occurrences = rule.nextOccurrences(DateTime(2024, 1, 1), 4);
      // Week parity A = odd weeks, should skip even weeks
      expect(occurrences.length, 4);
      // Check that weeks are alternating
      for (int i = 1; i < occurrences.length; i++) {
        final diff = occurrences[i].difference(occurrences[i - 1]).inDays;
        expect(diff, 14); // Every 2 weeks
      }
    });
  });

  group('RecurrenceRule - matchesDate', () {
    test('should return true for matching date', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.monday],
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule.matchesDate(DateTime(2024, 1, 1)), isTrue); // Monday
      expect(rule.matchesDate(DateTime(2024, 1, 8)), isTrue); // Monday
    });

    test('should return false for non-matching date', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.monday],
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule.matchesDate(DateTime(2024, 1, 2)), isFalse); // Tuesday
    });

    test('should return false for exception date', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
        exceptionDates: [DateTime(2024, 1, 3)],
      );

      expect(rule.matchesDate(DateTime(2024, 1, 3)), isFalse);
    });

    test('should return false before startDate', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 15),
      );

      expect(rule.matchesDate(DateTime(2024, 1, 1)), isFalse);
    });
  });

  group('RecurrenceRule - toDisplayString', () {
    test('should display daily', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule.toDisplayString(), 'Todos los dias');
    });

    test('should display daily with interval', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        interval: 3,
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule.toDisplayString(), 'Cada 3 dias');
    });

    test('should display workdays preset', () {
      final rule = RecurrenceRule.workdays(startDate: DateTime(2024, 1, 1));

      expect(rule.toDisplayString(), contains('Dias laborales'));
    });

    test('should display weekends preset', () {
      final rule = RecurrenceRule.weekends(startDate: DateTime(2024, 1, 1));

      expect(rule.toDisplayString(), contains('Fines de semana'));
    });

    test('should display multiple days', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.tuesday, WeekDay.thursday],
        startDate: DateTime(2024, 1, 1),
      );

      final display = rule.toDisplayString();
      expect(display, contains('Martes'));
      expect(display, contains('Jueves'));
    });

    test('should display first Monday of month', () {
      final rule = RecurrenceRule.nthWeekdayOfMonth(
        startDate: DateTime(2024, 1, 1),
        weekday: WeekDay.monday,
        position: 1,
      );

      final display = rule.toDisplayString();
      expect(display, contains('primer'));
      expect(display, contains('Lunes'));
    });

    test('should display with time', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
      );

      final display = rule.toDisplayString(const TimeOfDay(hour: 9, minute: 0));
      expect(display, contains('09:00'));
    });

    test('should display with week parity', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.monday],
        weekParity: WeekParity.a,
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule.toDisplayString(), contains('Semana A'));
    });
  });

  group('RecurrenceRule - RFC 5545', () {
    test('should serialize to RFC 5545 format', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.tuesday, WeekDay.thursday],
        startDate: DateTime(2024, 1, 1),
      );

      final rrule = rule.toRfc5545String();
      expect(rrule, contains('FREQ=WEEKLY'));
      expect(rrule, contains('BYDAY=TU,TH'));
    });

    test('should serialize with interval', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        startDate: DateTime(2024, 1, 1),
      );

      final rrule = rule.toRfc5545String();
      expect(rrule, contains('INTERVAL=2'));
    });

    test('should serialize with count', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        count: 10,
        startDate: DateTime(2024, 1, 1),
      );

      final rrule = rule.toRfc5545String();
      expect(rrule, contains('COUNT=10'));
    });

    test('should serialize with UNTIL date', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      final rrule = rule.toRfc5545String();
      expect(rrule, contains('UNTIL=20241231'));
    });

    test('should parse from RFC 5545 format', () {
      final parsed = RecurrenceRule.fromRfc5545(
        'FREQ=WEEKLY;BYDAY=TU,TH',
        DateTime(2024, 1, 1),
      );

      expect(parsed.frequency, RecurrenceFrequency.weekly);
      expect(parsed.byDays, contains(WeekDay.tuesday));
      expect(parsed.byDays, contains(WeekDay.thursday));
    });

    test('should round-trip RFC 5545', () {
      final original = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        byMonthDays: [15],
        interval: 2,
        startDate: DateTime(2024, 1, 1),
        count: 12,
      );

      final rrule = original.toRfc5545String();
      final parsed = RecurrenceRule.fromRfc5545(rrule, DateTime(2024, 1, 1));

      expect(parsed.frequency, original.frequency);
      expect(parsed.interval, original.interval);
      expect(parsed.byMonthDays, original.byMonthDays);
      expect(parsed.count, original.count);
    });
  });

  group('RecurrenceRule - JSON', () {
    test('should serialize to JSON', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.monday],
        startDate: DateTime(2024, 1, 1),
      );

      final json = rule.toJson();
      expect(json['frequency'], RecurrenceFrequency.weekly.index);
      expect(json['startDate'], '2024-01-01T00:00:00.000');
    });

    test('should deserialize from JSON', () {
      final json = {
        'frequency': 1, // weekly
        'interval': 1,
        'byDays': [0], // monday
        'byMonthDays': <int>[],
        'byMonths': <int>[],
        'startDate': '2024-01-01T00:00:00.000',
        'exceptionDates': <String>[],
      };

      final rule = RecurrenceRule.fromJson(json);
      expect(rule.frequency, RecurrenceFrequency.weekly);
      expect(rule.byDays, contains(WeekDay.monday));
    });

    test('should round-trip JSON', () {
      final original = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        byDays: [WeekDay.friday],
        weekPosition: -1,
        startDate: DateTime(2024, 1, 1),
        timezone: 'America/Mexico_City',
      );

      final json = original.toJson();
      final restored = RecurrenceRule.fromJson(json);

      expect(restored.frequency, original.frequency);
      expect(restored.byDays, original.byDays);
      expect(restored.weekPosition, original.weekPosition);
      expect(restored.timezone, original.timezone);
    });
  });

  group('RecurrenceRule - copyWith', () {
    test('should copy with modifications', () {
      final original = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
      );

      final copy = original.copyWith(interval: 2);

      expect(copy.frequency, original.frequency);
      expect(copy.interval, 2);
      expect(copy.startDate, original.startDate);
    });

    test('should clear optional fields', () {
      final original = RecurrenceRule(
        frequency: RecurrenceFrequency.monthly,
        weekPosition: 1,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );

      final copy = original.copyWith(
        clearWeekPosition: true,
        clearEndDate: true,
      );

      expect(copy.weekPosition, isNull);
      expect(copy.endDate, isNull);
    });
  });

  group('RecurrenceRule - Factory methods', () {
    test('workdays should include Mon-Fri', () {
      final rule = RecurrenceRule.workdays(startDate: DateTime(2024, 1, 1));

      expect(rule.byDays.length, 5);
      expect(rule.byDays, contains(WeekDay.monday));
      expect(rule.byDays, contains(WeekDay.friday));
      expect(rule.byDays, isNot(contains(WeekDay.saturday)));
    });

    test('weekends should include Sat-Sun', () {
      final rule = RecurrenceRule.weekends(startDate: DateTime(2024, 1, 1));

      expect(rule.byDays.length, 2);
      expect(rule.byDays, contains(WeekDay.saturday));
      expect(rule.byDays, contains(WeekDay.sunday));
    });

    test('biweekly should have interval 2', () {
      final rule = RecurrenceRule.biweekly(startDate: DateTime(2024, 1, 1));

      expect(rule.frequency, RecurrenceFrequency.weekly);
      expect(rule.interval, 2);
    });

    test('quarterly should have interval 3', () {
      final rule = RecurrenceRule.quarterly(startDate: DateTime(2024, 1, 1));

      expect(rule.frequency, RecurrenceFrequency.monthly);
      expect(rule.interval, 3);
    });

    test('lastOfMonth should use -1', () {
      final rule = RecurrenceRule.lastOfMonth(startDate: DateTime(2024, 1, 1));

      expect(rule.byMonthDays, contains(-1));
    });
  });

  group('RecurrenceRule - Helper methods', () {
    test('getIsoWeekNumber should calculate correctly', () {
      // Jan 1, 2024 is in week 1 (Monday)
      expect(RecurrenceRule.getIsoWeekNumber(DateTime(2024, 1, 1)), 1);

      // Dec 31, 2024 is in week 1 of 2025
      expect(RecurrenceRule.getIsoWeekNumber(DateTime(2024, 12, 31)), 1);
    });

    test('getWeekParity should alternate', () {
      final parityWeek1 = RecurrenceRule.getWeekParity(DateTime(2024, 1, 1));
      final parityWeek2 = RecurrenceRule.getWeekParity(DateTime(2024, 1, 8));

      expect(parityWeek1, isNot(parityWeek2));
    });

    test('getLastDayOfMonth should handle all months', () {
      expect(RecurrenceRule.getLastDayOfMonth(2024, 1).day, 31);
      expect(RecurrenceRule.getLastDayOfMonth(2024, 2).day, 29); // Leap year
      expect(RecurrenceRule.getLastDayOfMonth(2025, 2).day, 28); // Non-leap
      expect(RecurrenceRule.getLastDayOfMonth(2024, 4).day, 30);
    });

    test('getNthWeekdayOfMonth should find correct day', () {
      // First Monday of Jan 2024
      final firstMon = RecurrenceRule.getNthWeekdayOfMonth(2024, 1, 1, 1);
      expect(firstMon, DateTime(2024, 1, 1));

      // Last Friday of Jan 2024
      final lastFri = RecurrenceRule.getNthWeekdayOfMonth(2024, 1, 5, -1);
      expect(lastFri, DateTime(2024, 1, 26));
    });

    test('adjustDayForMonth should cap at last day', () {
      expect(RecurrenceRule.adjustDayForMonth(31, 2024, 2), 29); // Feb 2024
      expect(RecurrenceRule.adjustDayForMonth(31, 2025, 2), 28); // Feb 2025
      expect(RecurrenceRule.adjustDayForMonth(31, 2024, 4), 30); // April
    });
  });

  group('RecurrenceRule - Equality', () {
    test('should be equal for same properties', () {
      final rule1 = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.monday, WeekDay.friday],
        startDate: DateTime(2024, 1, 1),
      );

      final rule2 = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        byDays: [WeekDay.monday, WeekDay.friday],
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule1, equals(rule2));
      expect(rule1.hashCode, equals(rule2.hashCode));
    });

    test('should not be equal for different properties', () {
      final rule1 = RecurrenceRule(
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2024, 1, 1),
      );

      final rule2 = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2024, 1, 1),
      );

      expect(rule1, isNot(equals(rule2)));
    });
  });
}
