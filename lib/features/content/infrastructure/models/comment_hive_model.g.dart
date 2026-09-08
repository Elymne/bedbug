// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommentHiveModelAdapter extends TypeAdapter<CommentHiveModel> {
  @override
  final typeId = 2;

  @override
  CommentHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommentHiveModel(
      id: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
      updatedAt: (fields[2] as num).toInt(),
      contentId: fields[5] as String,
      authorId: fields[3] as String,
      body: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CommentHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.authorId)
      ..writeByte(4)
      ..write(obj.body)
      ..writeByte(5)
      ..write(obj.contentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
