import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/task_finance_link.dart';

void main() {
  group('TaskFinanceLink', () {
    test('should create valid task finance link', () {
      final link = TaskFinanceLink(
        id: 'test-id',
        taskId: 'task-123',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        createdAt: DateTime.now(),
        autoCreateTransaction: true,
      );

      expect(link.id, 'test-id');
      expect(link.taskId, 'task-123');
      expect(link.impactType, FinancialImpactType.cost);
      expect(link.estimatedAmount, 50.0);
      expect(link.categoryId, 'cat-1');
      expect(link.autoCreateTransaction, true);
      expect(link.deleted, false);
    });

    test('should identify linked status correctly', () {
      final unlinked = TaskFinanceLink(
        id: 'unlinked',
        taskId: 'task-1',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        createdAt: DateTime.now(),
      );

      final linked = TaskFinanceLink(
        id: 'linked',
        taskId: 'task-2',
        impactType: FinancialImpactType.income,
        estimatedAmount: 100.0,
        actualTransactionId: 'txn-456',
        categoryId: 'cat-2',
        createdAt: DateTime.now(),
        linkedAt: DateTime.now(),
      );

      expect(unlinked.isLinked, false);
      expect(linked.isLinked, true);
    });

    test('should serialize to/from Firestore correctly', () {
      final original = TaskFinanceLink(
        id: 'test-firestore',
        taskId: 'task-789',
        impactType: FinancialImpactType.saving,
        estimatedAmount: 75.25,
        actualTransactionId: 'txn-123',
        categoryId: 'cat-1',
        note: 'Test note',
        createdAt: DateTime(2024, 1, 1),
        linkedAt: DateTime(2024, 1, 2),
        deleted: false,
        autoCreateTransaction: true,
      );

      // Convert to Firestore
      final firestoreData = original.toFirestore();

      expect(firestoreData['id'], 'test-firestore');
      expect(firestoreData['taskId'], 'task-789');
      expect(firestoreData['impactType'], 'saving');
      expect(firestoreData['estimatedAmount'], 75.25);
      expect(firestoreData['actualTransactionId'], 'txn-123');
      expect(firestoreData['categoryId'], 'cat-1');
      expect(firestoreData['note'], 'Test note');
      expect(firestoreData['deleted'], false);
      expect(firestoreData['autoCreateTransaction'], true);

      // Convert from Firestore
      final restored = TaskFinanceLink.fromFirestore(
        'test-firestore',
        firestoreData,
      );

      expect(restored.id, original.id);
      expect(restored.taskId, original.taskId);
      expect(restored.impactType, original.impactType);
      expect(restored.estimatedAmount, original.estimatedAmount);
      expect(restored.actualTransactionId, original.actualTransactionId);
      expect(restored.categoryId, original.categoryId);
      expect(restored.note, original.note);
      expect(restored.deleted, original.deleted);
      expect(restored.autoCreateTransaction, original.autoCreateTransaction);
    });

    test('should create copy with modified fields', () {
      final original = TaskFinanceLink(
        id: 'test-copy',
        taskId: 'task-1',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        createdAt: DateTime.now(),
      );

      final copy = original.copyWith(
        estimatedAmount: 75.0,
        actualTransactionId: 'txn-999',
        linkedAt: DateTime.now(),
      );

      expect(copy.estimatedAmount, 75.0);
      expect(copy.actualTransactionId, 'txn-999');
      expect(copy.linkedAt, isNotNull);
      expect(copy.id, original.id); // Unchanged
      expect(copy.taskId, original.taskId);
      expect(copy.impactType, original.impactType);
    });

    test('should handle all impact types', () {
      for (final impactType in FinancialImpactType.values) {
        final link = TaskFinanceLink(
          id: 'test-${impactType.name}',
          taskId: 'task-1',
          impactType: impactType,
          estimatedAmount: 50.0,
          categoryId: 'cat-1',
          createdAt: DateTime.now(),
        );

        expect(link.impactType, impactType);

        final firestoreData = link.toFirestore();
        expect(firestoreData['impactType'], impactType.name);

        final restored = TaskFinanceLink.fromFirestore('test', firestoreData);
        expect(restored.impactType, impactType);
      }
    });

    test('should handle null optional fields', () {
      final link = TaskFinanceLink(
        id: 'test-nulls',
        taskId: 'task-1',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(link.actualTransactionId, isNull);
      expect(link.note, isNull);
      expect(link.linkedAt, isNull);

      final firestoreData = link.toFirestore();
      final restored = TaskFinanceLink.fromFirestore('test-nulls', firestoreData);

      expect(restored.actualTransactionId, isNull);
      expect(restored.note, isNull);
      expect(restored.linkedAt, isNull);
    });

    test('should handle default values correctly', () {
      final link = TaskFinanceLink(
        id: 'defaults',
        taskId: 'task-1',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        createdAt: DateTime.now(),
      );

      expect(link.deleted, false);
      expect(link.autoCreateTransaction, false);
    });

    test('should handle linking a transaction', () {
      final unlinked = TaskFinanceLink(
        id: 'link-test',
        taskId: 'task-1',
        impactType: FinancialImpactType.cost,
        estimatedAmount: 50.0,
        categoryId: 'cat-1',
        createdAt: DateTime.now(),
      );

      expect(unlinked.isLinked, false);

      final now = DateTime.now();
      final linked = unlinked.copyWith(
        actualTransactionId: 'txn-123',
        linkedAt: now,
      );

      expect(linked.isLinked, true);
      expect(linked.actualTransactionId, 'txn-123');
      expect(linked.linkedAt, now);
    });

    test('should handle unlinking a transaction', () {
      final linked = TaskFinanceLink(
        id: 'unlink-test',
        taskId: 'task-1',
        impactType: FinancialImpactType.income,
        estimatedAmount: 100.0,
        actualTransactionId: 'txn-123',
        categoryId: 'cat-1',
        createdAt: DateTime.now(),
        linkedAt: DateTime.now(),
      );

      expect(linked.isLinked, true);

      // Note: copyWith doesn't support setting to null explicitly
      // In real code, you'd create a new instance
      final unlinked = TaskFinanceLink(
        id: linked.id,
        taskId: linked.taskId,
        impactType: linked.impactType,
        estimatedAmount: linked.estimatedAmount,
        categoryId: linked.categoryId,
        createdAt: linked.createdAt,
        deleted: linked.deleted,
        autoCreateTransaction: linked.autoCreateTransaction,
      );

      expect(unlinked.isLinked, false);
      expect(unlinked.actualTransactionId, isNull);
    });
  });
}
