import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/sync_metadata.dart';

void main() {
  group('SyncMetadata Model Tests', () {
    test('SyncMetadata creation', () {
      final now = DateTime(2024, 1, 1);
      final metadata = SyncMetadata(
        recordId: 'rec-123',
        recordType: 'task',
        lastLocalUpdate: now,
      );

      expect(metadata.recordId, 'rec-123');
      expect(metadata.recordType, 'task');
      expect(metadata.lastLocalUpdate, now);
      expect(metadata.isPendingSync, true);
      expect(metadata.hasConflict, false);
      expect(metadata.syncAttempts, 0);
    });

    test('isPendingSync logic', () {
      final now = DateTime(2024, 1, 1);
      final metadata = SyncMetadata(
        recordId: 'rec-123',
        recordType: 'task',
        lastLocalUpdate: now,
        lastCloudSync: now.subtract(const Duration(minutes: 5)),
      );

      expect(metadata.isPendingSync, true);

      final syncedMetadata = metadata.copyWith(
        lastCloudSync: now.add(const Duration(minutes: 5)),
        isPendingSync: false,
      );
      expect(syncedMetadata.isPendingSync, false);
    });

    test('copyWith creates updated instance', () {
      final metadata = SyncMetadata(
        recordId: 'rec-123',
        recordType: 'task',
        lastLocalUpdate: DateTime(2024, 1, 1),
      );

      final copy = metadata.copyWith(syncAttempts: 3, hasConflict: true);

      expect(copy.syncAttempts, 3);
      expect(copy.hasConflict, true);
      expect(copy.recordId, metadata.recordId);
    });

    test('toJson and fromJson work correctly', () {
      final metadata = SyncMetadata(
        recordId: 'rec-123',
        recordType: 'note',
        lastLocalUpdate: DateTime(2024, 1, 1, 10, 0),
        lastCloudSync: DateTime(2024, 1, 1, 9, 0),
        syncAttempts: 2,
        lastSyncError: 'Network error',
      );

      final json = metadata.toJson();
      final restored = SyncMetadata.fromJson(json);

      expect(restored.recordId, metadata.recordId);
      expect(restored.recordType, metadata.recordType);
      expect(restored.lastLocalUpdate, metadata.lastLocalUpdate);
      expect(restored.lastCloudSync, metadata.lastCloudSync);
      expect(restored.syncAttempts, metadata.syncAttempts);
      expect(restored.lastSyncError, metadata.lastSyncError);
    });
  });
}
