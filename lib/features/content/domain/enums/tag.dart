import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/enums/tag_color.dart';

/// Tag pouvant être associé à un [Content], parmi une liste fermée définie
/// par l'application.
///
/// Il ne s'agit pas d'une saisie libre de l'utilisateur : le catalogue est
/// statique et codé en dur ici, ce qui garantit qu'un contenu reçu d'un pair
/// référence toujours un tag connu et affichable.
///
/// Pour ajouter un tag, déclarer une valeur avec le prochain entier libre : la
/// valeur part en base et aux pairs, elle ne doit jamais changer ni être
/// réutilisée. L'ordre de déclaration est celui du sélecteur.
enum Tag {
  /// Contenu apportant une information neutre.
  info(0, text: 'Info', colors: [TagColor.blue]),

  /// Contenu signalant une alerte ou un danger.
  alert(1, text: 'Alerte', colors: [TagColor.red]),

  /// Contenu posant une question à la communauté.
  question(2, text: 'Question', colors: [TagColor.purple]),

  /// Contenu révélant une information sensible ou un divulgâchage.
  spoiler(3, text: 'Spoiler', colors: [TagColor.orange]),

  /// Contenu parlant de l'actualité.
  news(4, text: 'Actu', colors: [TagColor.neutral]),

  /// Contenu parlant de politique.
  politics(5, text: 'Politique', colors: [TagColor.neutral]),

  /// Contenu parlant de technologie.
  tech(6, text: 'Tech', colors: [TagColor.neutral]),

  /// Contenu parlant de science.
  science(7, text: 'Science', colors: [TagColor.neutral]),

  /// Contenu parlant de jeux vidéo.
  gaming(8, text: 'Jeux vidéo', colors: [TagColor.neutral]),

  /// Contenu parlant de musique.
  music(9, text: 'Musique', colors: [TagColor.neutral]),

  /// Contenu parlant de cinéma.
  movies(10, text: 'Cinéma', colors: [TagColor.neutral]),

  /// Contenu parlant de sport.
  sport(11, text: 'Sport', colors: [TagColor.neutral]),

  /// Contenu humoristique.
  humor(12, text: 'Humour', colors: [TagColor.neutral]),

  /// Contenu parlant d'art.
  art(13, text: 'Art', colors: [TagColor.neutral]),

  /// Contenu parlant de cuisine.
  food(14, text: 'Cuisine', colors: [TagColor.neutral]),

  /// Contenu parlant de voyage.
  travel(15, text: 'Voyage', colors: [TagColor.neutral]);

  const Tag(this.value, {required this.text, required this.colors});

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Libellé affiché du tag.
  final String text;

  /// Couleur sémantique du tag, ou couleurs de son dégradé, de gauche à droite. Au moins une.
  final List<TagColor> colors;
}
