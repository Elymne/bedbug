import 'package:bedbug/core/domain/entity.dart';
import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/reaction/reaction.config.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/text_font.enum.dart';

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
  /// - [avatarFrames] : frames du bedbug choisi.
  /// - [bubbleText] : bulle de texte, non vide et au plus [maxReactionBubbleLength] caractères.
  /// - [colorArgb] : couleur de l'effet ghost du bedbug, `null` pour la couleur par défaut de l'app.
  /// - [ghostSpeed] : intensité de l'effet ghost, entre [minGhostSpeed] et [maxGhostSpeed].
  /// - [avatarFrameSpeed] : vitesse de l'animation du bedbug, entre [minAvatarFrameSpeed] et [maxAvatarFrameSpeed].
  /// - [bubbleFont] : police de la bulle de texte (défaut [TextFont.standard]).
  Reaction({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.contentId,
    required this.authorId,
    required this.avatarFrames,
    required this.bubbleText,
    this.colorArgb,
    this.ghostSpeed = defaultGhostSpeed,
    this.avatarFrameSpeed = defaultAvatarFrameSpeed,
    this.bubbleFont = TextFont.standard,
  });

  /// Identifiant du [Content] auquel cette réaction est rattachée.
  final String contentId;

  /// Identifiant de la signature qui a réagi.
  final String authorId;

  /// Frames du bedbug choisi, sous forme de texte (kaomoji), affichées tour à tour. Une seule frame : il reste fixe.
  ///
  /// Stockées telles quelles plutôt que sous forme d'index dans le catalogue :
  /// le bedbug reste lisible, et animé, chez un pair dont le catalogue est
  /// d'une autre version.
  final List<String> avatarFrames;

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

  /// Vitesse de l'animation du bedbug, entre [minAvatarFrameSpeed] et [maxAvatarFrameSpeed].
  ///
  /// Multiplicateur de la vitesse normale à laquelle les frames défilent (1 = vitesse normale). Sans effet sur un
  /// bedbug d'une seule frame.
  final double avatarFrameSpeed;

  /// Police de la bulle de texte.
  ///
  /// Choisie à chaque réaction, comme la couleur : un « NOOON » ne s'écrit
  /// pas dans la même police qu'un « trop mignon ».
  final TextFont bubbleFont;

  /// Indique si [bubbleText] est une bulle valide : non vide, une seule ligne, au plus [maxReactionBubbleLength]
  /// caractères.
  ///
  /// La règle vaut partout : à la saisie (formulaire), à l'enregistrement (use case), et à la réception d'une réaction
  /// d'un pair, qui ne passe par aucun formulaire. La longueur est comptée en caractères Unicode (runes) et non en
  /// unités UTF-16, pour qu'un emoji ne compte pas double.
  ///
  /// - [bubbleText] : texte à vérifier.
  static bool isValidBubble(String bubbleText) {
    return bubbleText.trim().isNotEmpty &&
        bubbleText.runes.length <= maxReactionBubbleLength &&
        !bubbleText.contains('\n');
  }
}
