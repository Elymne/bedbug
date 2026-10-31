import 'dart:typed_data';

import 'package:bedbug/features/exchange/domain/gateways/exchange_frame_decoder_gateway.dart';
import 'package:bedbug/features/exchange/domain/object_values/exchange_frame.dart';

/// Contrat de mise en octets des trames du protocole d'échange.
///
/// Le protocole raisonne en trames, mais le transport n'est qu'un flux d'octets sans frontières de messages : ce
/// gateway porte le format qui permet de retrouver où finit chaque trame.
abstract class ExchangeFrameCodecGateway {
  /// Retourne [frame] telle qu'elle voyage.
  ///
  /// - [frame] : trame à encoder.
  Uint8List encode(ExchangeFrame frame);

  /// Retourne un décodeur neuf, à réserver à une seule connexion.
  ExchangeFrameDecoderGateway createDecoder();
}
