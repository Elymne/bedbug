import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/enums/text_font.dart';
import 'package:bedbug/shared/domain/entity.dart';

/// Longueur maximale, en caractères, de la bulle de texte d'une [Reaction].
///
/// Une bulle reste une réaction (« trop bien », une courte remarque), pas un
/// commentaire : 250 caractères laissent la place d'une phrase tout en gardant
/// une réaction sous ~1 Ko, ce qui compte pour un transfert de pair à pair.
const int maxReactionBubbleLength = 250;

/// Nombre maximal de réactions conservées par contenu.
///
/// Sans identité vérifiable, rien n'empêche un pair de fabriquer des milliers
/// de réactions sous des auteurs inventés : on ne peut que borner leur
/// nombre. Au-delà, les plus anciennes sont écartées, ce qui plafonne le
/// poids des réactions d'un contenu à ~200 Ko.
const int maxReactionsPerContent = 200;

/// Réaction laissée sur un [Content] : un bedbug animé d'un effet ghost (couleur et intensité choisies),
/// accompagné d'une petite bulle de texte.
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
  /// - [bubbleText] : bulle de texte, non vide et au plus [maxReactionBubbleLength] caractères.
  /// - [colorArgb] : couleur de l'effet ghost du bedbug, `null` pour la couleur par défaut de l'app.
  /// - [ghostSpeed] : intensité de l'effet ghost, entre [minGhostSpeed] et [maxGhostSpeed].
  /// - [bubbleFont] : police de la bulle de texte (défaut [TextFont.standard]).
  Reaction({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.contentId,
    required this.authorId,
    required this.avatarText,
    required this.bubbleText,
    this.colorArgb,
    this.ghostSpeed = defaultGhostSpeed,
    this.bubbleFont = TextFont.standard,
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

  /// Bulle de texte affichée au-dessus du bedbug.
  ///
  /// Obligatoire : une réaction est un bedbug qui dit quelque chose. Seules
  /// des réactions stockées avant cette règle peuvent l'avoir vide.
  final String bubbleText;

  /// Couleur de l'effet ghost du bedbug, encodée en ARGB 32 bits. `null` pour la couleur par défaut de l'app.
  ///
  /// Choisie à chaque réaction, indépendamment de la signature : un même
  /// auteur peut réagir en rouge colère ou en bleu tristesse.
  final int? colorArgb;

  /// Intensité de l'effet ghost du bedbug (multiplicateur de la vitesse normale).
  final double ghostSpeed;

  /// Police de la bulle de texte.
  ///
  /// Choisie à chaque réaction, comme la couleur : un « NOOON » ne s'écrit
  /// pas dans la même police qu'un « trop mignon ».
  final TextFont bubbleFont;
}
