import 'package:bedbug/features/content/domain/object_values/compressed_image.dart';

/// Contrat du service de recompression d'image.
///
/// Isolé derrière une interface pour que le domaine décide des limites
/// (dimension, poids) sans dépendre de l'outil d'encodage utilisé.
abstract class ImageCompressorGateway {
  /// Recompresse l'image située à [sourcePath] pour qu'elle respecte les limites fournies.
  ///
  /// L'image est réduite en conservant ses proportions (jamais rognée ni
  /// agrandie), puis sa qualité est abaissée progressivement jusqu'à passer
  /// sous [maxSizeInBytes]. Si la qualité plancher ne suffit pas, les
  /// dimensions sont réduites davantage.
  ///
  /// - [sourcePath] : chemin absolu de l'image d'origine.
  /// - [maxDimension] : taille maximale du plus grand côté, en pixels.
  /// - [maxSizeInBytes] : poids maximal visé pour le fichier produit.
  Future<CompressedImage> compress(String sourcePath, {required int maxDimension, required int maxSizeInBytes});
}
