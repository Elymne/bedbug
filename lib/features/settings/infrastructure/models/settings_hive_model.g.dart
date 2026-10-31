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
      isAnonymousByDefault: fields[2] == null ? false : fields[2] as bool,
      isExchangeEnabled: fields[3] == null ? false : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.blockedUrls)
      ..writeByte(1)
      ..write(obj.blockedWords)
      ..writeByte(2)
      ..write(obj.isAnonymousByDefault)
      ..writeByte(3)
      ..write(obj.isExchangeEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
