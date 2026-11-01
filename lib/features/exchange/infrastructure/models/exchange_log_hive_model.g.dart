// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_log_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExchangeLogHiveModelAdapter extends TypeAdapter<ExchangeLogHiveModel> {
  @override
  final typeId = 10;

  @override
  ExchangeLogHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return ExchangeLogHiveModel(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      updatedAt: fields[2] as DateTime,
      peerAddress: fields[3] as String,
      outcome: (fields[4] as num).toInt(),
      isInitiator: fields[5] as bool?,
      durationInMillis: (fields[6] as num).toInt(),
      awaitedFrame: (fields[7] as num?)?.toInt(),
      sentBytes: (fields[8] as num).toInt(),
      receivedBytes: (fields[9] as num).toInt(),
      importedContents: (fields[10] as num).toInt(),
      rejectedContents: (fields[11] as num).toInt(),
      importedReactions: (fields[12] as num).toInt(),
      rejectedReactions: (fields[13] as num).toInt(),
      removedContents: (fields[14] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeLogHiveModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.peerAddress)
      ..writeByte(4)
      ..write(obj.outcome)
      ..writeByte(5)
      ..write(obj.isInitiator)
      ..writeByte(6)
      ..write(obj.durationInMillis)
      ..writeByte(7)
      ..write(obj.awaitedFrame)
      ..writeByte(8)
      ..write(obj.sentBytes)
      ..writeByte(9)
      ..write(obj.receivedBytes)
      ..writeByte(10)
      ..write(obj.importedContents)
      ..writeByte(11)
      ..write(obj.rejectedContents)
      ..writeByte(12)
      ..write(obj.importedReactions)
      ..writeByte(13)
      ..write(obj.rejectedReactions)
      ..writeByte(14)
      ..write(obj.removedContents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeLogHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
