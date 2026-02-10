import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/user_preferences.dart';

void main() {
  group('UserPreferences Model Tests', () {
    test('UserPreferences creation with default values', () {
      final prefs = UserPreferences();

      expect(prefs.odId, 'default');
      expect(prefs.hasAcceptedTerms, false);
      expect(prefs.hasAcceptedPrivacy, false);
      expect(prefs.notificationsEnabled, false);
      expect(prefs.calendarSyncEnabled, false);
      expect(prefs.cloudSyncEnabled, false);
      expect(prefs.syncOnMobileData, true);
      expect(prefs.syncDebounceMs, 3000);
      expect(prefs.collectionLastSync, isEmpty);
    });

    test('hasAcceptedAll returns true when both accepted', () {
      final prefs = UserPreferences(
        hasAcceptedTerms: true,
        hasAcceptedPrivacy: true,
      );

      expect(prefs.hasAcceptedAll, true);
    });

    test('hasAcceptedAll returns false when terms not accepted', () {
      final prefs = UserPreferences(
        hasAcceptedTerms: false,
        hasAcceptedPrivacy: true,
      );

      expect(prefs.hasAcceptedAll, false);
    });

    test('hasAcceptedAll returns false when privacy not accepted', () {
      final prefs = UserPreferences(
        hasAcceptedTerms: true,
        hasAcceptedPrivacy: false,
      );

      expect(prefs.hasAcceptedAll, false);
    });

    test('acceptTerms sets hasAcceptedTerms and timestamp', () {
      final prefs = UserPreferences();
      final beforeAccept = DateTime.now();

      prefs.acceptTerms();

      expect(prefs.hasAcceptedTerms, true);
      expect(prefs.termsAcceptedAt, isNotNull);
      expect(prefs.termsAcceptedAt!.isAfter(beforeAccept.subtract(Duration(seconds: 1))), true);
    });

    test('acceptPrivacy sets hasAcceptedPrivacy and timestamp', () {
      final prefs = UserPreferences();
      final beforeAccept = DateTime.now();

      prefs.acceptPrivacy();

      expect(prefs.hasAcceptedPrivacy, true);
      expect(prefs.privacyAcceptedAt, isNotNull);
      expect(prefs.privacyAcceptedAt!.isAfter(beforeAccept.subtract(Duration(seconds: 1))), true);
    });

    test('acceptAll sets both terms and privacy', () {
      final prefs = UserPreferences();

      prefs.acceptAll();

      expect(prefs.hasAcceptedTerms, true);
      expect(prefs.hasAcceptedPrivacy, true);
      expect(prefs.termsAcceptedAt, isNotNull);
      expect(prefs.privacyAcceptedAt, isNotNull);
      expect(prefs.hasAcceptedAll, true);
    });

    test('revokeAll resets all consent fields', () {
      final prefs = UserPreferences(
        hasAcceptedTerms: true,
        hasAcceptedPrivacy: true,
        termsAcceptedAt: DateTime.now(),
        privacyAcceptedAt: DateTime.now(),
        notificationsEnabled: true,
        calendarSyncEnabled: true,
        cloudSyncEnabled: true,
      );

      prefs.revokeAll();

      expect(prefs.hasAcceptedTerms, false);
      expect(prefs.hasAcceptedPrivacy, false);
      expect(prefs.termsAcceptedAt, isNull);
      expect(prefs.privacyAcceptedAt, isNull);
      expect(prefs.notificationsEnabled, false);
      expect(prefs.calendarSyncEnabled, false);
      expect(prefs.cloudSyncEnabled, false);
    });

    test('setCollectionLastSync stores sync timestamp', () {
      final prefs = UserPreferences();
      final syncTime = DateTime(2024, 1, 1, 12, 0);

      prefs.setCollectionLastSync('tasks', syncTime);

      expect(prefs.collectionLastSync['tasks'], isNotNull);
      expect(prefs.getCollectionLastSync('tasks'), syncTime);
    });

    test('getCollectionLastSync returns null for unknown collection', () {
      final prefs = UserPreferences();

      expect(prefs.getCollectionLastSync('unknown'), isNull);
    });

    test('getCollectionLastSync parses ISO string correctly', () {
      final prefs = UserPreferences();
      final syncTime = DateTime(2024, 1, 15, 10, 30);

      prefs.setCollectionLastSync('notes', syncTime);
      final retrieved = prefs.getCollectionLastSync('notes');

      expect(retrieved, isNotNull);
      expect(retrieved!.year, 2024);
      expect(retrieved.month, 1);
      expect(retrieved.day, 15);
      expect(retrieved.hour, 10);
      expect(retrieved.minute, 30);
    });

    test('toJson converts to Map correctly', () {
      final prefs = UserPreferences(
        hasAcceptedTerms: true,
        hasAcceptedPrivacy: true,
        termsAcceptedAt: DateTime(2024, 1, 1),
        privacyAcceptedAt: DateTime(2024, 1, 2),
        notificationsEnabled: true,
        calendarSyncEnabled: false,
        syncOnMobileData: false,
        syncDebounceMs: 5000,
        cloudSyncEnabled: true,
      );

      final json = prefs.toJson();

      expect(json['hasAcceptedTerms'], true);
      expect(json['hasAcceptedPrivacy'], true);
      expect(json['termsAcceptedAt'], isNotNull);
      expect(json['privacyAcceptedAt'], isNotNull);
      expect(json['notificationsEnabled'], true);
      expect(json['calendarSyncEnabled'], false);
      expect(json['syncOnMobileData'], false);
      expect(json['syncDebounceMs'], 5000);
      expect(json['cloudSyncEnabled'], true);
    });

    test('fromJson creates UserPreferences from Map', () {
      final json = {
        'hasAcceptedTerms': true,
        'hasAcceptedPrivacy': true,
        'termsAcceptedAt': '2024-01-01T00:00:00.000',
        'privacyAcceptedAt': '2024-01-02T00:00:00.000',
        'notificationsEnabled': true,
        'calendarSyncEnabled': false,
        'lastSyncTimestamp': '2024-01-03T12:00:00.000',
        'syncOnMobileData': false,
        'syncDebounceMs': 5000,
        'cloudSyncEnabled': true,
      };

      final prefs = UserPreferences.fromJson(json);

      expect(prefs.hasAcceptedTerms, true);
      expect(prefs.hasAcceptedPrivacy, true);
      expect(prefs.termsAcceptedAt, DateTime(2024, 1, 1));
      expect(prefs.privacyAcceptedAt, DateTime(2024, 1, 2));
      expect(prefs.notificationsEnabled, true);
      expect(prefs.calendarSyncEnabled, false);
      expect(prefs.lastSyncTimestamp, DateTime(2024, 1, 3, 12, 0));
      expect(prefs.syncOnMobileData, false);
      expect(prefs.syncDebounceMs, 5000);
      expect(prefs.cloudSyncEnabled, true);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final prefs = UserPreferences.fromJson(json);

      expect(prefs.hasAcceptedTerms, false);
      expect(prefs.hasAcceptedPrivacy, false);
      expect(prefs.notificationsEnabled, false);
      expect(prefs.calendarSyncEnabled, false);
      expect(prefs.syncOnMobileData, true);
      expect(prefs.syncDebounceMs, 3000);
      expect(prefs.cloudSyncEnabled, false);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = UserPreferences(
        hasAcceptedTerms: true,
        notificationsEnabled: false,
        syncDebounceMs: 3000,
      );

      final copy = original.copyWith(
        notificationsEnabled: true,
        syncDebounceMs: 5000,
      );

      expect(copy.hasAcceptedTerms, true); // Unchanged
      expect(copy.notificationsEnabled, true); // Updated
      expect(copy.syncDebounceMs, 5000); // Updated
      expect(original.notificationsEnabled, false); // Original unchanged
    });

    test('copyWith preserves collectionLastSync', () {
      final original = UserPreferences();
      original.setCollectionLastSync('tasks', DateTime(2024, 1, 1));

      final copy = original.copyWith(notificationsEnabled: true);

      expect(copy.getCollectionLastSync('tasks'), DateTime(2024, 1, 1));
    });

    test('round-trip toJson and fromJson preserves data', () {
      final original = UserPreferences(
        hasAcceptedTerms: true,
        hasAcceptedPrivacy: true,
        termsAcceptedAt: DateTime(2024, 1, 1, 10, 0),
        privacyAcceptedAt: DateTime(2024, 1, 2, 11, 0),
        notificationsEnabled: true,
        calendarSyncEnabled: true,
        lastSyncTimestamp: DateTime(2024, 1, 3, 12, 0),
        syncOnMobileData: false,
        syncDebounceMs: 5000,
        cloudSyncEnabled: true,
      );

      final json = original.toJson();
      final restored = UserPreferences.fromJson(json);

      expect(restored.hasAcceptedTerms, original.hasAcceptedTerms);
      expect(restored.hasAcceptedPrivacy, original.hasAcceptedPrivacy);
      expect(restored.notificationsEnabled, original.notificationsEnabled);
      expect(restored.calendarSyncEnabled, original.calendarSyncEnabled);
      expect(restored.syncOnMobileData, original.syncOnMobileData);
      expect(restored.syncDebounceMs, original.syncDebounceMs);
      expect(restored.cloudSyncEnabled, original.cloudSyncEnabled);
    });
  });
}
