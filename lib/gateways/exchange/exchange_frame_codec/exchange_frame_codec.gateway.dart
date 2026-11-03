import 'dart:typed_data';

import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_codec/exchange_frame_codec.config.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_decoder/exchange_frame_decoder.gateway.dart';

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

/// Unité de message du protocole d'échange : un type et une charge utile opaque.
///
/// Le type dit quoi faire du message sans avoir à lire la charge utile. La mise en octets relève de
/// `ExchangeFrameCodecGateway`.
class ExchangeFrame extends ValueObject {
  /// Crée une [ExchangeFrame].
  ///
  /// - [type] : type de la trame.
  /// - [payload] : charge utile, opaque pour le protocole.
  const ExchangeFrame(this.type, this.payload);

  /// Type de la trame.
  final ExchangeFrameType type;

  /// Charge utile, opaque pour le protocole.
  final Uint8List payload;

  @override
  bool operator ==(Object other) {
    return other is ExchangeFrame && other.type == type && _isSamePayload(other.payload);
  }

  @override
  int get hashCode {
    return Object.hash(type, Object.hashAll(payload));
  }

  @override
  String toString() {
    return 'ExchangeFrame(${type.name}, ${payload.length} octets)';
  }

  /// Indique si [other] contient les mêmes octets que [payload].
  ///
  /// - [other] : charge utile à comparer.
  bool _isSamePayload(Uint8List other) {
    if (other.length != payload.length) {
      return false;
    }
    for (var index = 0; index < payload.length; index++) {
      if (other[index] != payload[index]) {
        return false;
      }
    }
    return true;
  }
}

/// Types de trames du protocole d'échange.
enum ExchangeFrameType {
  /// Présentation : version du protocole, envoyée par les deux appareils dès la connexion.
  hello(0x01, 64),

  /// Offre : ce que l'appareil propose, encodée par `BuildExchangeOfferUsecase`.
  offer(0x02, maxExchangeNegotiationBytes),

  /// Demande : ce que l'appareil choisit dans l'offre du pair, encodée par `SelectFromExchangeOfferUsecase`.
  request(0x03, maxExchangeNegotiationBytes),

  /// Lot : réponse à la demande du pair, encodée par `BuildExchangeBundleUsecase`.
  data(0x04, maxExchangeDataBytes),

  /// Accusé : le lot du pair a été traité. Dernière trame d'un échange réussi.
  done(0x05, 0),

  /// Abandon : l'appareil met fin à l'échange. Permet au pair d'arrêter tout de suite plutôt que d'attendre.
  error(0x06, 0);

  /// Crée un [ExchangeFrameType].
  ///
  /// - [value] : valeur du type sur le fil.
  /// - [maxPayloadBytes] : taille maximale de la charge utile, en octets.
  const ExchangeFrameType(this.value, this.maxPayloadBytes);

  /// Valeur du type sur le fil.
  final int value;

  /// Taille maximale de la charge utile, en octets.
  ///
  /// Vérifiée dès l'en-tête, avant de réserver la mémoire : un pair ne peut pas annoncer 4 Go pour saturer l'appareil.
  final int maxPayloadBytes;

  /// Retourne le type de valeur [value], ou `null` s'il est inconnu.
  ///
  /// - [value] : valeur lue sur le fil.
  static ExchangeFrameType? fromValue(int value) {
    for (final type in values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}
