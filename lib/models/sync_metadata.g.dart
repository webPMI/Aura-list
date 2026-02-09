// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncMetadataAdapter extends TypeAdapter<SyncMetadata> {
  @override
  final int typeId = 5;

  @override
  SyncMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetadata(
      recordId: fields[0] as String,
      recordType: fields[1] as String,
      lastLocalUpdate: fields[2] as DateTime,
      lastCloudSync: fields[3] as DateTime?,
      isPendingSync: fields[4] as bool,
      hasConflict: fields[5] as bool,
      syncAttempts: fields[6] as int,
      lastSyncError: fields[7] as String?,
      remoteVersionAt: fields[8] as DateTime?,
      localChecksum: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadata obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.recordId)
      ..writeByte(1)
      ..write(obj.recordType)
      ..writeByte(2)
      ..write(obj.lastLocalUpdate)
      ..writeByte(3)
      ..write(obj.lastCloudSync)
      ..writeByte(4)
      ..write(obj.isPendingSync)
      ..writeByte(5)
      ..write(obj.hasConflict)
      ..writeByte(6)
      ..write(obj.syncAttempts)
      ..writeByte(7)
      ..write(obj.lastSyncError)
      ..writeByte(8)
      ..write(obj.remoteVersionAt)
      ..writeByte(9)
      ..write(obj.localChecksum);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
