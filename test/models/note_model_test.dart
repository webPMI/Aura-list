import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/note_model.dart';
import 'dart:convert';

void main() {
  group('Note Model Unit Tests', () {
    final now = DateTime.now();

    test('Note creation and checklist logic', () {
      final note = Note(
        title: 'Checklist Note',
        createdAt: now,
        contentType: 'checklist',
        checklist: [
          ChecklistItem(text: 'Item 1', isCompleted: true),
          ChecklistItem(text: 'Item 2', isCompleted: false),
        ],
      );

      expect(note.title, 'Checklist Note');
      expect(note.hasChecklist, true);
      expect(note.checklistTotal, 2);
      expect(note.checklistCompleted, 1);
      expect(note.checklistProgress, 0.5);
      expect(note.checklistProgressText, '1/2');
    });

    test('Rich text extraction logic', () {
      final deltaJson = jsonEncode({
        'ops': [
          {'insert': 'Hello '},
          {
            'insert': 'World',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ],
      });

      final note = Note(
        title: 'Rich Note',
        createdAt: now,
        contentType: 'rich',
        richContent: deltaJson,
      );

      expect(note.isRichText, true);
      expect(note.displayContent, 'Hello World');
    });

    test('Serialization to/from Firestore', () {
      final note = Note(
        title: 'Firestore Note',
        content: 'Some content',
        createdAt: now,
        color: '#FF0000',
        tags: ['test', 'unit'],
      );

      final json = note.toFirestore();
      final restored = Note.fromFirestore('note-123', json);

      expect(restored.firestoreId, 'note-123');
      expect(restored.title, note.title);
      expect(restored.content, note.content);
      expect(restored.color, note.color);
      expect(restored.tags, containsAll(['test', 'unit']));
    });

    test('Note.quick factory', () {
      final note = Note.quick('This is a quick note\nwith some more text');

      expect(note.title, 'This is a quick note');
      expect(note.content, contains('with some more text'));
      expect(note.color, '#FFFFFF');
    });

    test('updateInPlace and copyWith', () {
      final note = Note(title: 'Original', createdAt: now);

      // copyWith
      final copy = note.copyWith(title: 'Copy');
      expect(copy.title, 'Copy');
      expect(note.title, 'Original');

      // updateInPlace
      note.updateInPlace(title: 'Updated', isPinned: true);
      expect(note.title, 'Updated');
      expect(note.isPinned, true);
    });
  });
}
