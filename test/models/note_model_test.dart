import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/note_model.dart';

void main() {
  group('Note Model Tests', () {
    test('Note creation with required fields', () {
      final note = Note(
        title: 'Test Note',
        content: 'This is a test note',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(note.title, 'Test Note');
      expect(note.content, 'This is a test note');
      expect(note.createdAt, DateTime(2024, 1, 1));
      expect(note.color, '#FFFFFF'); // Default color
      expect(note.isPinned, false);
      expect(note.tags, isEmpty);
      expect(note.deleted, false);
    });

    test('Note with taskId is linked to task', () {
      final note = Note(
        title: 'Linked Note',
        content: 'Content',
        createdAt: DateTime.now(),
        taskId: 'task-123',
      );

      expect(note.isLinkedToTask, true);
      expect(note.taskId, 'task-123');
    });

    test('Note without taskId is independent', () {
      final note = Note(
        title: 'Independent Note',
        content: 'Content',
        createdAt: DateTime.now(),
      );

      expect(note.isLinkedToTask, false);
      expect(note.taskId, isNull);
    });

    test('contentPreview returns first 100 chars', () {
      final shortContent = 'Short note';
      final longContent = 'A' * 150;

      final shortNote = Note(
        title: 'Short',
        content: shortContent,
        createdAt: DateTime.now(),
      );

      final longNote = Note(
        title: 'Long',
        content: longContent,
        createdAt: DateTime.now(),
      );

      expect(shortNote.contentPreview, shortContent);
      expect(longNote.contentPreview.length, 100);
      expect(longNote.contentPreview.endsWith('...'), true);
    });

    test('contentPreview returns empty string for empty content', () {
      final note = Note(
        title: 'Empty',
        content: '',
        createdAt: DateTime.now(),
      );

      expect(note.contentPreview, '');
    });

    test('copyWith creates a new Note with updated fields', () {
      final original = Note(
        title: 'Original',
        content: 'Original content',
        createdAt: DateTime(2024, 1, 1),
        color: '#FFFFFF',
        isPinned: false,
      );

      final copy = original.copyWith(
        title: 'Updated',
        isPinned: true,
        color: '#FFFDE7',
      );

      expect(copy.title, 'Updated');
      expect(copy.content, 'Original content'); // Unchanged
      expect(copy.isPinned, true);
      expect(copy.color, '#FFFDE7');
    });

    test('copyWith can clear taskId', () {
      final note = Note(
        title: 'Note',
        content: 'Content',
        createdAt: DateTime.now(),
        taskId: 'task-123',
      );

      final copy = note.copyWith(clearTaskId: true);

      expect(copy.taskId, isNull);
      expect(note.taskId, 'task-123'); // Original unchanged
    });

    test('toFirestore and fromFirestore work correctly', () {
      final original = Note(
        firestoreId: 'fs-123',
        title: 'Test Note',
        content: 'Test content',
        createdAt: DateTime(2024, 1, 1, 12, 0),
        updatedAt: DateTime(2024, 1, 2, 12, 0),
        taskId: 'task-456',
        color: '#E8F5E9',
        isPinned: true,
        tags: ['work', 'important'],
        deleted: false,
      );

      final firestore = original.toFirestore();
      final restored = Note.fromFirestore('fs-123', firestore);

      expect(restored.firestoreId, original.firestoreId);
      expect(restored.title, original.title);
      expect(restored.content, original.content);
      expect(restored.taskId, original.taskId);
      expect(restored.color, original.color);
      expect(restored.isPinned, original.isPinned);
      expect(restored.tags, original.tags);
      expect(restored.deleted, original.deleted);
    });

    test('Note.quick creates note with auto-generated title', () {
      final note = Note.quick('This is the first line\nSecond line');

      expect(note.title, 'This is the first line');
      expect(note.content, 'This is the first line\nSecond line');
      expect(note.color, '#FFFFFF');
    });

    test('Note.quick truncates long first line for title', () {
      final longLine = 'A' * 100;
      final note = Note.quick('$longLine\nSecond line');

      expect(note.title.length, 50); // 47 chars + '...'
      expect(note.title.endsWith('...'), true);
    });

    test('Note.quick uses yellow color for task notes', () {
      final note = Note.quick('Content', taskId: 'task-123');

      expect(note.color, '#FFFDE7'); // Yellow
      expect(note.taskId, 'task-123');
    });

    test('Note.quick uses default title for empty content', () {
      final note = Note.quick('');

      expect(note.title, 'Nota rapida');
    });

    test('getColorName returns correct name for hex', () {
      expect(Note.getColorName('#FFFFFF'), 'Blanco');
      expect(Note.getColorName('#FFFDE7'), 'Amarillo');
      expect(Note.getColorName('#E8F5E9'), 'Verde');
      expect(Note.getColorName('#E3F2FD'), 'Azul');
      expect(Note.getColorName('#INVALID'), 'Blanco'); // Unknown defaults to Blanco
    });

    test('Note has correct color options', () {
      expect(Note.colorOptions.length, 8);
      expect(Note.colorOptions['Blanco'], '#FFFFFF');
      expect(Note.colorOptions['Amarillo'], '#FFFDE7');
      expect(Note.colorOptions['Verde'], '#E8F5E9');
    });

    test('Note tags can be added', () {
      final note = Note(
        title: 'Tagged Note',
        content: 'Content',
        createdAt: DateTime.now(),
        tags: ['work', 'urgent'],
      );

      expect(note.tags.length, 2);
      expect(note.tags, contains('work'));
      expect(note.tags, contains('urgent'));
    });
  });
}
