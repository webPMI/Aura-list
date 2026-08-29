import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/features/finance/models/savings_account.dart';
import 'package:checklist_app/features/finance/services/savings_simulation_service.dart';

/// ============================================================
/// Tests de SavingsSimulationService
/// Cubre: interés compuesto, proyecciones consolidadas, hitos,
/// estadísticas generales y promedios
/// ============================================================
void main() {
  final service = SavingsSimulationService();

  SavingsAccount account({
    String id = 'acc',
    String name = 'Cuenta',
    SavingsAccountType type = SavingsAccountType.savings,
    double initialBalance = 0,
    double currentBalance = 0,
    double monthlyContribution = 0,
    double annualInterestRate = 0,
  }) {
    return SavingsAccount(
      id: id,
      name: name,
      type: type,
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      monthlyContribution: monthlyContribution,
      annualInterestRate: annualInterestRate,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('monthlyRate', () {
    test('converts annual percentage to monthly', () {
      expect(service.monthlyRate(0), 0.0);
      expect(service.monthlyRate(12), closeTo(0.01, 1e-12));
      expect(service.monthlyRate(4.5), closeTo(0.00375, 1e-12));
    });
  });

  group('projectAccount', () {
    test('with 0% interest, balance grows only by contributions', () {
      final projection = service.projectAccount(
        account(currentBalance: 1000, monthlyContribution: 100),
        months: 12,
      );

      expect(projection.points.length, 12);
      expect(projection.totalInterest, 0.0);
      expect(projection.totalContributions, closeTo(1200, 1e-6));
      expect(projection.finalBalance, closeTo(2200, 1e-6));
    });

    test('applies monthly compound interest correctly', () {
      // Tasa anual 12% => mensual 1%. Saldo 1000, aporte 0.
      final projection = service.projectAccount(
        account(
          currentBalance: 1000,
          monthlyContribution: 0,
          annualInterestRate: 12,
        ),
        months: 2,
      );

      // mes 1: 1000 * 1.01 = 1010
      // mes 2: 1010 * 1.01 = 1020.10
      expect(projection.pointAt(1)!.balance, closeTo(1010, 1e-6));
      expect(projection.pointAt(2)!.balance, closeTo(1020.10, 1e-6));
    });

    test('interest accrues on the contribution added in the same month', () {
      // Tasa 12% anual. Saldo 0, aporte mensual 100.
      final projection = service.projectAccount(
        account(
          currentBalance: 0,
          monthlyContribution: 100,
          annualInterestRate: 12,
        ),
        months: 1,
      );

      // mes 1: (0 + 100) * 1.01 = 101
      expect(projection.pointAt(1)!.balance, closeTo(101, 1e-6));
      expect(projection.pointAt(1)!.contributions, closeTo(100, 1e-6));
      expect(projection.pointAt(1)!.interest, closeTo(1, 1e-6));
    });

    test('clamps horizon to monthly points', () {
      final projection = service.projectAccount(
        account(currentBalance: 100),
        months: 0,
      );

      expect(projection.points, isEmpty);
      expect(projection.finalBalance, 100.0);
    });

    test('balance is always contributions + start when rate is 0', () {
      final projection = service.projectAccount(
        account(
          initialBalance: 500,
          currentBalance: 800,
          monthlyContribution: 50,
        ),
        months: 60,
      );

      final last = projection.points.last;
      expect(last.balance, closeTo(last.contributions + 800, 1e-4));
    });
  });

  group('projectCombined', () {
    test('sums balances and contributions across accounts', () {
      final combined = service.projectCombined([
        account(
          id: 'a1',
          currentBalance: 1000,
          monthlyContribution: 100,
          annualInterestRate: 0,
        ),
        account(
          id: 'a2',
          currentBalance: 2000,
          monthlyContribution: 50,
          annualInterestRate: 0,
        ),
      ], months: 2);

      // Sin interés:
      // a1: mes2 = 1000 + 100*2 = 1200
      // a2: mes2 = 2000 + 50*2  = 2100
      // total = 3300
      expect(combined.startingBalance, closeTo(3000, 1e-6));
      expect(combined.totalContributions, closeTo(300, 1e-6));
      expect(combined.finalBalance, closeTo(3300, 1e-6));
      expect(combined.monthlyContribution, closeTo(150, 1e-6));
    });

    test('returns empty projection for no accounts', () {
      final combined = service.projectCombined([]);

      expect(combined.points, isEmpty);
      expect(combined.finalBalance, 0.0);
      expect(combined.totalContributions, 0.0);
    });
  });
  group('milestoneStats', () {
    test('computes milestone at year boundaries', () {
      final projection = service.projectAccount(
        account(
          currentBalance: 0,
          monthlyContribution: 100,
          annualInterestRate: 12,
        ),
        months: 60,
      );

      final five = service.milestoneStats(projection, 5);
      expect(five, isNotNull);
      expect(five!.years, 5);
      expect(five.months, 60);
      expect(
        five.projectedBalance,
        closeTo(projection.pointAt(60)!.balance, 1e-4),
      );
      expect(five.contributions, closeTo(6000, 1e-4));
    });

    test('returns null when horizon is too short', () {
      final projection = service.projectAccount(
        account(currentBalance: 100),
        months: 6,
      );

      expect(service.milestoneStats(projection, 5), isNull);
    });
  });

  group('overallStats', () {
    test('computes totals, weighted average and milestones', () {
      final stats = service.overallStats([
        account(
          id: 'a1',
          initialBalance: 1000,
          currentBalance: 2000,
          monthlyContribution: 100,
          annualInterestRate: 4,
          type: SavingsAccountType.savings,
        ),
        account(
          id: 'a2',
          initialBalance: 5000,
          currentBalance: 8000,
          monthlyContribution: 50,
          annualInterestRate: 12,
          type: SavingsAccountType.investment,
        ),
      ]);

      expect(stats.accountCount, 2);
      expect(stats.totalCurrentBalance, closeTo(10000, 1e-6));
      expect(stats.totalInitialBalance, closeTo(6000, 1e-6));
      expect(stats.totalMonthlyContribution, closeTo(150, 1e-6));
      expect(stats.totalGained, closeTo(4000, 1e-6));
      // Ponderado: (2000*4 + 8000*12) / 10000 = 10.4
      expect(stats.weightedAverageRate, closeTo(10.4, 1e-6));
      expect(stats.oneYear, isNotNull);
      expect(stats.fiveYears, isNotNull);
      expect(stats.tenYears, isNotNull);
      expect(stats.twentyYears, isNotNull);
      expect(stats.thirtyYears, isNotNull);
    });

    test('handles empty account list', () {
      final stats = service.overallStats([]);

      expect(stats.accountCount, 0);
      expect(stats.totalCurrentBalance, 0.0);
      expect(stats.totalGained, 0.0);
      expect(stats.weightedAverageRate, 0.0);
      expect(stats.oneYear, isNull);
      expect(stats.thirtyYears, isNull);
    });

    test('ignores soft-deleted accounts', () {
      final deleted = account(
        id: 'old',
        currentBalance: 99999,
        monthlyContribution: 500,
        annualInterestRate: 20,
      );
      deleted.deleted = true;

      final stats = service.overallStats([
        deleted,
        account(id: 'live', currentBalance: 1000, monthlyContribution: 50),
      ]);

      expect(stats.accountCount, 1);
      expect(stats.totalCurrentBalance, closeTo(1000, 1e-6));
    });
  });

  group('long term behavior', () {
    test('compound interest surpasses contributions within horizon', () {
      final projection = service.projectAccount(
        account(
          currentBalance: 10000,
          monthlyContribution: 100,
          annualInterestRate: 10,
        ),
        months: 360,
      );

      final last = projection.points.last;
      expect(last.interest, greaterThan(last.contributions));
      expect(projection.finalBalance, greaterThan(100000));
    });

    test('higher rates produce higher balances for same contributions', () {
      final low = service.projectAccount(
        account(
          currentBalance: 1000,
          monthlyContribution: 100,
          annualInterestRate: 2,
        ),
        months: 120,
      );
      final high = service.projectAccount(
        account(
          currentBalance: 1000,
          monthlyContribution: 100,
          annualInterestRate: 10,
        ),
        months: 120,
      );

      expect(high.finalBalance, greaterThan(low.finalBalance));
    });
  });
}
