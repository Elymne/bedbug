import 'package:bedbug/shared/domain/value_object.dart';

/// Offre envoyée à un pair au début d'un échange : la liste des contenus que l'appareil peut lui transmettre.
///
/// L'offre ne transporte que des identifiants et de quoi choisir, jamais les contenus eux-mêmes : c'est le pair
/// qui sélectionne ce qu'il veut recevoir, pour ne jamais télécharger un contenu qu'il possède déjà. Les contenus
/// sont rangés du plus prioritaire au moins prioritaire (`broadcastScore` décroissant) : le pair s'en sert pour
/// favoriser les premiers, sans exclure les autres.
class ExchangeOffer extends ValueObject {
  /// Crée une [ExchangeOffer].
  ///
  /// - [contents] : contenus proposés, du plus prioritaire au moins prioritaire.
  const ExchangeOffer({required this.contents});

  /// Contenus proposés, du plus prioritaire au moins prioritaire.
  final List<OfferedContent> contents;

  @override
  bool operator ==(Object other) {
    if (other is! ExchangeOffer || other.contents.length != contents.length) {
      return false;
    }
    for (var index = 0; index < contents.length; index++) {
      if (other.contents[index] != contents[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hashAll(contents);
  }

  @override
  String toString() {
    return 'ExchangeOffer(${contents.length} contenus)';
  }
}

/// Un contenu proposé dans une [ExchangeOffer].
///
/// Porte, en plus de l'identifiant, un résumé de ses réactions : un pair qui possède déjà le contenu peut ainsi
/// savoir s'il lui manque des réactions récentes, et ne demander que celles-ci.
class OfferedContent extends ValueObject {
  /// Crée un [OfferedContent].
  ///
  /// - [id] : identifiant du contenu.
  /// - [sizeInBytes] : poids annoncé du contenu, pour que le pair respecte son budget. Non fiable.
  /// - [reactionCount] : nombre de réactions connues sur ce contenu.
  /// - [latestReactionAt] : date de la réaction la plus récente, `null` s'il n'y en a aucune.
  const OfferedContent({
    required this.id,
    required this.sizeInBytes,
    required this.reactionCount,
    this.latestReactionAt,
  });

  /// Identifiant du contenu.
  final String id;

  /// Poids annoncé du contenu, en octets. Non fiable : le pair le revérifie à la réception.
  final int sizeInBytes;

  /// Nombre de réactions connues sur ce contenu.
  final int reactionCount;

  /// Date de la réaction la plus récente sur ce contenu, `null` s'il n'en a aucune.
  final DateTime? latestReactionAt;

  @override
  bool operator ==(Object other) {
    return other is OfferedContent &&
        other.id == id &&
        other.sizeInBytes == sizeInBytes &&
        other.reactionCount == reactionCount &&
        other.latestReactionAt == latestReactionAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, sizeInBytes, reactionCount, latestReactionAt);
  }

  @override
  String toString() {
    return 'OfferedContent($id, $sizeInBytes o, $reactionCount réactions)';
  }
}
