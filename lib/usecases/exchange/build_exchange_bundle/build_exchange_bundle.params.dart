import 'dart:typed_data';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/exchange/build_exchange_bundle/build_exchange_bundle.usecase.dart';

/// Paramètres du [BuildExchangeBundleUsecase].
class BuildExchangeBundleParams extends Params {
  /// Crée des [BuildExchangeBundleParams].
  ///
  /// - [requestBytes] : demande reçue du pair, encodée.
  const BuildExchangeBundleParams({required this.requestBytes});

  /// Demande reçue du pair, encodée.
  final Uint8List requestBytes;
}
