import '../models/savings_account.dart';
import '../models/savings_projection.dart';

/// Servicio de simulación de cuentas de ahorro e inversión.
///
/// Proyecta el crecimiento de una o varias cuentas usando interés compuesto
/// mensual sobre el saldo más la aportación periódica:
///
///   tasa_mensual = tasa_anual / 12 / 100
///   balance_n = (balance_{n-1} + aportación) * (1 + tasa_mensual)
///
/// Además calcula estadísticas generales y promedios útiles para proyectar
/// tanto el presente (saldo, ganancia, tasa ponderada) como el futuro
/// (hitos a 1, 5, 10, 20 y 30 años).
class SavingsSimulationService {
  /// Horizonte máximo de simulación en meses (30 años).
  static const int defaultHorizonMonths = 360;

  /// Hitos en años que se calculan en las estadísticas generales.
  static const List<int> milestoneYears = [1, 5, 10, 20, 30];

  /// Convierte una tasa anual en porcentaje a su equivalente mensual.
  double monthlyRate(double annualRatePercent) {
    return annualRatePercent / 12 / 100;
  }

  /// Proyecta una única cuenta mes a mes con interés compuesto.
  SavingsProjection projectAccount(
    SavingsAccount account, {
    int months = defaultHorizonMonths,
  }) {
    final start = DateTime(DateTime.now().year, DateTime.now().month);
    final rate = monthlyRate(account.annualInterestRate);
    final m = months.clamp(0, defaultHorizonMonths);

    final points = <SavingsProjectionPoint>[];
    var balance = account.currentBalance;
    var cumulativeContributions = 0.0;
    var cumulativeInterest = 0.0;

    for (var i = 1; i <= m; i++) {
      final interest = (balance + account.monthlyContribution) * rate;
      balance = balance + account.monthlyContribution + interest;
      cumulativeContributions += account.monthlyContribution;
      cumulativeInterest += interest;

      points.add(
        SavingsProjectionPoint(
          date: DateTime(start.year, start.month + i),
          balance: balance,
          contributions: cumulativeContributions,
          interest: cumulativeInterest,
        ),
      );
    }

    return SavingsProjection(
      points: points,
      startingBalance: account.currentBalance,
      monthlyContribution: account.monthlyContribution,
      annualInterestRate: account.annualInterestRate,
    );
  }

  /// Proyección consolidada de varias cuentas sumando mes a mes.
  SavingsProjection projectCombined(
    List<SavingsAccount> accounts, {
    int months = defaultHorizonMonths,
  }) {
    if (accounts.isEmpty) {
      return SavingsProjection(
        points: const [],
        startingBalance: 0,
        monthlyContribution: 0,
        annualInterestRate: 0,
      );
    }

    final individual = accounts
        .map((a) => projectAccount(a, months: months))
        .toList();
    final m = months.clamp(0, defaultHorizonMonths);
    final points = <SavingsProjectionPoint>[];

    for (var i = 1; i <= m; i++) {
      var balance = 0.0;
      var contributions = 0.0;
      var interest = 0.0;
      DateTime date = DateTime.now();

      for (final projection in individual) {
        final point = projection.pointAt(i);
        if (point == null) continue;
        balance += point.balance;
        contributions += point.contributions;
        interest += point.interest;
        date = point.date;
      }

      points.add(
        SavingsProjectionPoint(
          date: date,
          balance: balance,
          contributions: contributions,
          interest: interest,
        ),
      );
    }

    return SavingsProjection(
      points: points,
      startingBalance: accounts.fold<double>(
        0,
        (sum, a) => sum + a.currentBalance,
      ),
      monthlyContribution: accounts.fold<double>(
        0,
        (sum, a) => sum + a.monthlyContribution,
      ),
      annualInterestRate: weightedAverageRate(accounts),
    );
  }

  /// Estadísticas de un hito temporal (años) a partir de una proyección.
  SavingsMilestoneStats? milestoneStats(
    SavingsProjection projection,
    int years,
  ) {
    final point = projection.pointAt(years * 12);
    if (point == null) return null;
    return SavingsMilestoneStats(
      years: years,
      months: years * 12,
      projectedBalance: point.balance,
      contributions: point.contributions,
      interest: point.interest,
    );
  }

  /// Tasa anual promedio ponderada por saldo actual.
  double weightedAverageRate(List<SavingsAccount> accounts) {
    final totalBalance = accounts.fold<double>(
      0,
      (sum, a) => sum + a.currentBalance,
    );
    if (totalBalance <= 0) return 0.0;

    final weighted = accounts.fold<double>(
      0,
      (sum, a) => sum + a.currentBalance * a.annualInterestRate,
    );
    return weighted / totalBalance;
  }

  /// Aportación mensual total.
  double totalMonthlyContribution(List<SavingsAccount> accounts) {
    return accounts.fold<double>(0, (sum, a) => sum + a.monthlyContribution);
  }

  /// Estadísticas generales consolidadas de todas las cuentas activas.
  SavingsOverallStats overallStats(List<SavingsAccount> accounts) {
    final active = accounts.where((a) => !a.deleted).toList();

    final totalInitial = active.fold<double>(
      0,
      (sum, a) => sum + a.initialBalance,
    );
    final totalCurrent = active.fold<double>(
      0,
      (sum, a) => sum + a.currentBalance,
    );

    SavingsMilestoneStats? milestone(int years) {
      final projection = projectCombined(active, months: years * 12);
      return milestoneStats(projection, years);
    }

    return SavingsOverallStats(
      accountCount: active.length,
      totalCurrentBalance: totalCurrent,
      totalInitialBalance: totalInitial,
      totalMonthlyContribution: totalMonthlyContribution(active),
      totalGained: totalCurrent - totalInitial,
      weightedAverageRate: weightedAverageRate(active),
      oneYear: milestone(1),
      fiveYears: milestone(5),
      tenYears: milestone(10),
      twentyYears: milestone(20),
      thirtyYears: milestone(30),
    );
  }
}
