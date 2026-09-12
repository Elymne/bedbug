import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/image_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';

/// Regroupe l'accès au titre des différents sous-types de [Content].
///
/// Le titre n'existe pas sur [Content] lui-même (certains sous-types futurs
/// pourraient ne pas en avoir), mais tous les sous-types actuels
/// ([TextContent], [LinkContent], [ImageContent]) en portent un. Cette
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
    if (this is ImageContent) {
      return (this as ImageContent).title;
    }
    throw UnsupportedError('Sous-type de Content non géré par ContentTitleExtension: $runtimeType');
  }
}
