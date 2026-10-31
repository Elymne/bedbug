import 'dart:typed_data';

import 'package:bedbug/features/exchange/domain/object_values/exchange_frame.dart';

/// Contrat de reconstitution des trames à partir des morceaux d'octets reçus du transport.
///
/// Le transport découpe le flux comme il veut : une trame peut arriver en dizaines de morceaux, et plusieurs trames
/// dans le même. Un décodeur garde donc un état entre deux appels, et ne sert qu'à une seule connexion.
abstract class ExchangeFrameDecoderGateway {
  /// Ajoute [bytes] au flux, et retourne les trames qu'ils complètent, dans l'ordre.
  ///
  /// Lève une `DataException` sur un type inconnu ou une taille annoncée trop grande : le flux n'a alors plus de
  /// sens, et le décodeur ne doit plus être utilisé.
  ///
  /// - [bytes] : morceau reçu du transport.
  List<ExchangeFrame> add(Uint8List bytes);
}
