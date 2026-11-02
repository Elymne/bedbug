import 'package:bedbug/resources/exchange/exchange_log.entity.dart';

/// Contrat du journal des échanges.
abstract class ExchangeLogRepository {
  /// Enregistre [entity].
  Future<void> addOne(ExchangeLog entity);

  /// Retourne toutes les traces, de la plus récente à la plus ancienne.
  Future<List<ExchangeLog>> getAllNewestFirst();

  /// Ne garde que les [limit] traces les plus récentes.
  Future<void> keepNewest(int limit);
}
