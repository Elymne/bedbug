import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_log_outcome.dart';
import 'package:bedbug/shared/domain/entity.dart';

/// Trace d'une rencontre avec un pair : échange abouti, interrompu, ou qui n'a jamais commencé.
///
/// Sert à comprendre après coup ce qui s'est passé pendant que le téléphone était en poche. [createdAt] est le début
/// de la rencontre. Le journal reste sur l'appareil et ne voyage jamais.
class ExchangeLog extends Entity {
  /// Crée un [ExchangeLog].
  ///
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
  ExchangeLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
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

  /// Adresse Bluetooth du pair à cet instant.
  ///
  /// Le téléphone la renouvelle régulièrement : elle regroupe les rencontres proches, sans identifier une personne.
  final String peerAddress;

  /// Issue de la rencontre.
  final ExchangeLogOutcome outcome;

  /// Indique si ce téléphone a appelé le pair, `null` si aucune connexion n'a abouti.
  final bool? isInitiator;

  /// Durée de l'échange.
  final Duration duration;

  /// Trame attendue à la fin de l'échange, qui indique où il s'est arrêté. `null` sans échange.
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
