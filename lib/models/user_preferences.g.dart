// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 4;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      odId: fields[0] as String,
      hasAcceptedTerms: fields[1] as bool,
      hasAcceptedPrivacy: fields[2] as bool,
      termsAcceptedAt: fields[3] as DateTime?,
      privacyAcceptedAt: fields[4] as DateTime?,
      notificationsEnabled: fields[5] as bool,
      calendarSyncEnabled: fields[6] as bool,
      lastSyncTimestamp: fields[7] as DateTime?,
      collectionLastSync: (fields[8] as Map?)?.cast<String, String>(),
      syncOnMobileData: fields[9] as bool,
      syncDebounceMs: fields[10] as int,
      cloudSyncEnabled: fields[11] as bool,
      firestoreId: fields[12] as String?,
      lastUpdatedAt: fields[13] as DateTime?,
      restDayOfWeek: fields[14] as int?,
      notificationDeadlineReminders:
          fields[15] == null ? true : fields[15] as bool,
      notificationQuietHourStart: fields[16] == null ? 22 : fields[16] as int,
      notificationQuietHourEnd: fields[17] == null ? 8 : fields[17] as int,
      notificationHighPriorityOnly:
          fields[18] == null ? false : fields[18] as bool,
      notificationSound: fields[19] == null ? true : fields[19] as bool,
      notificationVibration: fields[20] == null ? true : fields[20] as bool,
      notificationEscalationDays: (fields[21] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.odId)
      ..writeByte(1)
      ..write(obj.hasAcceptedTerms)
      ..writeByte(2)
      ..write(obj.hasAcceptedPrivacy)
      ..writeByte(3)
      ..write(obj.termsAcceptedAt)
      ..writeByte(4)
      ..write(obj.privacyAcceptedAt)
      ..writeByte(5)
      ..write(obj.notificationsEnabled)
      ..writeByte(6)
      ..write(obj.calendarSyncEnabled)
      ..writeByte(7)
      ..write(obj.lastSyncTimestamp)
      ..writeByte(8)
      ..write(obj.collectionLastSync)
      ..writeByte(9)
      ..write(obj.syncOnMobileData)
      ..writeByte(10)
      ..write(obj.syncDebounceMs)
      ..writeByte(11)
      ..write(obj.cloudSyncEnabled)
      ..writeByte(12)
      ..write(obj.firestoreId)
      ..writeByte(13)
      ..write(obj.lastUpdatedAt)
      ..writeByte(14)
      ..write(obj.restDayOfWeek)
      ..writeByte(15)
      ..write(obj.notificationDeadlineReminders)
      ..writeByte(16)
      ..write(obj.notificationQuietHourStart)
      ..writeByte(17)
      ..write(obj.notificationQuietHourEnd)
      ..writeByte(18)
      ..write(obj.notificationHighPriorityOnly)
      ..writeByte(19)
      ..write(obj.notificationSound)
      ..writeByte(20)
      ..write(obj.notificationVibration)
      ..writeByte(21)
      ..write(obj.notificationEscalationDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
