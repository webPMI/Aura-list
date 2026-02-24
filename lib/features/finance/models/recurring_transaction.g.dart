// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionAdapter extends TypeAdapter<RecurringTransaction> {
  @override
  final int typeId = 17;

  @override
  RecurringTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransaction(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      categoryId: fields[3] as String,
      type: fields[4] as FinanceCategoryType,
      recurrence: fields[5] as RecurrenceRule,
      autoGenerate: fields[6] as bool,
      lastGenerated: fields[7] as DateTime?,
      active: fields[8] as bool,
      linkedTaskId: fields[9] as String?,
      note: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      lastUpdatedAt: fields[12] as DateTime?,
      deleted: fields[13] == null ? false : fields[13] as bool,
      deletedAt: fields[14] as DateTime?,
      firestoreId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransaction obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.recurrence)
      ..writeByte(6)
      ..write(obj.autoGenerate)
      ..writeByte(7)
      ..write(obj.lastGenerated)
      ..writeByte(8)
      ..write(obj.active)
      ..writeByte(9)
      ..write(obj.linkedTaskId)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.lastUpdatedAt)
      ..writeByte(13)
      ..write(obj.deleted)
      ..writeByte(14)
      ..write(obj.deletedAt)
      ..writeByte(15)
      ..write(obj.firestoreId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
