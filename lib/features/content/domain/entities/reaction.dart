import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/shared/domain/entity.dart';

/// Longueur maximale, en caractères, de la bulle de texte d'une [Reaction].
///
/// Une bulle est une interjection (« trop bien », « mdr »), pas un
/// commentaire : 40 caractères tiennent sur une ligne et gardent une réaction
/// sous ~400 octets, ce qui compte pour un transfert de pair à pair.
const int maxReactionBubbleLength = 40;

/// Nombre maximal de réactions conservées par contenu.
///
/// Sans identité vérifiable, rien n'empêche un pair de fabriquer des milliers
/// de réactions sous des auteurs inventés : on ne peut que borner leur
/// nombre. Au-delà, les plus anciennes sont écartées, ce qui plafonne le
/// poids des réactions d'un contenu à ~80 Ko.
const int maxReactionsPerContent = 200;

/// Réaction laissée sur un [Content] : un bedbug animé d'un effet ghost (couleur et intensité choisies),
/// accompagné d'une petite bulle de texte optionnelle.
///
/// Entité à part du contenu : une réaction voyage seule entre pairs, sans
/// obliger à renvoyer le contenu (et ses images) à chaque nouvelle réaction.
/// Une signature n'a qu'une réaction par contenu : en reposter une la
/// remplace, et entre deux versions, la plus récente ([updatedAt]) gagne.
class Reaction extends Entity {
  /// Crée une [Reaction].
  ///
  /// - [contentId] : identifiant du contenu auquel la réaction est rattachée.
  /// - [authorId] : identifiant de la signature qui a réagi.
  /// - [avatarText] : bedbug choisi, issu du catalogue des signatures.
  /// - [bubbleText] : bulle de texte optionnelle, au plus [maxReactionBubbleLength] caractères.
  /// - [colorArgb] : couleur de l'effet ghost du bedbug, `null` pour la couleur par défaut de l'app.
  /// - [ghostSpeed] : intensité de l'effet ghost, entre [minGhostSpeed] et [maxGhostSpeed].
  Reaction({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.contentId,
    required this.authorId,
    required this.avatarText,
    this.bubbleText,
    this.colorArgb,
    this.ghostSpeed = defaultGhostSpeed,
  });

  /// Identifiant du [Content] auquel cette réaction est rattachée.
  final String contentId;

  /// Identifiant de la signature qui a réagi.
  final String authorId;

  /// Bedbug choisi, sous forme de texte (kaomoji).
  ///
  /// Stocké tel quel plutôt que sous forme d'index dans le catalogue : il
  /// reste lisible par un pair dont le catalogue est d'une autre version.
  final String avatarText;

  /// Bulle de texte optionnelle affichée au-dessus du bedbug.
  final String? bubbleText;

  /// Couleur de l'effet ghost du bedbug, encodée en ARGB 32 bits. `null` pour la couleur par défaut de l'app.
  ///
  /// Choisie à chaque réaction, indépendamment de la signature : un même
  /// auteur peut réagir en rouge colère ou en bleu tristesse.
  final int? colorArgb;

  /// Intensité de l'effet ghost du bedbug (multiplicateur de la vitesse normale).
  final double ghostSpeed;
}
