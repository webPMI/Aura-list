// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurrenceFrequencyAdapter extends TypeAdapter<RecurrenceFrequency> {
  @override
  final int typeId = 22;

  @override
  RecurrenceFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceFrequency.daily;
      case 1:
        return RecurrenceFrequency.weekly;
      case 2:
        return RecurrenceFrequency.monthly;
      case 3:
        return RecurrenceFrequency.yearly;
      case 4:
        return RecurrenceFrequency.quarterly;
      default:
        return RecurrenceFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceFrequency obj) {
    switch (obj) {
      case RecurrenceFrequency.daily:
        writer.writeByte(0);
        break;
      case RecurrenceFrequency.weekly:
        writer.writeByte(1);
        break;
      case RecurrenceFrequency.monthly:
        writer.writeByte(2);
        break;
      case RecurrenceFrequency.yearly:
        writer.writeByte(3);
        break;
      case RecurrenceFrequency.quarterly:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 23;

  @override
  BudgetPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetPeriod.daily;
      case 1:
        return BudgetPeriod.weekly;
      case 2:
        return BudgetPeriod.monthly;
      case 3:
        return BudgetPeriod.yearly;
      case 4:
        return BudgetPeriod.quarterly;
      default:
        return BudgetPeriod.daily;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    switch (obj) {
      case BudgetPeriod.daily:
        writer.writeByte(0);
        break;
      case BudgetPeriod.weekly:
        writer.writeByte(1);
        break;
      case BudgetPeriod.monthly:
        writer.writeByte(2);
        break;
      case BudgetPeriod.yearly:
        writer.writeByte(3);
        break;
      case BudgetPeriod.quarterly:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskFinanceLinkTypeAdapter extends TypeAdapter<TaskFinanceLinkType> {
  @override
  final int typeId = 24;

  @override
  TaskFinanceLinkType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskFinanceLinkType.generateExpense;
      case 1:
        return TaskFinanceLinkType.generateIncome;
      case 2:
        return TaskFinanceLinkType.hasCost;
      case 3:
        return TaskFinanceLinkType.hasBenefit;
      default:
        return TaskFinanceLinkType.generateExpense;
    }
  }

  @override
  void write(BinaryWriter writer, TaskFinanceLinkType obj) {
    switch (obj) {
      case TaskFinanceLinkType.generateExpense:
        writer.writeByte(0);
        break;
      case TaskFinanceLinkType.generateIncome:
        writer.writeByte(1);
        break;
      case TaskFinanceLinkType.hasCost:
        writer.writeByte(2);
        break;
      case TaskFinanceLinkType.hasBenefit:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFinanceLinkTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlertTypeAdapter extends TypeAdapter<AlertType> {
  @override
  final int typeId = 25;

  @override
  AlertType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlertType.budgetExceeded;
      case 1:
        return AlertType.budgetWarning;
      case 2:
        return AlertType.negativeCashFlow;
      case 3:
        return AlertType.unusualExpense;
      case 4:
        return AlertType.unusualIncome;
      case 5:
        return AlertType.recurringTransactionDue;
      case 6:
        return AlertType.lowBalance;
      default:
        return AlertType.budgetExceeded;
    }
  }

  @override
  void write(BinaryWriter writer, AlertType obj) {
    switch (obj) {
      case AlertType.budgetExceeded:
        writer.writeByte(0);
        break;
      case AlertType.budgetWarning:
        writer.writeByte(1);
        break;
      case AlertType.negativeCashFlow:
        writer.writeByte(2);
        break;
      case AlertType.unusualExpense:
        writer.writeByte(3);
        break;
      case AlertType.unusualIncome:
        writer.writeByte(4);
        break;
      case AlertType.recurringTransactionDue:
        writer.writeByte(5);
        break;
      case AlertType.lowBalance:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlertSeverityAdapter extends TypeAdapter<AlertSeverity> {
  @override
  final int typeId = 26;

  @override
  AlertSeverity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlertSeverity.info;
      case 1:
        return AlertSeverity.warning;
      case 2:
        return AlertSeverity.critical;
      default:
        return AlertSeverity.info;
    }
  }

  @override
  void write(BinaryWriter writer, AlertSeverity obj) {
    switch (obj) {
      case AlertSeverity.info:
        writer.writeByte(0);
        break;
      case AlertSeverity.warning:
        writer.writeByte(1);
        break;
      case AlertSeverity.critical:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertSeverityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RiskLevelAdapter extends TypeAdapter<RiskLevel> {
  @override
  final int typeId = 27;

  @override
  RiskLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RiskLevel.low;
      case 1:
        return RiskLevel.medium;
      case 2:
        return RiskLevel.high;
      case 3:
        return RiskLevel.critical;
      default:
        return RiskLevel.low;
    }
  }

  @override
  void write(BinaryWriter writer, RiskLevel obj) {
    switch (obj) {
      case RiskLevel.low:
        writer.writeByte(0);
        break;
      case RiskLevel.medium:
        writer.writeByte(1);
        break;
      case RiskLevel.high:
        writer.writeByte(2);
        break;
      case RiskLevel.critical:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
