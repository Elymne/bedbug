import 'package:bedbug/resources/content/content/content.entity.dart';
import 'package:bedbug/resources/content/content/drawing_content.entity.dart';
import 'package:bedbug/resources/content/content/link_content.entity.dart';
import 'package:bedbug/resources/content/content/media_content.entity.dart';
import 'package:bedbug/resources/content/content/text_content.entity.dart';

/// Regroupe l'accès au titre des différents sous-types de [Content].
///
/// Le titre n'existe pas sur [Content] lui-même (certains sous-types futurs
/// pourraient ne pas en avoir), mais tous les sous-types actuels
/// ([TextContent], [LinkContent], [MediaContent], [DrawingContent]) en portent un. Cette
/// extension centralise leur lecture, notamment pour le filtrage par titre
/// (recherche), sans forcer ce champ sur l'entité de base.
extension ContentTitleExtension on Content {
  /// Retourne le titre de ce contenu.
  String get title {
    if (this is TextContent) {
      return (this as TextContent).title;
    }
    if (this is LinkContent) {
      return (this as LinkContent).title;
    }
    if (this is MediaContent) {
      return (this as MediaContent).title;
    }
    if (this is DrawingContent) {
      return (this as DrawingContent).title;
    }
    throw UnsupportedError('Sous-type de Content non géré par ContentTitleExtension: $runtimeType');
  }
}

/// Adresses externes vers lesquelles pointe un [Content], selon leur usage.
///
/// Un contenu reçu d'un pair peut pointer n'importe où : avant de l'afficher,
/// ses adresses sont confrontées aux listes de domaines de l'utilisateur.
/// Cette extension dit lesquelles, sans que le domaine du contenu ait à
/// connaître ces listes.
extension ContentUrlsExtension on Content {
  /// Adresses des médias qui décident de l'affichage du contenu : celles d'un [MediaContent].
  ///
  /// L'image d'aperçu d'un [LinkContent] n'en fait pas partie : elle n'est
  /// qu'une décoration, simplement omise si son domaine n'est pas accepté.
  List<String> get mediaUrls {
    final content = this;
    if (content is MediaContent) {
      return [for (final media in content.media) media.url];
    }
    return const [];
  }

  /// Adresses des liens du contenu : celle d'un [LinkContent].
  List<String> get linkUrls {
    final content = this;
    if (content is LinkContent) {
      return [content.url];
    }
    return const [];
  }
}

/// Normalisation du flair saisi à la main par l'auteur d'un contenu.
///
/// Le flair est un texte libre : l'utilisateur peut écrire `f/france`,
/// `/france`, `france ` ou `//France`. Sans normalisation, ces variantes
/// seraient stockées et diffusées comme des flairs distincts. Cette extension
/// garantit une forme canonique unique, stockée sans préfixe (`f/` est ajouté
/// à l'affichage).
extension FlairExtension on String {
  /// Retourne le flair normalisé, ou `null` s'il ne reste rien après nettoyage.
  ///
  /// Supprime les espaces en bordure et le préfixe initial (`f/` ou `/`,
  /// éventuellement répétés), puis passe en minuscules pour que `f/France` et
  /// `france` désignent le même flair.
  String? toFlair() {
    final normalized = trim().replaceFirst(RegExp('^(f/|/)+', caseSensitive: false), '').trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
