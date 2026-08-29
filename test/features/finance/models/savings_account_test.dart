import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/savings_account.dart';

/// ============================================================
/// Tests de SavingsAccount
/// Cubre: creación, round-trip Firestore, getters y casos de borde
/// ============================================================
void main() {
  group('SavingsAccount', () {
    test('creation with all fields and defaults', () {
      final account = SavingsAccount(
        id: 'acc-1',
        name: 'Fondo de emergencia',
        type: SavingsAccountType.savings,
        initialBalance: 1000.0,
        currentBalance: 1500.0,
        monthlyContribution: 200.0,
        annualInterestRate: 4.5,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(account.id, 'acc-1');
      expect(account.name, 'Fondo de emergencia');
      expect(account.type, SavingsAccountType.savings);
      expect(account.initialBalance, 1000.0);
      expect(account.currentBalance, 1500.0);
      expect(account.monthlyContribution, 200.0);
      expect(account.annualInterestRate, 4.5);
      expect(account.deleted, false);
      expect(account.icon, 'savings');
      expect(account.color, '#66BB6A');
    });

    test('investment type provides its own icon and color', () {
      final account = SavingsAccount(
        id: 'acc-2',
        name: 'ETF global',
        type: SavingsAccountType.investment,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(account.icon, 'trending_up');
      expect(account.color, '#2196F3');
    });

    test('gainedAmount and totalReturnPercentage', () {
      final account = SavingsAccount(
        id: 'acc-3',
        name: 'Inversión',
        type: SavingsAccountType.investment,
        initialBalance: 1000.0,
        currentBalance: 1250.0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(account.gainedAmount, 250.0);
      expect(account.totalReturnPercentage, closeTo(25.0, 0.001));
    });

    test('totalReturnPercentage is 0 when initial balance is 0', () {
      final account = SavingsAccount(
        id: 'acc-4',
        name: 'Nueva',
        type: SavingsAccountType.savings,
        initialBalance: 0.0,
        currentBalance: 100.0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(account.totalReturnPercentage, 0.0);
    });

    test('toFirestore round-trip preserves all fields', () {
      final original = SavingsAccount(
        id: 'acc-firestore',
        name: 'Cuenta prueba',
        type: SavingsAccountType.investment,
        initialBalance: 500.0,
        currentBalance: 800.0,
        monthlyContribution: 100.0,
        annualInterestRate: 7.25,
        icon: 'trending_up',
        color: '#2196F3',
        startDate: DateTime(2025, 3, 15),
        createdAt: DateTime(2026, 1, 1, 10, 30),
        lastUpdatedAt: DateTime(2026, 2, 1),
        firestoreId: 'cloud-id-123',
      );

      final data = original.toFirestore();
      final restored = SavingsAccount.fromFirestore('different-doc', data);

      expect(restored.id, 'acc-firestore');
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.initialBalance, original.initialBalance);
      expect(restored.currentBalance, original.currentBalance);
      expect(restored.monthlyContribution, original.monthlyContribution);
      expect(restored.annualInterestRate, original.annualInterestRate);
      expect(restored.icon, original.icon);
      expect(restored.color, original.color);
      expect(restored.startDate, original.startDate);
      expect(restored.createdAt, original.createdAt);
      expect(restored.lastUpdatedAt, original.lastUpdatedAt);
      expect(restored.deleted, false);
      expect(restored.firestoreId, 'different-doc');
    });

    test('fromFirestore handles missing fields with defaults', () {
      final restored = SavingsAccount.fromFirestore('fallback-id', {});

      expect(restored.id, 'fallback-id');
      expect(restored.name, '');
      expect(restored.type, SavingsAccountType.savings);
      expect(restored.initialBalance, 0.0);
      expect(restored.currentBalance, 0.0);
      expect(restored.monthlyContribution, 0.0);
      expect(restored.annualInterestRate, 0.0);
      expect(restored.deleted, false);
    });

    test('fromFirestore handles unknown type gracefully', () {
      final restored = SavingsAccount.fromFirestore('id', {
        'type': 'unknown_type',
      });

      expect(restored.type, SavingsAccountType.savings);
    });
  });
  test('copyWith updates only provided fields', () {
    final account = SavingsAccount(
      id: 'acc-5',
      name: 'Original',
      type: SavingsAccountType.savings,
      initialBalance: 100.0,
      currentBalance: 100.0,
      monthlyContribution: 10.0,
      annualInterestRate: 3.0,
      createdAt: DateTime(2026, 1, 1),
    );

    final updated = account.copyWith(name: 'Renombrada', currentBalance: 250.0);

    expect(updated.id, 'acc-5');
    expect(updated.name, 'Renombrada');
    expect(updated.currentBalance, 250.0);
    expect(updated.initialBalance, 100.0);
    expect(updated.monthlyContribution, 10.0);
    expect(updated.annualInterestRate, 3.0);
    expect(updated.type, SavingsAccountType.savings);
    expect(account.name, 'Original');
    expect(account.currentBalance, 100.0);
  });

  test('deleted flag round-trips through Firestore', () {
    final original = SavingsAccount(
      id: 'acc-deleted',
      name: 'A eliminar',
      type: SavingsAccountType.savings,
      createdAt: DateTime(2026, 1, 1),
      deleted: true,
      deletedAt: DateTime(2026, 3, 1),
    );

    final restored = SavingsAccount.fromFirestore(
      'acc-deleted',
      original.toFirestore(),
    );

    expect(restored.deleted, true);
    expect(restored.deletedAt, DateTime(2026, 3, 1));
  });

  group('SavingsAccountType', () {
    test('labels are in Spanish', () {
      expect(SavingsAccountType.savings.label, 'Ahorro');
      expect(SavingsAccountType.investment.label, 'Inversión');
    });

    test('descriptions are present', () {
      expect(SavingsAccountType.savings.description, isNotEmpty);
      expect(SavingsAccountType.investment.description, isNotEmpty);
    });
  });
}
