import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.entity.dart';

/// Conversion entre un [ErrorLog] et sa ligne de la table `error_logs`.
abstract final class ErrorLogDriftMapper {
  /// Reconstruit la trace d'une ligne.
  ///
  /// Lève une [DataException] si la ligne ne peut pas être convertie.
  ///
  /// [row] : ligne lue dans la table `error_logs`.
  static ErrorLog toEntity(ErrorLogRow row) {
    try {
      return ErrorLog(
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        source: row.source,
        errorType: row.errorType,
        message: row.message,
        stackTrace: row.stackTrace,
      );
    } catch (error) {
      throw DataException('ErrorLogDriftMapper', error);
    }
  }

  /// Construit la ligne à écrire pour une trace.
  ///
  /// [entity] : trace à écrire.
  static ErrorLogsCompanion toCompanion(ErrorLog entity) {
    return ErrorLogsCompanion.insert(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      source: entity.source,
      errorType: entity.errorType,
      message: entity.message,
      stackTrace: entity.stackTrace,
    );
  }
}
