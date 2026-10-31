import 'dart:typed_data';

import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/shared/domain/value_object.dart';

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
