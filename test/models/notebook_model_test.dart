import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/models/notebook_model.dart';

void main() {
  group('Notebook Model Tests', () {
    test('Notebook creation with required fields', () {
      final now = DateTime(2024, 1, 1);
      final notebook = Notebook(name: 'My Notebook', createdAt: now);

      expect(notebook.name, 'My Notebook');
      expect(notebook.createdAt, now);
      expect(notebook.updatedAt, now);
      expect(notebook.icon, '📁');
      expect(notebook.color, '#6750A4');
      expect(notebook.isFavorited, false);
      expect(notebook.parentId, isNull);
    });

    test('copyWith creates updated instance', () {
      final now = DateTime(2024, 1, 1);
      final original = Notebook(
        name: 'Original',
        createdAt: now,
        parentId: 'parent-123',
      );

      final copy = original.copyWith(
        name: 'Updated',
        isFavorited: true,
        clearParentId: true,
      );

      expect(copy.name, 'Updated');
      expect(copy.isFavorited, true);
      expect(copy.parentId, isNull);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt.isAfter(original.updatedAt), true);
    });

    test('toFirestore and fromFirestore work correctly', () {
      final now = DateTime(2024, 1, 1, 12, 0);
      final original = Notebook(
        firestoreId: 'fs-123',
        name: 'Test Notebook',
        icon: '📝',
        color: '#FF0000',
        createdAt: now,
        updatedAt: now.add(const Duration(days: 1)),
        isFavorited: true,
        parentId: 'parent-456',
      );

      final firestore = original.toFirestore();
      final restored = Notebook.fromFirestore('fs-123', firestore);

      expect(restored.firestoreId, original.firestoreId);
      expect(restored.name, original.name);
      expect(restored.icon, original.icon);
      expect(restored.color, original.color);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(restored.isFavorited, original.isFavorited);
      expect(restored.parentId, original.parentId);
    });

    test('updateInPlace modifies existing instance', () {
      final notebook = Notebook(
        name: 'Original',
        createdAt: DateTime(2024, 1, 1),
      );

      notebook.updateInPlace(name: 'Modified', isFavorited: true);

      expect(notebook.name, 'Modified');
      expect(notebook.isFavorited, true);
    });

    test('getColorName returns correct names', () {
      expect(Notebook.getColorName('#6750A4'), 'Morado');
      expect(Notebook.getColorName('#1E88E5'), 'Azul');
      expect(Notebook.getColorName('#43A047'), 'Verde');
      expect(
        Notebook.getColorName('#FFFFFF'),
        'Morado',
      ); // Unknown defaults to Morado
    });

    test('Notebook has predefined options', () {
      expect(Notebook.iconOptions, isNotEmpty);
      expect(Notebook.colorOptions, isNotEmpty);
    });
  });
}
