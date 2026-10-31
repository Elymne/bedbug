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
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return ContentHiveModel(
      id: fields[0] as String,
      createdAt: (fields[1] as num).toInt(),
      updatedAt: (fields[2] as num).toInt(),
      signatureId: fields[3] as String,
      type: fields[4] as String,
      origin: (fields[7] as num).toInt(),
      broadcastScore: (fields[19] as num).toDouble(),
      survivalScore: (fields[20] as num).toDouble(),
      displayScore: (fields[21] as num).toDouble(),
      bounce: (fields[8] as num).toInt(),
      title: fields[5] as String?,
      body: fields[6] as String?,
      url: fields[10] as String?,
      mediaUrls: fields[27] == null ? [] : (fields[27] as List).cast<String>(),
      mediaKinds: fields[28] == null ? [] : (fields[28] as List).cast<int>(),
      drawingData: fields[29] as Uint8List?,
      flair: fields[23] == null ? 'public' : fields[23] as String,
      sizeInBytes: (fields[13] as num).toInt(),
      ogImageUrl: fields[14] as String?,
      ogTitle: fields[15] as String?,
      ogDescription: fields[16] as String?,
      tagValues: fields[22] == null ? const [] : (fields[22] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, ContentHiveModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.signatureId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.body)
      ..writeByte(7)
      ..write(obj.origin)
      ..writeByte(8)
      ..write(obj.bounce)
      ..writeByte(10)
      ..write(obj.url)
      ..writeByte(13)
      ..write(obj.sizeInBytes)
      ..writeByte(14)
      ..write(obj.ogImageUrl)
      ..writeByte(15)
      ..write(obj.ogTitle)
      ..writeByte(16)
      ..write(obj.ogDescription)
      ..writeByte(19)
      ..write(obj.broadcastScore)
      ..writeByte(20)
      ..write(obj.survivalScore)
      ..writeByte(21)
      ..write(obj.displayScore)
      ..writeByte(22)
      ..write(obj.tagValues)
      ..writeByte(23)
      ..write(obj.flair)
      ..writeByte(27)
      ..write(obj.mediaUrls)
      ..writeByte(28)
      ..write(obj.mediaKinds)
      ..writeByte(29)
      ..write(obj.drawingData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentHiveModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
