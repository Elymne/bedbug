import 'dart:typed_data';

import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/reaction/reaction.entity.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';

/// Contrat de mise en octets des messages échangés entre deux appareils.
///
/// Le transport (BLE aujourd'hui) ne fait circuler que des octets : ce gateway traduit les objets d'un échange
/// dans le format qui voyage, et inversement. Le format est versionné, pour que deux versions de l'app puissent
/// encore se comprendre ou au moins se reconnaître incompatibles.
///
/// Les décodages ne font confiance à rien : un message mal formé, d'une version inconnue ou trop volumineux une
/// fois décompressé lève une `DataException`.
abstract class ExchangeCodecGateway {
  /// Retourne [offer] encodée.
  Uint8List encodeOffer(ExchangeOffer offer);

  /// Retourne l'offre décodée depuis [bytes].
  ExchangeOffer decodeOffer(Uint8List bytes);

  /// Retourne [request] encodée.
  Uint8List encodeRequest(ExchangeRequest request);

  /// Retourne la demande décodée depuis [bytes].
  ExchangeRequest decodeRequest(Uint8List bytes);

  /// Retourne [bundle] encodé.
  Uint8List encodeBundle(ExchangeBundle bundle);

  /// Retourne le lot décodé depuis [bytes].
  ExchangeBundle decodeBundle(Uint8List bytes);
}

/// Lot envoyé à un pair en réponse à sa demande : les contenus et réactions qu'il a choisis.
///
/// Ce qui voyage n'est pas une copie de la base locale. Aucun identifiant de signature ne sort du téléphone : chaque
/// contenu emporte la signature complète de son auteur (ou aucune s'il est anonyme), et le téléphone qui le reçoit
/// en déduit lui-même un identifiant local. Les réactions voyagent sans auteur. Les champs propres à l'appareil
/// (provenance, scores, poids) ne voyagent pas non plus : le destinataire les recalcule.
class ExchangeBundle extends ValueObject {
  /// Crée un [ExchangeBundle].
  ///
  /// - [contents] : contenus transmis, chacun avec la signature de son auteur.
  /// - [reactions] : réactions transmises, sur les contenus demandés ou sur ceux dont seules les réactions l'étaient.
  const ExchangeBundle({required this.contents, required this.reactions});

  /// Contenus transmis, chacun avec la signature de son auteur.
  final List<ExchangedContent> contents;

  /// Réactions transmises. Leur `authorId` n'est pas transmis et n'a pas de sens à la réception.
  final List<Reaction> reactions;

  @override
  bool operator ==(Object other) {
    if (other is! ExchangeBundle ||
        other.contents.length != contents.length ||
        other.reactions.length != reactions.length) {
      return false;
    }
    for (var index = 0; index < contents.length; index++) {
      if (other.contents[index] != contents[index]) {
        return false;
      }
    }
    for (var index = 0; index < reactions.length; index++) {
      if (other.reactions[index].id != reactions[index].id) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(contents), Object.hashAll(reactions.map((reaction) => reaction.id)));
  }

  @override
  String toString() {
    return 'ExchangeBundle(${contents.length} contenus, ${reactions.length} réactions)';
  }
}

/// Un contenu d'un [ExchangeBundle], accompagné de la signature de son auteur.
class ExchangedContent {
  /// Crée un [ExchangedContent].
  ///
  /// - [content] : contenu transmis. Seuls ses champs publics ont un sens à la réception.
  /// - [signature] : signature complète de l'auteur, `null` pour un contenu anonyme.
  const ExchangedContent({required this.content, this.signature});

  /// Contenu transmis.
  final Content content;

  /// Signature complète de l'auteur, `null` pour un contenu anonyme. Son `id` n'est pas transmis.
  final Signature? signature;

  @override
  bool operator ==(Object other) {
    return other is ExchangedContent && other.content.id == content.id && other.signature?.id == signature?.id;
  }

  @override
  int get hashCode {
    return Object.hash(content.id, signature?.id);
  }

  @override
  String toString() {
    return 'ExchangedContent(${content.id})';
  }
}

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
class OfferedContent {
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
