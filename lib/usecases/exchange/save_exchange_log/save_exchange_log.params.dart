import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_codec/exchange_frame_codec.gateway.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log_outcome.enum.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.usecase.dart';

/// Paramètres du [SaveExchangeLogUsecase] : ce qu'on sait d'une rencontre avec un pair.
class SaveExchangeLogParams extends Params {
  /// Crée des [SaveExchangeLogParams].
  ///
  /// - [startedAt] : début de la rencontre.
  /// - [peerAddress] : adresse Bluetooth du pair à cet instant.
  /// - [outcome] : issue de la rencontre.
  /// - [isInitiator] : `true` si ce téléphone a appelé le pair, `null` si aucune connexion n'a abouti.
  /// - [duration] : durée de l'échange.
  /// - [awaitedFrame] : trame attendue à la fin de l'échange, `null` sans échange.
  /// - [sentBytes] : octets envoyés au pair.
  /// - [receivedBytes] : octets reçus du pair.
  /// - [importedContents] : contenus enregistrés.
  /// - [rejectedContents] : contenus écartés.
  /// - [importedReactions] : réactions enregistrées.
  /// - [rejectedReactions] : réactions écartées.
  /// - [removedContents] : contenus supprimés ensuite pour respecter la limite de stockage.
  const SaveExchangeLogParams({
    required this.startedAt,
    required this.peerAddress,
    required this.outcome,
    this.isInitiator,
    this.duration = Duration.zero,
    this.awaitedFrame,
    this.sentBytes = 0,
    this.receivedBytes = 0,
    this.importedContents = 0,
    this.rejectedContents = 0,
    this.importedReactions = 0,
    this.rejectedReactions = 0,
    this.removedContents = 0,
  });

  /// Début de la rencontre.
  final DateTime startedAt;

  /// Adresse Bluetooth du pair à cet instant.
  final String peerAddress;

  /// Issue de la rencontre.
  final ExchangeLogOutcome outcome;

  /// Indique si ce téléphone a appelé le pair, `null` si aucune connexion n'a abouti.
  final bool? isInitiator;

  /// Durée de l'échange.
  final Duration duration;

  /// Trame du protocole attendue à la fin de l'échange, `null` sans échange.
  final ExchangeFrameType? awaitedFrame;

  /// Octets envoyés au pair.
  final int sentBytes;

  /// Octets reçus du pair.
  final int receivedBytes;

  /// Contenus enregistrés.
  final int importedContents;

  /// Contenus écartés.
  final int rejectedContents;

  /// Réactions enregistrées.
  final int importedReactions;

  /// Réactions écartées.
  final int rejectedReactions;

  /// Contenus supprimés ensuite pour respecter la limite de stockage.
  final int removedContents;
}
