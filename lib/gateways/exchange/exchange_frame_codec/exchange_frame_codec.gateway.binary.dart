import 'dart:typed_data';

import 'package:bedbug/gateways/exchange/exchange_frame/exchange_frame.value_object.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_codec/exchange_frame_codec.gateway.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_decoder/exchange_frame_decoder.config.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_decoder/exchange_frame_decoder.gateway.binary.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_decoder/exchange_frame_decoder.gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [BinaryExchangeFrameCodecGateway].
final exchangeFrameCodecGatewayProvider = Provider<ExchangeFrameCodecGateway>((ref) {
  return const BinaryExchangeFrameCodecGateway();
});

/// Implémentation de [ExchangeFrameCodecGateway] : `[type][longueur][charge utile]`.
///
/// La longueur permet de savoir où finit chaque trame dans un flux d'octets sans frontières de messages.
class BinaryExchangeFrameCodecGateway implements ExchangeFrameCodecGateway {
  /// Crée un [BinaryExchangeFrameCodecGateway].
  const BinaryExchangeFrameCodecGateway();

  @override
  Uint8List encode(ExchangeFrame frame) {
    final bytes = Uint8List(exchangeFrameHeaderBytes + frame.payload.length);
    ByteData.sublistView(bytes)
      ..setUint8(0, frame.type.value)
      ..setUint32(1, frame.payload.length);
    bytes.setRange(exchangeFrameHeaderBytes, bytes.length, frame.payload);
    return bytes;
  }

  @override
  ExchangeFrameDecoderGateway createDecoder() {
    return BinaryExchangeFrameDecoderGateway();
  }
}
