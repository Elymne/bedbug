// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReactionHiveModelAdapter extends TypeAdapter<ReactionHiveModel> {
  @override
  final typeId = 8;

  @override
  ReactionHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return ReactionHiveModel(
      id: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
      updatedAt: (fields[2] as num).toInt(),
      contentId: fields[3] as String,
      authorId: fields[4] as String,
      avatarText: fields[5] as String,
      bubbleText: fields[6] as String?,
      colorArgb: (fields[7] as num?)?.toInt(),
      ghostSpeed: fields[8] == null ? 1.0 : (fields[8] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ReactionHiveModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.contentId)
      ..writeByte(4)
      ..write(obj.authorId)
      ..writeByte(5)
      ..write(obj.avatarText)
      ..writeByte(6)
      ..write(obj.bubbleText)
      ..writeByte(7)
      ..write(obj.colorArgb)
      ..writeByte(8)
      ..write(obj.ghostSpeed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
