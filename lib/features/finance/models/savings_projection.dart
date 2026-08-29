/// Punto de proyección mensual de una cuenta de ahorro o inversión.
class SavingsProjectionPoint {
  /// Fecha del punto proyectado (fin de mes).
  final DateTime date;

  /// Saldo proyectado al cierre del mes.
  final double balance;

  /// Aporte acumulado hasta ese mes (sin intereses).
  final double contributions;

  /// Interés acumulado generado hasta ese mes.
  final double interest;

  const SavingsProjectionPoint({
    required this.date,
    required this.balance,
    required this.contributions,
    required this.interest,
  });
}

/// Resultado de una simulación de cuenta de ahorro o inversión.
class SavingsProjection {
  /// Puntos mes a mes de la proyección.
  final List<SavingsProjectionPoint> points;

  /// Saldo de partida usado en la simulación.
  final double startingBalance;

  /// Aportación mensual constante utilizada.
  final double monthlyContribution;

  /// Tasa de interés anual utilizada (porcentaje).
  final double annualInterestRate;

  const SavingsProjection({
    required this.points,
    required this.startingBalance,
    required this.monthlyContribution,
    required this.annualInterestRate,
  });

  /// Saldo final proyectado (último punto de la simulación).
  double get finalBalance =>
      points.isEmpty ? startingBalance : points.last.balance;

  /// Total aportado durante toda la simulación.
  double get totalContributions =>
      points.isEmpty ? 0.0 : points.last.contributions;

  /// Total de interés generado durante toda la simulación.
  double get totalInterest => points.isEmpty ? 0.0 : points.last.interest;

  /// Número de meses proyectados.
  int get monthCount => points.length;

  /// Retorna el punto en el mes indicado (índice desde 1) o null si no existe.
  SavingsProjectionPoint? pointAt(int month) {
    if (month < 1 || month > points.length) return null;
    return points[month - 1];
  }
}

/// Estadísticas por hito temporal (ej: proyección a 5 años).
class SavingsMilestoneStats {
  /// Número de años del hito.
  final int years;

  /// Meses transcurridos.
  final int months;

  /// Saldo proyectado al final del hito.
  final double projectedBalance;

  /// Total aportado en el hito.
  final double contributions;

  /// Interés generado en el hito.
  final double interest;

  const SavingsMilestoneStats({
    required this.years,
    required this.months,
    required this.projectedBalance,
    required this.contributions,
    required this.interest,
  });
}

/// Estadísticas generales consolidadas de todas las cuentas.
class SavingsOverallStats {
  /// Número de cuentas activas.
  final int accountCount;

  /// Saldo actual total (suma de saldos actuales).
  final double totalCurrentBalance;

  /// Saldo inicial total.
  final double totalInitialBalance;

  /// Aportación mensual total de todas las cuentas.
  final double totalMonthlyContribution;

  /// Ganancia total acumulada (current - initial).
  final double totalGained;

  /// Tasa de interés anual promedio ponderada por saldo.
  final double weightedAverageRate;

  /// Proyección consolidada a 1 año.
  final SavingsMilestoneStats? oneYear;

  /// Proyección consolidada a 5 años.
  final SavingsMilestoneStats? fiveYears;

  /// Proyección consolidada a 10 años.
  final SavingsMilestoneStats? tenYears;

  /// Proyección consolidada a 20 años.
  final SavingsMilestoneStats? twentyYears;

  /// Proyección consolidada a 30 años.
  final SavingsMilestoneStats? thirtyYears;

  const SavingsOverallStats({
    required this.accountCount,
    required this.totalCurrentBalance,
    required this.totalInitialBalance,
    required this.totalMonthlyContribution,
    required this.totalGained,
    required this.weightedAverageRate,
    this.oneYear,
    this.fiveYears,
    this.tenYears,
    this.twentyYears,
    this.thirtyYears,
  });

  /// Saldo proyectado para el hito indicado, si existe.
  SavingsMilestoneStats? milestoneFor(int years) {
    switch (years) {
      case 1:
        return oneYear;
      case 5:
        return fiveYears;
      case 10:
        return tenYears;
      case 20:
        return twentyYears;
      case 30:
        return thirtyYears;
      default:
        return null;
    }
  }
}
