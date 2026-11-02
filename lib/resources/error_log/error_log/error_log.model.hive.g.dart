// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_log.model.hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ErrorLogHiveModelAdapter extends TypeAdapter<ErrorLogHiveModel> {
  @override
  final typeId = 11;

  @override
  ErrorLogHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return ErrorLogHiveModel(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      updatedAt: fields[2] as DateTime,
      source: fields[3] as String,
      errorType: fields[4] as String,
      message: fields[5] as String,
      stackTrace: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ErrorLogHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.errorType)
      ..writeByte(5)
      ..write(obj.message)
      ..writeByte(6)
      ..write(obj.stackTrace);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorLogHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
