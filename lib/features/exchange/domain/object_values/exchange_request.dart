import 'package:bedbug/shared/domain/value_object.dart';

/// Demande envoyée en réponse à une offre : ce que l'appareil veut recevoir du pair.
///
/// Le pair qui reçoit l'offre choisit lui-même, au hasard, parmi ce qu'il ne possède pas encore : celui qui
/// propose ne décide donc pas seul de ce qui circule. La demande sert aussi, à la réception, de liste blanche :
/// tout ce qui arrive sans avoir été demandé est ignoré.
class ExchangeRequest extends ValueObject {
  /// Crée une [ExchangeRequest].
  ///
  /// - [contentIds] : contenus demandés, à recevoir avec leurs réactions et la signature de leur auteur.
  /// - [reactionContentIds] : contenus déjà possédés dont on ne demande que les réactions, plus récentes chez le pair.
  const ExchangeRequest({required this.contentIds, required this.reactionContentIds});

  /// Contenus demandés, à recevoir avec leurs réactions et la signature de leur auteur.
  final List<String> contentIds;

  /// Contenus déjà possédés dont on ne demande que les réactions.
  final List<String> reactionContentIds;

  /// Indique si la demande ne porte sur rien : l'échange peut alors s'arrêter là.
  bool get isEmpty {
    return contentIds.isEmpty && reactionContentIds.isEmpty;
  }

  @override
  bool operator ==(Object other) {
    return other is ExchangeRequest &&
        _isSameList(other.contentIds, contentIds) &&
        _isSameList(other.reactionContentIds, reactionContentIds);
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(contentIds), Object.hashAll(reactionContentIds));
  }

  @override
  String toString() {
    return 'ExchangeRequest(${contentIds.length} contenus, ${reactionContentIds.length} réactions)';
  }

  /// Indique si [left] et [right] contiennent les mêmes identifiants, dans le même ordre.
  ///
  /// - [left] : première liste.
  /// - [right] : seconde liste.
  bool _isSameList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
