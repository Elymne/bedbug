import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/drift.guard.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log.entity.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log.mapper.drift.dart';
import 'package:bedbug/infra/resources/exchange/exchange_log/exchange_log.repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [DriftExchangeLogRepository].
final exchangeLogRepositoryProvider = Provider<ExchangeLogRepository>((ref) {
  return DriftExchangeLogRepository(ref.read(appDatabaseProvider));
});

/// Implémentation de [ExchangeLogRepository] stockant le journal dans la table SQLite `exchange_logs`.
class DriftExchangeLogRepository implements ExchangeLogRepository {
  /// Crée un [DriftExchangeLogRepository].
  ///
  /// - [_database] : base SQLite de l'app.
  DriftExchangeLogRepository(this._database);

  /// Base SQLite de l'app.
  final AppDatabase _database;

  /// Écrit [entity], en remplaçant une éventuelle trace de même identifiant.
  ///
  /// - [entity] : trace à enregistrer.
  @override
  Future<void> addOne(ExchangeLog entity) async {
    await guardDrift('DriftExchangeLogRepository', () async {
      await _database.into(_database.exchangeLogs).insertOnConflictUpdate(ExchangeLogDriftMapper.toCompanion(entity));
    });
  }

  /// Lit toutes les traces, triées par SQLite de la plus récente à la plus ancienne.
  ///
  /// À date de début égale, la dernière trace enregistrée (`rowid` le plus grand) passe en premier.
  @override
  Future<List<ExchangeLog>> getAllNewestFirst() async {
    return guardDrift('DriftExchangeLogRepository', () async {
      final query = _database.select(_database.exchangeLogs)
        ..orderBy([
          (row) => OrderingTerm(expression: row.createdAt, mode: OrderingMode.desc),
          (row) => OrderingTerm(expression: row.rowId, mode: OrderingMode.desc),
        ]);
      final rows = await query.get();
      return rows.map(ExchangeLogDriftMapper.toEntity).toList();
    });
  }

  /// Supprime, en une seule requête, toutes les traces qui ne sont pas parmi les [limit] plus récentes.
  ///
  /// Même ordre que [getAllNewestFirst] : les traces conservées sont exactement les premières de cette liste.
  ///
  /// - [limit] : nombre de traces à conserver.
  @override
  Future<void> keepNewest(int limit) async {
    await guardDrift('DriftExchangeLogRepository', () async {
      final table = _database.exchangeLogs;
      final newestIds = _database.selectOnly(table)
        ..addColumns([table.id])
        ..orderBy([
          OrderingTerm(expression: table.createdAt, mode: OrderingMode.desc),
          OrderingTerm(expression: table.rowId, mode: OrderingMode.desc),
        ])
        ..limit(limit);
      await (_database.delete(table)..where((row) => row.id.isNotInQuery(newestIds))).go();
    });
  }
}
