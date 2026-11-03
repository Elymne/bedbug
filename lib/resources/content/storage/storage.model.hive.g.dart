// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage.model.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StorageHiveModelAdapter extends TypeAdapter<StorageHiveModel> {
  @override
  final typeId = 6;

  @override
  StorageHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return StorageHiveModel(
      maxSizeInBytes: (fields[0] as num).toInt(),
      currentSizeInBytes: (fields[2] as num).toInt(),
      strategy: (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StorageHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.maxSizeInBytes)
      ..writeByte(1)
      ..write(obj.strategy)
      ..writeByte(2)
      ..write(obj.currentSizeInBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
