// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keychain_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KeychainHiveModelAdapter extends TypeAdapter<KeychainHiveModel> {
  @override
  final typeId = 4;

  @override
  KeychainHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeychainHiveModel(
      id: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
      updatedAt: (fields[2] as num).toInt(),
      label: fields[3] as String,
      subId: fields[4] as String,
      keys: (fields[5] as List).cast<PrivateKeyHiveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, KeychainHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.label)
      ..writeByte(4)
      ..write(obj.subId)
      ..writeByte(5)
      ..write(obj.keys);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeychainHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrivateKeyHiveModelAdapter extends TypeAdapter<PrivateKeyHiveModel> {
  @override
  final typeId = 5;

  @override
  PrivateKeyHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrivateKeyHiveModel(
      value: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, PrivateKeyHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.value)
      ..writeByte(1)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivateKeyHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
