// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingsAccountAdapter extends TypeAdapter<SavingsAccount> {
  @override
  final int typeId = 32;

  @override
  SavingsAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsAccount(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as SavingsAccountType,
      initialBalance: fields[3] as double,
      currentBalance: fields[4] as double,
      monthlyContribution: fields[5] as double,
      annualInterestRate: fields[6] as double,
      icon: fields[7] as String?,
      color: fields[8] as String?,
      startDate: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime,
      lastUpdatedAt: fields[11] as DateTime?,
      deleted: fields[12] == null ? false : fields[12] as bool,
      deletedAt: fields[13] as DateTime?,
      firestoreId: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsAccount obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.initialBalance)
      ..writeByte(4)
      ..write(obj.currentBalance)
      ..writeByte(5)
      ..write(obj.monthlyContribution)
      ..writeByte(6)
      ..write(obj.annualInterestRate)
      ..writeByte(7)
      ..write(obj.icon)
      ..writeByte(8)
      ..write(obj.color)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.lastUpdatedAt)
      ..writeByte(12)
      ..write(obj.deleted)
      ..writeByte(13)
      ..write(obj.deletedAt)
      ..writeByte(14)
      ..write(obj.firestoreId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavingsAccountTypeAdapter extends TypeAdapter<SavingsAccountType> {
  @override
  final int typeId = 31;

  @override
  SavingsAccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SavingsAccountType.savings;
      case 1:
        return SavingsAccountType.investment;
      default:
        return SavingsAccountType.savings;
    }
  }

  @override
  void write(BinaryWriter writer, SavingsAccountType obj) {
    switch (obj) {
      case SavingsAccountType.savings:
        writer.writeByte(0);
        break;
      case SavingsAccountType.investment:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsAccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
