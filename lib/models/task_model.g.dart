// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      firestoreId: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      isCompleted: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      dueDate: fields[5] as DateTime?,
      category: fields[6] as String,
      priority: fields[7] as int,
      dueTimeMinutes: fields[8] as int?,
      motivation: fields[9] as String?,
      reward: fields[10] as String?,
      recurrenceDay: fields[11] as int?,
      deadline: fields[12] as DateTime?,
      deleted: fields[13] == null ? false : fields[13] as bool,
      deletedAt: fields[14] as DateTime?,
      lastUpdatedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.firestoreId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.dueTimeMinutes)
      ..writeByte(9)
      ..write(obj.motivation)
      ..writeByte(10)
      ..write(obj.reward)
      ..writeByte(11)
      ..write(obj.recurrenceDay)
      ..writeByte(12)
      ..write(obj.deadline)
      ..writeByte(13)
      ..write(obj.deleted)
      ..writeByte(14)
      ..write(obj.deletedAt)
      ..writeByte(15)
      ..write(obj.lastUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
