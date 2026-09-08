import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/tag_color.dart';

/// Tag pouvant être associé à un [Content], parmi une liste fermée définie
/// par l'application.
///
/// Il ne s'agit pas d'une saisie libre de l'utilisateur : le catalogue est
/// statique et codé en dur ici, ce qui garantit qu'un contenu reçu d'un pair
/// référence toujours un tag connu et affichable.
enum Tag {
  /// Contenu apportant une information neutre.
  info(0, text: 'Info', color: TagColor.blue),

  /// Contenu signalant une alerte ou un danger.
  alert(1, text: 'Alerte', color: TagColor.red),

  /// Contenu posant une question à la communauté.
  question(2, text: 'Question', color: TagColor.purple),

  /// Contenu révélant une information sensible ou un divulgâchage.
  spoiler(3, text: 'Spoiler', color: TagColor.orange);

  const Tag(this.value, {required this.text, required this.color});

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Libellé affiché du tag.
  final String text;

  /// Couleur sémantique du tag.
  final TagColor color;
}
