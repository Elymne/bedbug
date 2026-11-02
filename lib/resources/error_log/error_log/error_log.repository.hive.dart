import 'package:bedbug/core/extensions/string_uuid_x.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.config.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.entity.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.model.hive.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive du journal des erreurs imprévues.
final hiveErrorLogBoxProvider = Provider<Box<ErrorLogHiveModel>>((ref) => Hive.box<ErrorLogHiveModel>(errorLogBoxName));

/// Provider du [HiveErrorLogRepository].
final errorLogRepositoryProvider = Provider<ErrorLogRepository>((ref) {
  return HiveErrorLogRepository(ref.read(hiveErrorLogBoxProvider));
});

/// Implémentation de [ErrorLogRepository] utilisant Hive comme stockage local.
class HiveErrorLogRepository implements ErrorLogRepository {
  /// Crée un [HiveErrorLogRepository].
  ///
  /// - [_box] : box Hive du journal des erreurs.
  HiveErrorLogRepository(this._box);

  final Box<ErrorLogHiveModel> _box;

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
      await _box.put(errorLog.id, ErrorLogHiveModel.fromEntity(errorLog));
      await _keepNewest();
    } catch (recordError, recordStackTrace) {
      AppLogger.error('HiveErrorLogRepository', recordError, recordStackTrace);
    }
  }

  /// Supprime les traces les plus anciennes au-delà de [maxErrorLogs].
  Future<void> _keepNewest() async {
    if (_box.length <= maxErrorLogs) {
      return;
    }
    final models = _box.values.toList();
    models.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    await _box.deleteAll(models.skip(maxErrorLogs).map((model) => model.id));
  }
}
