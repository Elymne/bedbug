// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewed_content.model.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ViewedContentHiveModelAdapter extends TypeAdapter<ViewedContentHiveModel> {
  @override
  final typeId = 12;

  @override
  ViewedContentHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return ViewedContentHiveModel(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      updatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ViewedContentHiveModel obj) {
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
      other is ViewedContentHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
