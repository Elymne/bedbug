// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.model.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsHiveModelAdapter extends TypeAdapter<UserSettingsHiveModel> {
  @override
  final typeId = 7;

  @override
  UserSettingsHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettingsHiveModel(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      updatedAt: fields[2] as DateTime,
      blockedUrls: (fields[3] as List).cast<String>(),
      blockedWords: (fields[4] as List).cast<String>(),
      isAnonymousByDefault: fields[5] as bool,
      isExchangeEnabled: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettingsHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.blockedUrls)
      ..writeByte(4)
      ..write(obj.blockedWords)
      ..writeByte(5)
      ..write(obj.isAnonymousByDefault)
      ..writeByte(6)
      ..write(obj.isExchangeEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
