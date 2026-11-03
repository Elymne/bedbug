import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/signature/signature/social_network.enum.dart';
import 'package:bedbug/resources/signature/signature/text_font.enum.dart';
import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.usecase.dart';

/// Paramètres du [SaveLocalSignatureUsecase].
class SaveLocalSignatureParams extends Params {
  /// Crée des [SaveLocalSignatureParams].
  ///
  /// - [pseudo] : pseudo saisi.
  /// - [avatarText] : icône texte saisie.
  /// - [colorArgb] : couleur de l'effet ghost de l'icône en ARGB 32 bits, `null` pour la couleur par défaut.
  /// - [ghostSpeed] : vitesse de l'effet ghost (ramenée dans ses bornes par le use case).
  /// - [socialLinks] : identifiants saisis par réseau, bruts (normalisés par le use case).
  /// - [bio] : description saisie, `null` ou vide pour ne pas en avoir.
  /// - [bioFont] : police choisie pour la description (défaut [TextFont.standard]).
  const SaveLocalSignatureParams({
    required this.pseudo,
    required this.avatarText,
    required this.colorArgb,
    required this.ghostSpeed,
    required this.socialLinks,
    this.bio,
    this.bioFont = TextFont.standard,
  });

  /// Pseudo saisi.
  final String pseudo;

  /// Icône texte saisie.
  final String avatarText;

  /// Couleur de l'effet ghost de l'icône en ARGB 32 bits, `null` pour la couleur par défaut.
  final int? colorArgb;

  /// Vitesse de l'effet ghost.
  final double ghostSpeed;

  /// Identifiants saisis par réseau, bruts.
  final Map<SocialNetwork, String> socialLinks;

  /// Description saisie, `null` ou vide pour ne pas en avoir.
  final String? bio;

  /// Police choisie pour la description.
  final TextFont bioFont;
}
