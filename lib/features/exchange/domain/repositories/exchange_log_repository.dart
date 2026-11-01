import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';

/// Contrat du journal des échanges.
abstract class ExchangeLogRepository {
  /// Enregistre [entity].
  Future<void> addOne(ExchangeLog entity);

  /// Retourne toutes les traces, de la plus récente à la plus ancienne.
  Future<List<ExchangeLog>> getAllNewestFirst();

  /// Ne garde que les [limit] traces les plus récentes.
  Future<void> keepNewest(int limit);
}
