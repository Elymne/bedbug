// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsHiveModelAdapter extends TypeAdapter<SettingsHiveModel> {
  @override
  final typeId = 7;

  @override
  SettingsHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return SettingsHiveModel(
      blockedUrls: (fields[0] as List).cast<String>(),
      blockedWords: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SettingsHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.blockedUrls)
      ..writeByte(1)
      ..write(obj.blockedWords);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
