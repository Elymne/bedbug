import 'dart:typed_data';

import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';

/// Signature en tête d'un dessin encodé : « BBD » puis la version du format.
const List<int> _header = [0x42, 0x42, 0x44, 0x01];

/// Marqueur d'un trait dans le flux encodé.
const int _strokeTag = 0;

/// Marqueur d'un remplissage dans le flux encodé.
const int _fillTag = 1;

/// Nombre maximal d'octets d'un entier variable : assez pour 32 bits.
const int _maxVarintBytes = 5;

/// Encodage binaire compact d'un [Drawing], pour le stockage et la transmission.
///
/// Les points d'un trait sont encodés en écarts avec le point précédent, en
/// entiers de taille variable : un trait tracé au doigt avance par petits
/// pas, et la plupart des points tiennent sur deux octets.
///
/// Le décodage ne fait confiance à rien : il refuse un flux tronqué, une
/// signature inconnue, ou un nombre d'opérations ou de points qui dépasse
/// les limites d'un dessin, avant même de réserver la mémoire
/// correspondante. Il lève alors une [FormatException]. Les autres limites
/// sont vérifiées ensuite, par `DrawingValidationService`.
class DrawingBinaryCodec {
  /// Crée un [DrawingBinaryCodec].
  const DrawingBinaryCodec();

  /// Retourne [drawing] encodé.
  ///
  /// - [drawing] : dessin à encoder, déjà vérifié.
  Uint8List encode(Drawing drawing) {
    final writer = _ByteWriter()
      ..addBytes(_header)
      ..addByte(drawing.palette.length);
    for (final color in drawing.palette) {
      writer.addUint32(color);
    }
    writer.addVarint(drawing.operations.length);
    for (final operation in drawing.operations) {
      switch (operation) {
        case DrawingFill(:final point):
          writer
            ..addByte(_fillTag)
            ..addByte(operation.layer)
            ..addByte(operation.colorIndex)
            ..addVarint(point.x)
            ..addVarint(point.y);
        case DrawingStroke(:final brush, :final size, :final seed, :final points):
          writer
            ..addByte(_strokeTag)
            ..addByte(operation.layer)
            ..addByte(operation.colorIndex)
            ..addByte(brush.value)
            ..addByte(size)
            ..addUint32(seed)
            ..addVarint(points.length);
          var previous = const DrawingPoint(0, 0);
          for (final point in points) {
            writer
              ..addSignedVarint(point.x - previous.x)
              ..addSignedVarint(point.y - previous.y);
            previous = point;
          }
      }
    }
    return writer.toBytes();
  }

  /// Retourne le dessin encodé dans [bytes].
  ///
  /// Lève une [FormatException] si le flux est mal formé ou dépasse les limites d'un dessin.
  ///
  /// - [bytes] : dessin encodé, reçu ou stocké.
  Drawing decode(Uint8List bytes) {
    final reader = _ByteReader(bytes);
    for (final expected in _header) {
      if (reader.readByte() != expected) {
        throw const FormatException('Signature de dessin inconnue');
      }
    }

    final paletteLength = reader.readByte();
    if (paletteLength != drawingPaletteSize) {
      throw const FormatException('Palette de taille invalide');
    }
    final palette = [for (var index = 0; index < paletteLength; index++) reader.readUint32()];

    final operationCount = reader.readVarint();
    if (operationCount > maxDrawingOperations) {
      throw const FormatException('Trop d\'opérations');
    }
    var pointTotal = 0;
    final operations = <DrawingOperation>[];
    for (var operationIndex = 0; operationIndex < operationCount; operationIndex++) {
      final tag = reader.readByte();
      final layer = reader.readByte();
      final colorIndex = reader.readByte();
      if (tag == _fillTag) {
        operations.add(
          DrawingFill(
            layer: layer,
            colorIndex: colorIndex,
            point: DrawingPoint(reader.readVarint(), reader.readVarint()),
          ),
        );
        continue;
      }
      if (tag != _strokeTag) {
        throw const FormatException('Opération inconnue');
      }

      final brush = DrawingBrush.fromValue(reader.readByte());
      if (brush == null) {
        throw const FormatException('Pinceau inconnu');
      }
      final size = reader.readByte();
      final seed = reader.readUint32();
      final pointCount = reader.readVarint();
      pointTotal += pointCount;
      if (pointCount > maxDrawingStrokePoints || pointTotal > maxDrawingPoints) {
        throw const FormatException('Trop de points');
      }
      final points = <DrawingPoint>[];
      var x = 0;
      var y = 0;
      for (var pointIndex = 0; pointIndex < pointCount; pointIndex++) {
        x += reader.readSignedVarint();
        y += reader.readSignedVarint();
        points.add(DrawingPoint(x, y));
      }
      operations.add(
        DrawingStroke(layer: layer, colorIndex: colorIndex, brush: brush, size: size, seed: seed, points: points),
      );
    }
    if (!reader.isAtEnd) {
      throw const FormatException('Octets en trop après le dessin');
    }
    return Drawing(palette: palette, operations: operations);
  }
}

/// Écriture séquentielle d'octets.
class _ByteWriter {
  /// Octets écrits.
  final BytesBuilder _builder = BytesBuilder(copy: false);

  /// Ajoute [bytes].
  void addBytes(List<int> bytes) {
    _builder.add(bytes);
  }

  /// Ajoute un octet.
  void addByte(int value) {
    _builder.addByte(value & 0xFF);
  }

  /// Ajoute un entier non signé sur 32 bits, poids fort en premier.
  void addUint32(int value) {
    addBytes([(value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF]);
  }

  /// Ajoute un entier positif de taille variable (7 bits par octet, le bit fort indiquant une suite).
  void addVarint(int value) {
    var remaining = value;
    while (remaining >= 0x80) {
      addByte((remaining & 0x7F) | 0x80);
      remaining >>= 7;
    }
    addByte(remaining);
  }

  /// Ajoute un entier signé de taille variable, les petites valeurs négatives restant courtes (zigzag).
  void addSignedVarint(int value) {
    addVarint(value >= 0 ? value * 2 : -value * 2 - 1);
  }

  /// Retourne les octets écrits.
  Uint8List toBytes() {
    return _builder.toBytes();
  }
}

/// Lecture séquentielle d'octets, qui refuse de lire au-delà de la fin.
class _ByteReader {
  _ByteReader(this._bytes);

  /// Octets à lire.
  final Uint8List _bytes;

  /// Position du prochain octet à lire.
  int _offset = 0;

  /// Indique si tous les octets ont été lus.
  bool get isAtEnd {
    return _offset == _bytes.length;
  }

  /// Lit un octet.
  int readByte() {
    if (_offset >= _bytes.length) {
      throw const FormatException('Dessin tronqué');
    }
    return _bytes[_offset++];
  }

  /// Lit un entier non signé sur 32 bits, poids fort en premier.
  int readUint32() {
    return (readByte() << 24) | (readByte() << 16) | (readByte() << 8) | readByte();
  }

  /// Lit un entier positif de taille variable.
  int readVarint() {
    var value = 0;
    for (var index = 0; index < _maxVarintBytes; index++) {
      final byte = readByte();
      value |= (byte & 0x7F) << (7 * index);
      if (byte < 0x80) {
        return value;
      }
    }
    throw const FormatException('Entier trop long');
  }

  /// Lit un entier signé de taille variable (zigzag).
  int readSignedVarint() {
    final encoded = readVarint();
    return encoded.isEven ? encoded ~/ 2 : -(encoded + 1) ~/ 2;
  }
}
