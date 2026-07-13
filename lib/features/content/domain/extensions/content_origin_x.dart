import 'package:bedbug/features/content/domain/enums/content_origin.dart';

/// Extensions de [ContentOrigin] liées au calcul du score de survie.
///
/// Toutes les provenances ne doivent pas perdre en valeur perçue au même
/// rythme : un contenu favori mérite de résister bien plus longtemps qu'un
/// contenu public glané en passant. Centraliser ces demi-vies ici évite de
/// disperser ces règles métier dans chaque use case qui en a besoin.
extension ContentOriginX on ContentOrigin {
  /// Demi-vie en jours utilisée par la décroissance exponentielle du
  /// `survivalScore`. Plus la valeur est grande, plus le contenu résiste
  /// longtemps à la suppression automatique.
  ///
  /// Sans effet pour [ContentOrigin.owned], dont le score reste fixe à `1.0`.
  double get survivalHalfLifeDays {
    switch (this) {
      case ContentOrigin.owned:
        return double.infinity;
      case ContentOrigin.favorited:
        return 90;
      case ContentOrigin.subscribed:
        return 21;
      case ContentOrigin.public:
        return 7;
    }
  }
}
