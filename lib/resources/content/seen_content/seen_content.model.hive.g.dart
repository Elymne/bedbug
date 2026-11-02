// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seen_content.model.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SeenContentHiveModelAdapter extends TypeAdapter<SeenContentHiveModel> {
  @override
  final typeId = 13;

  @override
  SeenContentHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return SeenContentHiveModel(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      updatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SeenContentHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeenContentHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
