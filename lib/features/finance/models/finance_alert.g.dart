// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinanceAlertAdapter extends TypeAdapter<FinanceAlert> {
  @override
  final int typeId = 20;

  @override
  FinanceAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinanceAlert(
      id: fields[0] as String,
      type: fields[1] as AlertType,
      severity: fields[2] as AlertSeverity,
      title: fields[3] as String,
      message: fields[4] as String,
      relatedBudgetId: fields[5] as String?,
      relatedCategoryId: fields[6] as String?,
      relatedRecurringTransactionId: fields[7] as String?,
      createdAt: fields[8] as DateTime,
      isRead: fields[9] as bool,
      isDismissed: fields[10] as bool,
      readAt: fields[11] as DateTime?,
      dismissedAt: fields[12] as DateTime?,
      metadata: (fields[13] as Map?)?.cast<String, dynamic>(),
      deleted: fields[14] == null ? false : fields[14] as bool,
      deletedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FinanceAlert obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.severity)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.relatedBudgetId)
      ..writeByte(6)
      ..write(obj.relatedCategoryId)
      ..writeByte(7)
      ..write(obj.relatedRecurringTransactionId)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.isRead)
      ..writeByte(10)
      ..write(obj.isDismissed)
      ..writeByte(11)
      ..write(obj.readAt)
      ..writeByte(12)
      ..write(obj.dismissedAt)
      ..writeByte(13)
      ..write(obj.metadata)
      ..writeByte(14)
      ..write(obj.deleted)
      ..writeByte(15)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinanceAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
