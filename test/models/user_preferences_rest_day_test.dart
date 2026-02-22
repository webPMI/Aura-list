import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/user_preferences.dart';

void main() {
  group('UserPreferences Rest Day Field Tests', () {
    test('restDayOfWeek defaults to null', () {
      final prefs = UserPreferences();
      expect(prefs.restDayOfWeek, isNull);
    });

    test('restDayOfWeek can be set to valid weekday (1-7)', () {
      for (int weekday = 1; weekday <= 7; weekday++) {
        final prefs = UserPreferences(restDayOfWeek: weekday);
        expect(prefs.restDayOfWeek, weekday);
      }
    });

    test('restDayOfWeek can be set to null (no rest day)', () {
      final prefs = UserPreferences(restDayOfWeek: null);
      expect(prefs.restDayOfWeek, isNull);
    });

    test('copyWith preserves restDayOfWeek when not changed', () {
      final prefs = UserPreferences(restDayOfWeek: 6);
      final copied = prefs.copyWith(notificationsEnabled: true);

      expect(copied.restDayOfWeek, 6);
      expect(copied.notificationsEnabled, true);
    });

    test('copyWith can update restDayOfWeek', () {
      final prefs = UserPreferences(restDayOfWeek: 1);
      final updated = prefs.copyWith(restDayOfWeek: 7);

      expect(prefs.restDayOfWeek, 1);
      expect(updated.restDayOfWeek, 7);
    });

    test('copyWith with null restDayOfWeek preserves original value', () {
      // Note: copyWith uses ?? operator, so passing null preserves original
      final prefs = UserPreferences(restDayOfWeek: 5);
      final updated = prefs.copyWith(restDayOfWeek: null);

      expect(prefs.restDayOfWeek, 5);
      expect(updated.restDayOfWeek, 5); // Preserved, not set to null
    });

    test('toFirestore includes restDayOfWeek', () {
      final prefs = UserPreferences(
        restDayOfWeek: 3,
        hasAcceptedTerms: true,
      );

      final json = prefs.toFirestore();

      expect(json['restDayOfWeek'], 3);
      expect(json['hasAcceptedTerms'], true);
      expect(json.containsKey('restDayOfWeek'), true);
    });

    test('toFirestore handles null restDayOfWeek', () {
      final prefs = UserPreferences(
        restDayOfWeek: null,
        hasAcceptedTerms: true,
      );

      final json = prefs.toFirestore();

      expect(json['restDayOfWeek'], isNull);
      expect(json.containsKey('restDayOfWeek'), true);
    });

    test('fromFirestore restores restDayOfWeek', () {
      final json = {
        'hasAcceptedTerms': true,
        'hasAcceptedPrivacy': true,
        'notificationsEnabled': false,
        'calendarSyncEnabled': false,
        'syncOnMobileData': true,
        'syncDebounceMs': 3000,
        'cloudSyncEnabled': false,
        'restDayOfWeek': 4,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      };

      final prefs = UserPreferences.fromFirestore('test-id', json);

      expect(prefs.restDayOfWeek, 4);
      expect(prefs.firestoreId, 'test-id');
    });

    test('fromFirestore handles missing restDayOfWeek (backward compatibility)',
        () {
      final json = {
        'hasAcceptedTerms': true,
        'hasAcceptedPrivacy': false,
        'notificationsEnabled': true,
        'calendarSyncEnabled': false,
        'syncOnMobileData': true,
        'syncDebounceMs': 3000,
        'cloudSyncEnabled': false,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
        // restDayOfWeek intentionally missing
      };

      final prefs = UserPreferences.fromFirestore('test-id', json);

      expect(prefs.restDayOfWeek, isNull);
      expect(prefs.hasAcceptedTerms, true);
    });

    test('fromFirestore handles null restDayOfWeek value', () {
      final json = {
        'hasAcceptedTerms': false,
        'hasAcceptedPrivacy': false,
        'notificationsEnabled': false,
        'calendarSyncEnabled': false,
        'syncOnMobileData': true,
        'syncDebounceMs': 3000,
        'cloudSyncEnabled': false,
        'restDayOfWeek': null,
        'lastUpdatedAt': DateTime.now().toIso8601String(),
      };

      final prefs = UserPreferences.fromFirestore('test-id', json);

      expect(prefs.restDayOfWeek, isNull);
    });

    test('fromJson restores restDayOfWeek', () {
      final json = {
        'hasAcceptedTerms': true,
        'hasAcceptedPrivacy': true,
        'notificationsEnabled': true,
        'calendarSyncEnabled': false,
        'syncOnMobileData': true,
        'syncDebounceMs': 3000,
        'cloudSyncEnabled': true,
        'restDayOfWeek': 2,
      };

      final prefs = UserPreferences.fromJson(json);

      expect(prefs.restDayOfWeek, 2);
    });

    test('fromJson handles missing restDayOfWeek', () {
      final json = {
        'hasAcceptedTerms': false,
        'hasAcceptedPrivacy': false,
        'notificationsEnabled': false,
        'calendarSyncEnabled': false,
        'syncOnMobileData': true,
        'syncDebounceMs': 3000,
        'cloudSyncEnabled': false,
        // restDayOfWeek missing
      };

      final prefs = UserPreferences.fromJson(json);

      expect(prefs.restDayOfWeek, isNull);
    });

    test('toJson includes restDayOfWeek', () {
      final prefs = UserPreferences(
        restDayOfWeek: 7,
        hasAcceptedTerms: true,
      );

      final json = prefs.toJson();

      expect(json['restDayOfWeek'], 7);
      expect(json['hasAcceptedTerms'], true);
    });

    test('toJson handles null restDayOfWeek', () {
      final prefs = UserPreferences(
        restDayOfWeek: null,
        hasAcceptedTerms: false,
      );

      final json = prefs.toJson();

      expect(json['restDayOfWeek'], isNull);
      expect(json.containsKey('restDayOfWeek'), true);
    });

    test('Round-trip serialization preserves restDayOfWeek', () {
      final original = UserPreferences(
        restDayOfWeek: 5,
        hasAcceptedTerms: true,
        notificationsEnabled: true,
        cloudSyncEnabled: false,
      );

      final json = original.toFirestore();
      final restored = UserPreferences.fromFirestore('test-id', json);

      expect(restored.restDayOfWeek, original.restDayOfWeek);
      expect(restored.hasAcceptedTerms, original.hasAcceptedTerms);
      expect(restored.notificationsEnabled, original.notificationsEnabled);
    });

    test('Different rest days for different users', () {
      final user1 = UserPreferences(restDayOfWeek: 1); // Monday
      final user2 = UserPreferences(restDayOfWeek: 6); // Saturday
      final user3 = UserPreferences(restDayOfWeek: 7); // Sunday

      expect(user1.restDayOfWeek, 1);
      expect(user2.restDayOfWeek, 6);
      expect(user3.restDayOfWeek, 7);
      expect(user1.restDayOfWeek != user2.restDayOfWeek, true);
    });

    test('Changing rest day multiple times', () {
      var prefs = UserPreferences(restDayOfWeek: 1);
      expect(prefs.restDayOfWeek, 1);

      prefs = prefs.copyWith(restDayOfWeek: 3);
      expect(prefs.restDayOfWeek, 3);

      prefs = prefs.copyWith(restDayOfWeek: 7);
      expect(prefs.restDayOfWeek, 7);

      // To set to null, create a new instance
      prefs = UserPreferences(
        hasAcceptedTerms: prefs.hasAcceptedTerms,
        hasAcceptedPrivacy: prefs.hasAcceptedPrivacy,
        restDayOfWeek: null,
      );
      expect(prefs.restDayOfWeek, isNull);
    });

    test('restDayOfWeek works with all other preferences', () {
      final prefs = UserPreferences(
        restDayOfWeek: 4,
        hasAcceptedTerms: true,
        hasAcceptedPrivacy: true,
        notificationsEnabled: true,
        calendarSyncEnabled: true,
        syncOnMobileData: false,
        syncDebounceMs: 5000,
        cloudSyncEnabled: true,
      );

      expect(prefs.restDayOfWeek, 4);
      expect(prefs.hasAcceptedTerms, true);
      expect(prefs.hasAcceptedPrivacy, true);
      expect(prefs.notificationsEnabled, true);
      expect(prefs.calendarSyncEnabled, true);
      expect(prefs.syncOnMobileData, false);
      expect(prefs.syncDebounceMs, 5000);
      expect(prefs.cloudSyncEnabled, true);

      // Verify it doesn't interfere with other methods
      expect(prefs.hasAcceptedAll, true);
    });

    test('touch() does not affect restDayOfWeek', () {
      final prefs = UserPreferences(restDayOfWeek: 2);
      final beforeTouch = prefs.restDayOfWeek;

      prefs.touch();

      expect(prefs.restDayOfWeek, beforeTouch);
      expect(prefs.lastUpdatedAt, isNotNull);
    });

    test('revokeAll() does not clear restDayOfWeek', () {
      final prefs = UserPreferences(
        restDayOfWeek: 6,
        hasAcceptedTerms: true,
        hasAcceptedPrivacy: true,
        notificationsEnabled: true,
      );

      prefs.revokeAll();

      // Rest day should remain unchanged
      expect(prefs.restDayOfWeek, 6);

      // But other settings should be cleared
      expect(prefs.hasAcceptedTerms, false);
      expect(prefs.hasAcceptedPrivacy, false);
      expect(prefs.notificationsEnabled, false);
    });
  });
}
