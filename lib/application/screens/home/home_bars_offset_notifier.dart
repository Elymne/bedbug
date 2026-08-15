import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Distance maximale (en pixels) sur laquelle la searchbar et la navbar peuvent sortir de l'écran.
///
/// Supérieure à la hauteur des deux barres : chacune se clampe indépendamment
/// à sa propre hauteur lors de l'affichage.
const double _maxBarsHiddenOffset = 200;

/// Provider du [HomeBarsOffsetNotifier].
final homeBarsOffsetNotifierProvider = NotifierProvider<HomeBarsOffsetNotifier, double>(HomeBarsOffsetNotifier.new);

/// Notifier gérant la distance de sortie d'écran de la searchbar et de la navbar au scroll.
///
/// Séparé du `HomeFeedNotifier` : cet état est une animation d'UI pure, mise
/// à jour à très haute fréquence (chaque pixel de scroll), sans rapport avec
/// le chargement des contenus. Le mélanger à l'état métier forcerait un
/// rebuild de toute la page à chaque évènement de scroll.
class HomeBarsOffsetNotifier extends Notifier<double> {
  @override
  double build() {
    return 0;
  }

  /// Répercute le [delta] de scroll sur la sortie d'écran des barres.
  ///
  /// - [delta] : distance de scroll depuis la dernière position. Positif
  ///   (scroll vers le bas) fait sortir les barres, négatif (scroll vers
  ///   le haut) les fait revenir.
  void applyScrollDelta(double delta) {
    state = (state + delta).clamp(0.0, _maxBarsHiddenOffset);
  }
}
