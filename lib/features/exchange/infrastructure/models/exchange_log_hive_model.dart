import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_log_outcome.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'exchange_log_hive_model.g.dart';

/// DTO Hive représentant un [ExchangeLog] persisté localement.
@HiveType(typeId: HiveTypeIds.exchangeLog)
class ExchangeLogHiveModel extends HiveObject {
  /// Crée un [ExchangeLogHiveModel].
  ExchangeLogHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.peerAddress,
    required this.outcome,
    required this.isInitiator,
    required this.durationInMillis,
    required this.awaitedFrame,
    required this.sentBytes,
    required this.receivedBytes,
    required this.importedContents,
    required this.rejectedContents,
    required this.importedReactions,
    required this.rejectedReactions,
    required this.removedContents,
  });

  /// Crée un [ExchangeLogHiveModel] depuis une entité [ExchangeLog].
  factory ExchangeLogHiveModel.fromEntity(ExchangeLog entity) {
    return ExchangeLogHiveModel(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      peerAddress: entity.peerAddress,
      outcome: entity.outcome.value,
      isInitiator: entity.isInitiator,
      durationInMillis: entity.duration.inMilliseconds,
      awaitedFrame: entity.awaitedFrame?.value,
      sentBytes: entity.sentBytes,
      receivedBytes: entity.receivedBytes,
      importedContents: entity.importedContents,
      rejectedContents: entity.rejectedContents,
      importedReactions: entity.importedReactions,
      rejectedReactions: entity.rejectedReactions,
      removedContents: entity.removedContents,
    );
  }

  /// Identifiant unique de la trace.
  @HiveField(0)
  final String id;

  /// Début de la rencontre.
  @HiveField(1)
  final DateTime createdAt;

  /// Date de dernière mise à jour.
  @HiveField(2)
  final DateTime updatedAt;

  /// Adresse Bluetooth du pair à cet instant.
  @HiveField(3)
  final String peerAddress;

  /// Issue de la rencontre, encodée comme valeur de [ExchangeLogOutcome].
  @HiveField(4)
  final int outcome;

  /// Indique si ce téléphone a appelé le pair, `null` si aucune connexion n'a abouti.
  @HiveField(5)
  final bool? isInitiator;

  /// Durée de l'échange, en millisecondes.
  @HiveField(6)
  final int durationInMillis;

  /// Trame attendue à la fin de l'échange, encodée comme valeur de [ExchangeFrameType].
  @HiveField(7)
  final int? awaitedFrame;

  /// Octets envoyés au pair.
  @HiveField(8)
  final int sentBytes;

  /// Octets reçus du pair.
  @HiveField(9)
  final int receivedBytes;

  /// Contenus enregistrés.
  @HiveField(10)
  final int importedContents;

  /// Contenus écartés.
  @HiveField(11)
  final int rejectedContents;

  /// Réactions enregistrées.
  @HiveField(12)
  final int importedReactions;

  /// Réactions écartées.
  @HiveField(13)
  final int rejectedReactions;

  /// Contenus supprimés ensuite pour respecter la limite de stockage.
  @HiveField(14)
  final int removedContents;

  /// Convertit ce modèle en entité [ExchangeLog].
  ///
  /// Lève une [DataException] si l'issue enregistrée n'existe plus.
  ExchangeLog toEntity() {
    try {
      final frame = awaitedFrame;
      return ExchangeLog(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        peerAddress: peerAddress,
        outcome: ExchangeLogOutcome.values.firstWhere((candidate) => candidate.value == outcome),
        isInitiator: isInitiator,
        duration: Duration(milliseconds: durationInMillis),
        awaitedFrame: frame == null ? null : ExchangeFrameType.fromValue(frame),
        sentBytes: sentBytes,
        receivedBytes: receivedBytes,
        importedContents: importedContents,
        rejectedContents: rejectedContents,
        importedReactions: importedReactions,
        rejectedReactions: rejectedReactions,
        removedContents: removedContents,
      );
    } on StateError catch (error) {
      throw DataException('ExchangeLogHiveModel', error);
    }
  }
}
