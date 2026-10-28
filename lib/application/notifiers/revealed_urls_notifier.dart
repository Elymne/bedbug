import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [RevealedUrlsNotifier].
final revealedUrlsNotifierProvider = NotifierProvider<RevealedUrlsNotifier, Set<String>>(RevealedUrlsNotifier.new);

/// Notifier retenant les médias que l'utilisateur a choisi d'afficher malgré la greylist ou un domaine inconnu.
///
/// Un média flouté ne se dévoile qu'après confirmation : retenir ce choix
/// le temps de la session évite de redemander à chaque passage dans le fil
/// ou sur la page de détail. Il n'est pas persisté : à la prochaine
/// ouverture de l'app, la prudence reprend le dessus.
class RevealedUrlsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return const {};
  }

  /// Retient que l'utilisateur a choisi d'afficher le média [url].
  ///
  /// - [url] : adresse du média, telle que reçue.
  void reveal(String url) {
    state = {...state, url};
  }
}
