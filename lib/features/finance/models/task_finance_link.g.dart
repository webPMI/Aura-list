// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_finance_link.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskFinanceLinkAdapter extends TypeAdapter<TaskFinanceLink> {
  @override
  final int typeId = 29;

  @override
  TaskFinanceLink read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskFinanceLink(
      id: fields[0] as String,
      taskId: fields[1] as String,
      impactType: fields[2] as FinancialImpactType,
      estimatedAmount: fields[3] as double,
      actualTransactionId: fields[4] as String?,
      categoryId: fields[5] as String,
      note: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      linkedAt: fields[8] as DateTime?,
      deleted: fields[9] == null ? false : fields[9] as bool,
      deletedAt: fields[10] as DateTime?,
      autoCreateTransaction: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TaskFinanceLink obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.impactType)
      ..writeByte(3)
      ..write(obj.estimatedAmount)
      ..writeByte(4)
      ..write(obj.actualTransactionId)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.linkedAt)
      ..writeByte(9)
      ..write(obj.deleted)
      ..writeByte(10)
      ..write(obj.deletedAt)
      ..writeByte(11)
      ..write(obj.autoCreateTransaction);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFinanceLinkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FinancialImpactTypeAdapter extends TypeAdapter<FinancialImpactType> {
  @override
  final int typeId = 28;

  @override
  FinancialImpactType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FinancialImpactType.cost;
      case 1:
        return FinancialImpactType.saving;
      case 2:
        return FinancialImpactType.income;
      default:
        return FinancialImpactType.cost;
    }
  }

  @override
  void write(BinaryWriter writer, FinancialImpactType obj) {
    switch (obj) {
      case FinancialImpactType.cost:
        writer.writeByte(0);
        break;
      case FinancialImpactType.saving:
        writer.writeByte(1);
        break;
      case FinancialImpactType.income:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialImpactTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
