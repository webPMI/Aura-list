// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurrenceRuleAdapter extends TypeAdapter<RecurrenceRule> {
  @override
  final int typeId = 9;

  @override
  RecurrenceRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurrenceRule(
      frequency: fields[0] as RecurrenceFrequency,
      interval: fields[1] as int,
      byDays: (fields[2] as List?)?.cast<WeekDay>(),
      byMonthDays: (fields[3] as List?)?.cast<int>(),
      byMonths: (fields[4] as List?)?.cast<int>(),
      weekPosition: fields[5] as int?,
      weekParity: fields[6] as WeekParity?,
      startDate: fields[7] as DateTime,
      endDate: fields[8] as DateTime?,
      count: fields[9] as int?,
      exceptionDates: (fields[10] as List?)?.cast<DateTime>(),
      timezone: fields[11] as String?,
      preset: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurrenceRule obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.frequency)
      ..writeByte(1)
      ..write(obj.interval)
      ..writeByte(2)
      ..write(obj.byDays)
      ..writeByte(3)
      ..write(obj.byMonthDays)
      ..writeByte(4)
      ..write(obj.byMonths)
      ..writeByte(5)
      ..write(obj.weekPosition)
      ..writeByte(6)
      ..write(obj.weekParity)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.count)
      ..writeByte(10)
      ..write(obj.exceptionDates)
      ..writeByte(11)
      ..write(obj.timezone)
      ..writeByte(12)
      ..write(obj.preset);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceFrequencyAdapter extends TypeAdapter<RecurrenceFrequency> {
  @override
  final int typeId = 10;

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

class WeekDayAdapter extends TypeAdapter<WeekDay> {
  @override
  final int typeId = 11;

  @override
  WeekDay read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WeekDay.monday;
      case 1:
        return WeekDay.tuesday;
      case 2:
        return WeekDay.wednesday;
      case 3:
        return WeekDay.thursday;
      case 4:
        return WeekDay.friday;
      case 5:
        return WeekDay.saturday;
      case 6:
        return WeekDay.sunday;
      default:
        return WeekDay.monday;
    }
  }

  @override
  void write(BinaryWriter writer, WeekDay obj) {
    switch (obj) {
      case WeekDay.monday:
        writer.writeByte(0);
        break;
      case WeekDay.tuesday:
        writer.writeByte(1);
        break;
      case WeekDay.wednesday:
        writer.writeByte(2);
        break;
      case WeekDay.thursday:
        writer.writeByte(3);
        break;
      case WeekDay.friday:
        writer.writeByte(4);
        break;
      case WeekDay.saturday:
        writer.writeByte(5);
        break;
      case WeekDay.sunday:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeekParityAdapter extends TypeAdapter<WeekParity> {
  @override
  final int typeId = 12;

  @override
  WeekParity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WeekParity.a;
      case 1:
        return WeekParity.b;
      default:
        return WeekParity.a;
    }
  }

  @override
  void write(BinaryWriter writer, WeekParity obj) {
    switch (obj) {
      case WeekParity.a:
        writer.writeByte(0);
        break;
      case WeekParity.b:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekParityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
