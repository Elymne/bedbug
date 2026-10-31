import 'dart:typed_data';

import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_frame_decoder_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_frame.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/binary_exchange_frame_codec_gateway.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/binary_exchange_frame_decoder_gateway.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Codec testé.
const BinaryExchangeFrameCodecGateway _codec = BinaryExchangeFrameCodecGateway();

/// Retourne un décodeur neuf.
ExchangeFrameDecoderGateway _decoder() {
  return _codec.createDecoder();
}

/// Retourne les octets d'une trame de type [type] et de charge utile [payload].
///
/// - [type] : type de la trame.
/// - [payload] : charge utile.
Uint8List _frameBytes(ExchangeFrameType type, List<int> payload) {
  return _codec.encode(ExchangeFrame(type, Uint8List.fromList(payload)));
}

/// Retourne un en-tête annonçant [length] octets, pour le type de valeur [typeValue].
///
/// - [typeValue] : valeur du type sur le fil.
/// - [length] : longueur annoncée.
Uint8List _header(int typeValue, int length) {
  final bytes = Uint8List(exchangeFrameHeaderBytes);
  ByteData.sublistView(bytes)
    ..setUint8(0, typeValue)
    ..setUint32(1, length);
  return bytes;
}

void main() {
  group('BinaryExchangeFrameCodecGateway', () {
    test('écrit le type, la longueur en gros-boutiste, puis la charge utile', () {
      expect(_frameBytes(ExchangeFrameType.offer, [7, 8, 9]), [0x02, 0, 0, 0, 3, 7, 8, 9]);
    });
  });

  group('BinaryExchangeFrameDecoderGateway', () {
    test('décode une trame arrivée en un seul morceau', () {
      final frames = _decoder().add(_frameBytes(ExchangeFrameType.request, [1, 2, 3]));

      expect(frames.single.type, ExchangeFrameType.request);
      expect(frames.single.payload, [1, 2, 3]);
    });

    test('reconstitue une trame arrivée octet par octet', () {
      final decoder = _decoder();
      final frames = <ExchangeFrame>[];
      for (final byte in _frameBytes(ExchangeFrameType.data, [1, 2, 3, 4])) {
        frames.addAll(decoder.add(Uint8List.fromList([byte])));
      }

      expect(frames.single.type, ExchangeFrameType.data);
      expect(frames.single.payload, [1, 2, 3, 4]);
    });

    test('sépare plusieurs trames arrivées dans le même morceau', () {
      final frames = _decoder().add(
        Uint8List.fromList([
          ..._frameBytes(ExchangeFrameType.hello, [1]),
          ..._frameBytes(ExchangeFrameType.done, []),
          ..._frameBytes(ExchangeFrameType.offer, [2, 3]),
        ]),
      );

      expect(frames.map((frame) => frame.type), [
        ExchangeFrameType.hello,
        ExchangeFrameType.done,
        ExchangeFrameType.offer,
      ]);
      expect(frames.last.payload, [2, 3]);
    });

    test('garde le début d\'une trame coupée entre deux morceaux', () {
      final decoder = _decoder();
      final bytes = _frameBytes(ExchangeFrameType.offer, [1, 2, 3]);

      expect(decoder.add(Uint8List.sublistView(bytes, 0, 6)), isEmpty);
      expect(decoder.add(Uint8List.sublistView(bytes, 6)).single.payload, [1, 2, 3]);
    });

    test('rend une trame sans charge utile dès la fin de son en-tête', () {
      expect(_decoder().add(_frameBytes(ExchangeFrameType.done, [])).single.type, ExchangeFrameType.done);
    });

    test('refuse un type inconnu', () {
      expect(() => _decoder().add(_header(0x7F, 0)), throwsA(isA<DataException>()));
    });

    test('refuse dès l\'en-tête une taille trop grande, sans attendre la charge utile', () {
      final oversized = _header(ExchangeFrameType.data.value, maxExchangeDataBytes + 1);

      expect(() => _decoder().add(oversized), throwsA(isA<DataException>()));
    });

    test('refuse une charge utile sur une trame qui n\'en a pas', () {
      expect(() => _decoder().add(_header(ExchangeFrameType.done.value, 1)), throwsA(isA<DataException>()));
    });
  });
}
