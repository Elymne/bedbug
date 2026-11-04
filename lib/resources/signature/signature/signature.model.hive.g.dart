// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signature.model.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SignatureHiveModelAdapter extends TypeAdapter<SignatureHiveModel> {
  @override
  final typeId = 0;

  @override
  SignatureHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return SignatureHiveModel(
      id: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
      updatedAt: (fields[2] as num).toInt(),
      pseudo: fields[3] as String,
      avatarFrames: fields[12] == null ? ['(◕‿◕)'] : (fields[12] as List).cast<String>(),
      colorArgb: (fields[8] as num?)?.toInt(),
      ghostSpeed: fields[9] == null ? 1.0 : (fields[9] as num).toDouble(),
      avatarFrameSpeed: fields[13] == null ? 1.0 : (fields[13] as num).toDouble(),
      socialLinks: fields[7] == null ? {} : (fields[7] as Map).cast<int, String>(),
      bio: fields[10] as String?,
      bioFont: fields[11] == null ? 0 : (fields[11] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, SignatureHiveModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.pseudo)
      ..writeByte(7)
      ..write(obj.socialLinks)
      ..writeByte(8)
      ..write(obj.colorArgb)
      ..writeByte(9)
      ..write(obj.ghostSpeed)
      ..writeByte(10)
      ..write(obj.bio)
      ..writeByte(11)
      ..write(obj.bioFont)
      ..writeByte(12)
      ..write(obj.avatarFrames)
      ..writeByte(13)
      ..write(obj.avatarFrameSpeed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
