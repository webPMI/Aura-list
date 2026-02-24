import 'package:hive/hive.dart';

part 'finance_enums.g.dart';

/// Frecuencia de recurrencia para transacciones recurrentes.
@HiveType(typeId: 22)
enum RecurrenceFrequency {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,

  @HiveField(2)
  monthly,

  @HiveField(3)
  yearly,

  @HiveField(4)
  quarterly,
}

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get spanishName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Diaria';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.monthly:
        return 'Mensual';
      case RecurrenceFrequency.yearly:
        return 'Anual';
      case RecurrenceFrequency.quarterly:
        return 'Trimestral';
    }
  }
}

/// Periodo para limites de presupuesto.
@HiveType(typeId: 23)
enum BudgetPeriod {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,

  @HiveField(2)
  monthly,

  @HiveField(3)
  yearly,

  @HiveField(4)
  quarterly,
}

extension BudgetPeriodExtension on BudgetPeriod {
  String get spanishName {
    switch (this) {
      case BudgetPeriod.daily:
        return 'Diario';
      case BudgetPeriod.weekly:
        return 'Semanal';
      case BudgetPeriod.monthly:
        return 'Mensual';
      case BudgetPeriod.yearly:
        return 'Anual';
      case BudgetPeriod.quarterly:
        return 'Trimestral';
    }
  }
}

/// Tipo de vinculacion entre tarea y transaccion financiera.
@HiveType(typeId: 24)
enum TaskFinanceLinkType {
  /// La tarea genera un gasto al completarse
  @HiveField(0)
  generateExpense,

  /// La tarea genera un ingreso al completarse
  @HiveField(1)
  generateIncome,

  /// La tarea tiene un costo asociado
  @HiveField(2)
  hasCost,

  /// La tarea tiene un beneficio economico asociado
  @HiveField(3)
  hasBenefit,
}

extension TaskFinanceLinkTypeExtension on TaskFinanceLinkType {
  String get spanishName {
    switch (this) {
      case TaskFinanceLinkType.generateExpense:
        return 'Genera Gasto';
      case TaskFinanceLinkType.generateIncome:
        return 'Genera Ingreso';
      case TaskFinanceLinkType.hasCost:
        return 'Tiene Costo';
      case TaskFinanceLinkType.hasBenefit:
        return 'Tiene Beneficio';
    }
  }

  String get description {
    switch (this) {
      case TaskFinanceLinkType.generateExpense:
        return 'Al completar la tarea se registra automaticamente un gasto';
      case TaskFinanceLinkType.generateIncome:
        return 'Al completar la tarea se registra automaticamente un ingreso';
      case TaskFinanceLinkType.hasCost:
        return 'La tarea tiene un costo asociado que se debe considerar';
      case TaskFinanceLinkType.hasBenefit:
        return 'La tarea tiene un beneficio economico asociado';
    }
  }
}

/// Tipo de alerta financiera.
@HiveType(typeId: 25)
enum AlertType {
  /// Alerta de presupuesto excedido
  @HiveField(0)
  budgetExceeded,

  /// Alerta de proximo a exceder presupuesto
  @HiveField(1)
  budgetWarning,

  /// Alerta de flujo de efectivo negativo
  @HiveField(2)
  negativeCashFlow,

  /// Alerta de gasto inusual
  @HiveField(3)
  unusualExpense,

  /// Alerta de ingreso inusual
  @HiveField(4)
  unusualIncome,

  /// Recordatorio de transaccion recurrente
  @HiveField(5)
  recurringTransactionDue,

  /// Alerta de saldo bajo
  @HiveField(6)
  lowBalance,
}

extension AlertTypeExtension on AlertType {
  String get spanishName {
    switch (this) {
      case AlertType.budgetExceeded:
        return 'Presupuesto Excedido';
      case AlertType.budgetWarning:
        return 'Alerta de Presupuesto';
      case AlertType.negativeCashFlow:
        return 'Flujo Negativo';
      case AlertType.unusualExpense:
        return 'Gasto Inusual';
      case AlertType.unusualIncome:
        return 'Ingreso Inusual';
      case AlertType.recurringTransactionDue:
        return 'Transaccion Pendiente';
      case AlertType.lowBalance:
        return 'Saldo Bajo';
    }
  }
}

/// Severidad de una alerta financiera.
@HiveType(typeId: 26)
enum AlertSeverity {
  /// Informacion, no requiere accion inmediata
  @HiveField(0)
  info,

  /// Advertencia, requiere atencion
  @HiveField(1)
  warning,

  /// Critico, requiere accion inmediata
  @HiveField(2)
  critical,
}

extension AlertSeverityExtension on AlertSeverity {
  String get spanishName {
    switch (this) {
      case AlertSeverity.info:
        return 'Informacion';
      case AlertSeverity.warning:
        return 'Advertencia';
      case AlertSeverity.critical:
        return 'Critico';
    }
  }
}

/// Nivel de riesgo en proyecciones de flujo de efectivo.
@HiveType(typeId: 27)
enum RiskLevel {
  /// Riesgo bajo, proyeccion estable
  @HiveField(0)
  low,

  /// Riesgo medio, requiere monitorizacion
  @HiveField(1)
  medium,

  /// Riesgo alto, requiere accion
  @HiveField(2)
  high,

  /// Riesgo critico, situacion urgente
  @HiveField(3)
  critical,
}

extension RiskLevelExtension on RiskLevel {
  String get spanishName {
    switch (this) {
      case RiskLevel.low:
        return 'Bajo';
      case RiskLevel.medium:
        return 'Medio';
      case RiskLevel.high:
        return 'Alto';
      case RiskLevel.critical:
        return 'Critico';
    }
  }

  String get description {
    switch (this) {
      case RiskLevel.low:
        return 'Situacion financiera estable';
      case RiskLevel.medium:
        return 'Requiere monitorizacion';
      case RiskLevel.high:
        return 'Requiere atencion y ajustes';
      case RiskLevel.critical:
        return 'Situacion urgente, accion inmediata necesaria';
    }
  }
}
