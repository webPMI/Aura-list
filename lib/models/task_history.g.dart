// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskHistoryAdapter extends TypeAdapter<TaskHistory> {
  @override
  final int typeId = 3;

  @override
  TaskHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskHistory(
      taskId: fields[0] as String,
      date: fields[1] as DateTime,
      wasCompleted: fields[2] as bool,
      completedAt: fields[3] as DateTime?,
      firestoreId: fields[4] as String?,
      lastUpdatedAt: fields[5] as DateTime?,
      deleted: fields[6] as bool,
      deletedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskHistory obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.taskId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.wasCompleted)
      ..writeByte(3)
      ..write(obj.completedAt)
      ..writeByte(4)
      ..write(obj.firestoreId)
      ..writeByte(5)
      ..write(obj.lastUpdatedAt)
      ..writeByte(6)
      ..write(obj.deleted)
      ..writeByte(7)
      ..write(obj.deletedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
