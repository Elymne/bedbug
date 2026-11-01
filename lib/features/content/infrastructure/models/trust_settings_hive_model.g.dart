// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trust_settings_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrustSettingsHiveModelAdapter extends TypeAdapter<TrustSettingsHiveModel> {
  @override
  final typeId = 9;

  @override
  TrustSettingsHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return TrustSettingsHiveModel(
      mediaTrustedPatterns: fields[0] == null ? [] : (fields[0] as List).cast<String>(),
      mediaGreyPatterns: fields[1] == null ? [] : (fields[1] as List).cast<String>(),
      linkTrustedPatterns: fields[2] == null ? [] : (fields[2] as List).cast<String>(),
      linkGreyPatterns: fields[3] == null ? [] : (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TrustSettingsHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.mediaTrustedPatterns)
      ..writeByte(1)
      ..write(obj.mediaGreyPatterns)
      ..writeByte(2)
      ..write(obj.linkTrustedPatterns)
      ..writeByte(3)
      ..write(obj.linkGreyPatterns);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrustSettingsHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
