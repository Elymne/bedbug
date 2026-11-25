import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log.entity.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log_outcome.enum.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log_step.enum.dart';
import 'package:drift/drift.dart';

/// Conversion entre un [ExchangeLog] et sa ligne de la table `exchange_logs`.
abstract final class ExchangeLogDriftMapper {
  /// Reconstruit la trace d'une ligne.
  ///
  /// Lève une [DataException] si l'issue ou l'étape enregistrée n'existe plus.
  ///
  /// [row] : ligne lue dans la table `exchange_logs`.
  static ExchangeLog toEntity(ExchangeLogRow row) {
    try {
      final step = row.awaitedStep;
      return ExchangeLog(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        peerAddress: row.peerAddress,
        outcome: ExchangeLogOutcome.values.firstWhere((candidate) => candidate.value == row.outcome),
        isInitiator: row.isInitiator,
        duration: Duration(milliseconds: row.durationInMillis),
        awaitedStep: step == null ? null : ExchangeLogStep.values.firstWhere((candidate) => candidate.value == step),
        sentBytes: row.sentBytes,
        receivedBytes: row.receivedBytes,
        importedContents: row.importedContents,
        rejectedContents: row.rejectedContents,
        importedReactions: row.importedReactions,
        rejectedReactions: row.rejectedReactions,
        removedContents: row.removedContents,
      );
    } on StateError catch (error) {
      throw DataException('ExchangeLogDriftMapper', error);
    }
  }

  /// Construit la ligne à écrire pour une trace.
  ///
  /// [entity] : trace à écrire.
  static ExchangeLogsCompanion toCompanion(ExchangeLog entity) {
    return ExchangeLogsCompanion.insert(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      peerAddress: entity.peerAddress,
      outcome: entity.outcome.value,
      isInitiator: Value(entity.isInitiator),
      durationInMillis: entity.duration.inMilliseconds,
      awaitedStep: Value(entity.awaitedStep?.value),
      sentBytes: entity.sentBytes,
      receivedBytes: entity.receivedBytes,
      importedContents: entity.importedContents,
      rejectedContents: entity.rejectedContents,
      importedReactions: entity.importedReactions,
      rejectedReactions: entity.rejectedReactions,
      removedContents: entity.removedContents,
    );
  }
}
