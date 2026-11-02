import 'package:bedbug/resources/content/content.entity.dart';
import 'package:bedbug/resources/content/drawing_content.entity.dart';
import 'package:bedbug/resources/content/link_content.entity.dart';
import 'package:bedbug/resources/content/media_content.entity.dart';
import 'package:bedbug/resources/content/text_content.entity.dart';

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
