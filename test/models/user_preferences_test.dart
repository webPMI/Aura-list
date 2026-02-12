import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/user_preferences.dart';

void main() {
  group('UserPreferences Model Unit Tests', () {
    test('Default values are correct', () {
      final prefs = UserPreferences();
      expect(prefs.hasAcceptedTerms, false);
      expect(prefs.hasAcceptedPrivacy, false);
      expect(prefs.notificationsEnabled, false);
      expect(prefs.cloudSyncEnabled, false);
      expect(prefs.syncOnMobileData, true);
    });

    test('Legal acceptance logic', () {
      final prefs = UserPreferences();
      expect(prefs.hasAcceptedAll, false);

      prefs.acceptTerms();
      expect(prefs.hasAcceptedTerms, true);
      expect(prefs.termsAcceptedAt, isNotNull);
      expect(prefs.hasAcceptedAll, false);

      prefs.acceptPrivacy();
      expect(prefs.hasAcceptedPrivacy, true);
      expect(prefs.privacyAcceptedAt, isNotNull);
      expect(prefs.hasAcceptedAll, true);

      prefs.revokeAll();
      expect(prefs.hasAcceptedAll, false);
      expect(prefs.termsAcceptedAt, isNull);
    });

    test('Collection sync tracking', () {
      final prefs = UserPreferences();
      final now = DateTime.now();

      prefs.setCollectionLastSync('tasks', now);
      final retrieved = prefs.getCollectionLastSync('tasks');

      expect(retrieved, isNotNull);
      expect(retrieved!.toIso8601String(), now.toIso8601String());
      expect(prefs.getCollectionLastSync('notes'), isNull);
    });

    test('Serialization to/from Firestore', () {
      final now = DateTime.now();
      final prefs = UserPreferences(
        hasAcceptedTerms: true,
        termsAcceptedAt: now,
        notificationsEnabled: true,
      );

      final json = prefs.toFirestore();
      final restored = UserPreferences.fromFirestore('test-id', json);

      expect(restored.firestoreId, 'test-id');
      expect(restored.hasAcceptedTerms, true);
      expect(restored.notificationsEnabled, true);
      expect(
        restored.termsAcceptedAt!.toIso8601String(),
        now.toIso8601String(),
      );
    });

    test('copyWith creates modified instance', () {
      final prefs = UserPreferences(notificationsEnabled: false);
      final updated = prefs.copyWith(notificationsEnabled: true);

      expect(updated.notificationsEnabled, true);
      expect(prefs.notificationsEnabled, false);
    });
  });
}
