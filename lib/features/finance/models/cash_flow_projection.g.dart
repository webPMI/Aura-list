// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_flow_projection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashFlowProjectionAdapter extends TypeAdapter<CashFlowProjection> {
  @override
  final int typeId = 19;

  @override
  CashFlowProjection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashFlowProjection(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      projectedIncome: fields[2] as double,
      projectedExpenses: fields[3] as double,
      projectedBalance: fields[4] as double,
      actualIncome: fields[5] as double,
      actualExpenses: fields[6] as double,
      createdAt: fields[7] as DateTime,
      lastUpdatedAt: fields[8] as DateTime,
      isHistorical: fields[9] as bool,
      deleted: fields[10] == null ? false : fields[10] as bool,
      deletedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CashFlowProjection obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.projectedIncome)
      ..writeByte(3)
      ..write(obj.projectedExpenses)
      ..writeByte(4)
      ..write(obj.projectedBalance)
      ..writeByte(5)
      ..write(obj.actualIncome)
      ..writeByte(6)
      ..write(obj.actualExpenses)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.lastUpdatedAt)
      ..writeByte(9)
      ..write(obj.isHistorical)
      ..writeByte(10)
      ..write(obj.deleted)
      ..writeByte(11)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashFlowProjectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
