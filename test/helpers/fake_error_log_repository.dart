import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';

/// Faux journal des erreurs imprévues, en mémoire, pour les tests qui construisent un use case à la main.
class FakeErrorLogRepository implements ErrorLogRepository {
  /// Sources des erreurs enregistrées, dans l'ordre.
  final List<String> recordedSources = [];

  @override
  Future<void> record({required String source, required Object error, required StackTrace stackTrace}) async {
    recordedSources.add(source);
  }
}
