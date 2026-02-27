// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskTemplateAdapter extends TypeAdapter<TaskTemplate> {
  @override
  final int typeId = 30;

  @override
  TaskTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      taskType: fields[3] as String,
      title: fields[4] as String,
      category: fields[5] as String,
      priority: fields[6] as int,
      motivation: fields[7] as String?,
      reward: fields[8] as String?,
      dueTimeMinutes: fields[9] as int?,
      daysOffset: fields[10] as int?,
      recurrenceDay: fields[11] as int?,
      financialCost: fields[12] as double?,
      financialBenefit: fields[13] as double?,
      financialCategoryId: fields[14] as String?,
      financialNote: fields[15] as String?,
      autoGenerateTransaction: fields[16] as bool,
      linkedRecurringTransactionId: fields[17] as String?,
      createdAt: fields[18] as DateTime?,
      lastUsedAt: fields[19] as DateTime?,
      usageCount: fields[20] as int,
      firestoreId: fields[21] as String,
      lastUpdatedAt: fields[22] as DateTime?,
      isPinned: fields[23] == null ? false : fields[23] as bool,
      tags: (fields[24] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TaskTemplate obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.taskType)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.priority)
      ..writeByte(7)
      ..write(obj.motivation)
      ..writeByte(8)
      ..write(obj.reward)
      ..writeByte(9)
      ..write(obj.dueTimeMinutes)
      ..writeByte(10)
      ..write(obj.daysOffset)
      ..writeByte(11)
      ..write(obj.recurrenceDay)
      ..writeByte(12)
      ..write(obj.financialCost)
      ..writeByte(13)
      ..write(obj.financialBenefit)
      ..writeByte(14)
      ..write(obj.financialCategoryId)
      ..writeByte(15)
      ..write(obj.financialNote)
      ..writeByte(16)
      ..write(obj.autoGenerateTransaction)
      ..writeByte(17)
      ..write(obj.linkedRecurringTransactionId)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.lastUsedAt)
      ..writeByte(20)
      ..write(obj.usageCount)
      ..writeByte(21)
      ..write(obj.firestoreId)
      ..writeByte(22)
      ..write(obj.lastUpdatedAt)
      ..writeByte(23)
      ..write(obj.isPinned)
      ..writeByte(24)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
