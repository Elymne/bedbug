import 'package:bedbug/shared/domain/value_object.dart';

/// Bilan de l'import d'un lot reçu d'un pair.
///
/// Sert au journal de l'échange et, plus tard, à décider s'il faut rafraîchir le fil d'accueil.
class ExchangeImportReport extends ValueObject {
  /// Crée un [ExchangeImportReport].
  ///
  /// - [importedContents] : nombre de contenus enregistrés.
  /// - [rejectedContents] : nombre de contenus écartés (non demandés, déjà possédés, invalides ou trop lourds).
  /// - [importedReactions] : nombre de réactions enregistrées ou mises à jour.
  /// - [rejectedReactions] : nombre de réactions écartées.
  const ExchangeImportReport({
    required this.importedContents,
    required this.rejectedContents,
    required this.importedReactions,
    required this.rejectedReactions,
  });

  /// Nombre de contenus enregistrés.
  final int importedContents;

  /// Nombre de contenus écartés.
  final int rejectedContents;

  /// Nombre de réactions enregistrées ou mises à jour.
  final int importedReactions;

  /// Nombre de réactions écartées.
  final int rejectedReactions;

  @override
  bool operator ==(Object other) {
    return other is ExchangeImportReport &&
        other.importedContents == importedContents &&
        other.rejectedContents == rejectedContents &&
        other.importedReactions == importedReactions &&
        other.rejectedReactions == rejectedReactions;
  }

  @override
  int get hashCode {
    return Object.hash(importedContents, rejectedContents, importedReactions, rejectedReactions);
  }

  @override
  String toString() {
    return 'ExchangeImportReport(contenus +$importedContents/-$rejectedContents, '
        'réactions +$importedReactions/-$rejectedReactions)';
  }
}
