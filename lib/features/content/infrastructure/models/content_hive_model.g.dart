// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContentHiveModelAdapter extends TypeAdapter<ContentHiveModel> {
  @override
  final typeId = 1;

  @override
  ContentHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContentHiveModel(
      id: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
      updatedAt: (fields[2] as num).toInt(),
      authorId: fields[3] as String,
      type: fields[4] as String,
      title: fields[5] as String?,
      body: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ContentHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.authorId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.body);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
