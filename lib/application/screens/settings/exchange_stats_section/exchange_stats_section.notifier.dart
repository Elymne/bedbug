import 'package:bedbug/application/exchange/exchange_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ExchangeStatsSectionNotifier].
final exchangeStatsSectionNotifierProvider = NotifierProvider<ExchangeStatsSectionNotifier, ExchangeStatsSectionState>(
  ExchangeStatsSectionNotifier.new,
);

/// Notifier comptant les échanges depuis le lancement de l'app, pour voir si le transfert fonctionne.
///
/// Rien n'est enregistré : les compteurs repartent de zéro au redémarrage de l'app.
class ExchangeStatsSectionNotifier extends Notifier<ExchangeStatsSectionState> {
  @override
  ExchangeStatsSectionState build() {
    return const ExchangeStatsSectionState(successCount: 0, failureCount: 0, contentCount: 0);
  }

  /// Ajoute le résultat d'une session aux compteurs.
  ///
  /// Les contenus d'une session en échec sont comptés aussi : ils restent acquis.
  ///
  /// - [result] : résultat de la session.
  void addResult(ExchangeSessionResult result) {
    state = ExchangeStatsSectionState(
      successCount: state.successCount + (result.isSuccess ? 1 : 0),
      failureCount: state.failureCount + (result.isSuccess ? 0 : 1),
      contentCount: state.contentCount + (result.report?.importedContents ?? 0),
    );
  }
}

/// Compteurs des échanges depuis le lancement de l'app.
class ExchangeStatsSectionState {
  /// Crée un [ExchangeStatsSectionState].
  ///
  /// - [successCount] : nombre d'échanges réussis.
  /// - [failureCount] : nombre d'échanges échoués.
  /// - [contentCount] : nombre de contenus reçus.
  const ExchangeStatsSectionState({required this.successCount, required this.failureCount, required this.contentCount});

  /// Nombre d'échanges réussis.
  final int successCount;

  /// Nombre d'échanges échoués.
  final int failureCount;

  /// Nombre de contenus reçus.
  final int contentCount;
}
