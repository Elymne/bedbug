import 'package:bedbug/core/extensions/string_uuid_x.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.config.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.entity.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.mapper.drift.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DriftErrorLogRepository].
final errorLogRepositoryProvider = Provider<ErrorLogRepository>((ref) {
  return DriftErrorLogRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [ErrorLogRepository] stockant le journal dans la table SQLite `error_logs`.
class DriftErrorLogRepository implements ErrorLogRepository {
  /// Crée un [DriftErrorLogRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftErrorLogRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Écrit la trace de l'erreur, puis supprime les plus anciennes au-delà de [maxErrorLogs].
  ///
  /// Les deux écritures se font dans une transaction : le journal ne dépasse jamais son plafond, même un instant. Tout
  /// échec est seulement logué, pour respecter le contrat : cette méthode ne lève jamais.
  ///
  /// - [source] : nom du use case qui a attrapé l'erreur.
  /// - [error] : erreur attrapée.
  /// - [stackTrace] : pile d'appels associée.
  @override
  Future<void> record({required String source, required Object error, required StackTrace stackTrace}) async {
    try {
      final now = DateTime.now();
      final errorLog = ErrorLog(
        id: UuidX.generate(),
        createdAt: now,
        updatedAt: now,
        source: source,
        errorType: '${error.runtimeType}',
        message: '$error',
        stackTrace: '$stackTrace',
      );
      await guardDrift('DriftErrorLogRepository', () async {
        await _database.transaction(() async {
          await _database.into(_database.errorLogs).insert(ErrorLogDriftMapper.toCompanion(errorLog));
          await _keepNewest();
        });
      });
    } catch (recordError, recordStackTrace) {
      AppLogger.error('DriftErrorLogRepository', recordError, recordStackTrace);
    }
  }

  /// Supprime, en une seule requête, les traces qui ne sont pas parmi les [maxErrorLogs] plus récentes.
  ///
  /// À date égale (plusieurs erreurs dans la même milliseconde), l'ordre d'insertion (`rowid`) départage : la dernière
  /// erreur enregistrée est toujours conservée.
  Future<void> _keepNewest() async {
    final table = _database.errorLogs;
    final newestIds = _database.selectOnly(table)
      ..addColumns([table.id])
      ..orderBy([
        OrderingTerm(expression: table.createdAt, mode: OrderingMode.desc),
        OrderingTerm(expression: table.rowId, mode: OrderingMode.desc),
      ])
      ..limit(maxErrorLogs);
    await (_database.delete(table)..where((row) => row.id.isNotInQuery(newestIds))).go();
  }
}
