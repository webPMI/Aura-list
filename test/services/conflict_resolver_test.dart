import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/services/conflict_resolver.dart';
import 'package:checklist_app/models/task_model.dart';
import 'package:checklist_app/models/note_model.dart';

void main() {
  group('ConflictResolver Tests', () {
    late ConflictResolver resolver;

    setUp(() {
      resolver = ConflictResolver(
        defaultStrategy: ConflictStrategy.lastWriteWins,
      );
    });

    test('hasConflict returns true for diverging timestamps', () {
      final local = DateTime(2024, 1, 1, 10, 0);
      final remote = DateTime(2024, 1, 1, 11, 0);

      expect(resolver.hasConflict(local, remote), true);
    });

    test('hasConflict returns false for identical timestamps', () {
      final time = DateTime(2024, 1, 1);
      expect(resolver.hasConflict(time, time), false);
    });

    test('resolveTaskConflict: clientWins strategy', () {
      final local = Task(
        title: 'Local',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        lastUpdatedAt: DateTime(2024, 1, 1, 10, 0),
      );
      final remote = Task(
        title: 'Remote',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        lastUpdatedAt: DateTime(2024, 1, 1, 11, 0),
      );

      final result = resolver.resolveTaskConflict(
        local,
        remote,
        strategy: ConflictStrategy.clientWins,
      );

      expect(result.resolved.title, 'Local');
      expect(result.hadConflict, true);
    });

    test('resolveTaskConflict: lastWriteWins strategy', () {
      final local = Task(
        title: 'Local',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        lastUpdatedAt: DateTime(2024, 1, 1, 10, 0),
      );
      final remote = Task(
        title: 'Remote',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        lastUpdatedAt: DateTime(2024, 1, 1, 12, 0),
      );

      final result = resolver.resolveTaskConflict(local, remote);

      expect(result.resolved.title, 'Remote');
      expect(result.strategyUsed, ConflictStrategy.lastWriteWins);
    });

    test('resolveTaskConflict: merge strategy combining fields', () {
      final local = Task(
        title: 'T1',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        lastUpdatedAt: DateTime(2024, 1, 1, 10, 0),
        isCompleted: true,
        priority: 1,
      );
      final remote = Task(
        title: 'T1 Updated',
        type: 'daily',
        createdAt: DateTime(2024, 1, 1),
        lastUpdatedAt: DateTime(2024, 1, 1, 11, 0),
        isCompleted: false,
        priority: 2, // Higher is more priority in merge logic?
      );

      final result = resolver.resolveTaskConflict(
        local,
        remote,
        strategy: ConflictStrategy.merge,
      );

      expect(result.hadConflict, true);
      // Merge logic: isCompleted = local || remote
      expect(result.resolved.isCompleted, true);
      // priority = max(local, remote)
      expect(result.resolved.priority, 2);
    });

    test('resolveNoteConflict: merge strategy concatenating content', () {
      final local = Note(
        title: 'N1',
        content: 'Local content',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1, 10, 0),
      );
      final remote = Note(
        title: 'N1',
        content: 'Remote content',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1, 11, 0),
      );

      final result = resolver.resolveNoteConflict(
        local,
        remote,
        strategy: ConflictStrategy.merge,
      );

      expect(result.resolved.content, contains('Local content'));
      expect(result.resolved.content, contains('Remote content'));
      expect(result.resolved.content, contains('[Contenido sincronizado]'));
    });
  });
}
