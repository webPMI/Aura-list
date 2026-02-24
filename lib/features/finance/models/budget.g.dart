// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 18;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      id: fields[0] as String,
      name: fields[1] as String,
      categoryId: fields[2] as String,
      limit: fields[3] as double,
      period: fields[4] as BudgetPeriod,
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime?,
      alertThreshold: fields[7] as double,
      rollover: fields[8] as bool,
      rolloverAmount: fields[9] as double,
      active: fields[10] as bool,
      createdAt: fields[11] as DateTime,
      lastUpdatedAt: fields[12] as DateTime?,
      deleted: fields[13] == null ? false : fields[13] as bool,
      deletedAt: fields[14] as DateTime?,
      firestoreId: fields[15] as String?,
      note: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.limit)
      ..writeByte(4)
      ..write(obj.period)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.alertThreshold)
      ..writeByte(8)
      ..write(obj.rollover)
      ..writeByte(9)
      ..write(obj.rolloverAmount)
      ..writeByte(10)
      ..write(obj.active)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.lastUpdatedAt)
      ..writeByte(13)
      ..write(obj.deleted)
      ..writeByte(14)
      ..write(obj.deletedAt)
      ..writeByte(15)
      ..write(obj.firestoreId)
      ..writeByte(16)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
