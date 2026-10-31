import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/reaction.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/shared/domain/value_object.dart';

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
class ExchangedContent extends ValueObject {
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
