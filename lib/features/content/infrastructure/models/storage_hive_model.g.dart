// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_hive_model.dart';

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
      id: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
      updatedAt: (fields[2] as num).toInt(),
      maxSizeInBytes: (fields[3] as num).toInt(),
      strategy: (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, StorageHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.maxSizeInBytes)
      ..writeByte(4)
      ..write(obj.strategy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
