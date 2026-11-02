import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/resources/exchange/exchange_log_outcome.enum.dart';

/// Pair vu par la recherche, mais avec qui aucune connexion n'a abouti.
class PeerAttempt extends ValueObject {
  /// Crée un [PeerAttempt].
  ///
  /// - [peerAddress] : adresse Bluetooth du pair.
  /// - [outcome] : raison pour laquelle l'échange n'a pas eu lieu.
  const PeerAttempt({required this.peerAddress, required this.outcome});

  /// Adresse Bluetooth du pair.
  final String peerAddress;

  /// Raison pour laquelle l'échange n'a pas eu lieu.
  final ExchangeLogOutcome outcome;

  @override
  bool operator ==(Object other) {
    return other is PeerAttempt && other.peerAddress == peerAddress && other.outcome == outcome;
  }

  @override
  int get hashCode {
    return Object.hash(peerAddress, outcome);
  }
}
