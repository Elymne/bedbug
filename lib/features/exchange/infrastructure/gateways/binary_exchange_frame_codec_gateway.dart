import 'dart:typed_data';

import 'package:bedbug/features/exchange/domain/gateways/exchange_frame_codec_gateway.dart';
import 'package:bedbug/features/exchange/domain/gateways/exchange_frame_decoder_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_frame.dart';
import 'package:bedbug/features/exchange/infrastructure/gateways/binary_exchange_frame_decoder_gateway.dart';
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
