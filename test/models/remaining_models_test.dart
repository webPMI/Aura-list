import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/notebook_model.dart';
import 'package:checklist_app/models/sync_metadata.dart';
import 'package:checklist_app/models/task_history.dart';

void main() {
  group('Remaining Models Unit Tests', () {
    final now = DateTime.now();

    group('Notebook Model', () {
      test('Notebook creation and serialization', () {
        final notebook = Notebook(
          name: 'Work',
          icon: '💼',
          color: '#1E88E5',
          createdAt: now,
          isFavorited: true,
        );

        expect(notebook.name, 'Work');
        expect(notebook.isFavorited, true);

        final json = notebook.toFirestore();
        final restored = Notebook.fromFirestore('nb-1', json);

        expect(restored.firestoreId, 'nb-1');
        expect(restored.name, 'Work');
        expect(restored.icon, '💼');
      });

      test('updateInPlace and copyWith', () {
        final notebook = Notebook(name: 'Test', createdAt: now);

        final copy = notebook.copyWith(name: 'Copy');
        expect(copy.name, 'Copy');

        notebook.updateInPlace(name: 'Updated', isFavorited: true);
        expect(notebook.name, 'Updated');
        expect(notebook.isFavorited, true);
      });
    });

    group('SyncMetadata Model', () {
      test('Sync state management', () {
        final meta = SyncMetadata.forTask('task-123');

        expect(meta.recordId, 'task-123');
        expect(meta.isPendingSync, true);
        expect(meta.syncAttempts, 0);

        meta.recordSyncFailure('Network Error');
        expect(meta.syncAttempts, 1);
        expect(meta.lastSyncError, 'Network Error');

        meta.markSynced();
        expect(meta.isPendingSync, false);
        expect(meta.syncAttempts, 0);
        expect(meta.lastCloudSync, isNotNull);
      });

      test('Conflict handling', () {
        final meta = SyncMetadata.forTask('task-123');
        final remoteTime = now.subtract(const Duration(minutes: 5));

        meta.markConflict(remoteTime);
        expect(meta.hasConflict, true);
        expect(meta.remoteVersionAt, remoteTime);

        meta.resolveConflict();
        expect(meta.hasConflict, false);
      });
    });

    group('TaskHistory Model', () {
      test('History marking and normalization', () {
        final history = TaskHistory.forToday(taskId: '123');
        final todayMidnight = TaskHistory.normalizeDate(DateTime.now());

        expect(history.date, todayMidnight);
        expect(history.wasCompleted, false);

        history.markCompleted();
        expect(history.wasCompleted, true);
        expect(history.completedAt, isNotNull);

        history.markIncomplete();
        expect(history.wasCompleted, false);
        expect(history.completedAt, isNull);
      });

      test('Serialization', () {
        final history = TaskHistory(
          taskId: '123',
          date: now,
          wasCompleted: true,
          completedAt: now,
        );

        final json = history.toFirestore();
        final restored = TaskHistory.fromFirestore('hist-1', json);

        expect(restored.firestoreId, 'hist-1');
        expect(restored.wasCompleted, true);
        expect(restored.taskId, '123');
      });
    });
    group('Consistency check with database_test.dart', () {
      // The original database_test.dart had simple checks.
      // Our new tests are more comprehensive but we ensure no regressions in basic usage.
      test('TaskHistory normalizeDate consistency', () {
        final date = DateTime(2024, 12, 25, 10, 30);
        final normalized = TaskHistory.normalizeDate(date);
        expect(normalized.year, 2024);
        expect(normalized.month, 12);
        expect(normalized.day, 25);
        expect(normalized.hour, 0);
      });
    });
  });
}
