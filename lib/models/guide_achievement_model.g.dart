// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_achievement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GuideAchievementAdapter extends TypeAdapter<GuideAchievement> {
  @override
  final int typeId = 13;

  @override
  GuideAchievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GuideAchievement(
      id: fields[0] as String,
      titleEs: fields[1] as String,
      description: fields[2] as String,
      guideId: fields[3] as String,
      category: fields[4] as String,
      condition: fields[5] as String,
      earnedAt: fields[6] as DateTime?,
      isEarned: fields[7] as bool,
      guideMessage: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GuideAchievement obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titleEs)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.guideId)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.condition)
      ..writeByte(6)
      ..write(obj.earnedAt)
      ..writeByte(7)
      ..write(obj.isEarned)
      ..writeByte(8)
      ..write(obj.guideMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuideAchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
