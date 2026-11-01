import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';
import 'package:bedbug/features/exchange/domain/repositories/exchange_log_repository.dart';
import 'package:bedbug/features/exchange/infrastructure/models/exchange_log_hive_model.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Nom de la box Hive du journal des échanges.
const String exchangeLogBoxName = 'exchange_logs';

/// Provider de la [Box] Hive du journal des échanges.
final hiveExchangeLogBoxProvider = Provider<Box<ExchangeLogHiveModel>>((ref) {
  return Hive.box<ExchangeLogHiveModel>(exchangeLogBoxName);
});

/// Provider du [HiveExchangeLogRepository].
final exchangeLogRepositoryProvider = Provider<ExchangeLogRepository>((ref) {
  return HiveExchangeLogRepository(ref.read(hiveExchangeLogBoxProvider));
});

/// Implémentation de [ExchangeLogRepository] utilisant Hive comme stockage local.
class HiveExchangeLogRepository implements ExchangeLogRepository {
  /// Crée un [HiveExchangeLogRepository].
  HiveExchangeLogRepository(this._box);

  final Box<ExchangeLogHiveModel> _box;

  @override
  Future<void> addOne(ExchangeLog entity) async {
    try {
      await _box.put(entity.id, ExchangeLogHiveModel.fromEntity(entity));
    } on HiveError catch (error) {
      throw DatasourceException('HiveExchangeLogRepository', error);
    }
  }

  @override
  Future<List<ExchangeLog>> getAllNewestFirst() async {
    try {
      final logs = _box.values.map((model) => model.toEntity()).toList();
      logs.sort((first, second) => second.createdAt.compareTo(first.createdAt));
      return logs;
    } on HiveError catch (error) {
      throw DatasourceException('HiveExchangeLogRepository', error);
    }
  }

  @override
  Future<void> keepNewest(int limit) async {
    try {
      if (_box.length <= limit) {
        return;
      }
      final models = _box.values.toList();
      models.sort((first, second) => second.createdAt.compareTo(first.createdAt));
      await _box.deleteAll(models.skip(limit).map((model) => model.id));
    } on HiveError catch (error) {
      throw DatasourceException('HiveExchangeLogRepository', error);
    }
  }
}
