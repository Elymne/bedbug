import 'dart:typed_data';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/exchange/import_exchange_bundle/import_exchange_bundle.usecase.dart';

/// Paramètres du [ImportExchangeBundleUsecase].
class ImportExchangeBundleParams extends Params {
  /// Crée des [ImportExchangeBundleParams].
  ///
  /// - [requestBytes] : demande envoyée au pair, encodée, qui sert de liste blanche.
  /// - [bundleBytes] : lot reçu du pair, encodé.
  const ImportExchangeBundleParams({required this.requestBytes, required this.bundleBytes});

  /// Demande envoyée au pair, encodée. Seul ce qu'elle contient est accepté.
  final Uint8List requestBytes;

  /// Lot reçu du pair, encodé.
  final Uint8List bundleBytes;
}
