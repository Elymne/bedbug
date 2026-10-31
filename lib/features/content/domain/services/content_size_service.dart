import 'dart:convert';

import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/drawing_content.dart';
import 'package:bedbug/features/content/domain/entities/link_content.dart';
import 'package:bedbug/features/content/domain/entities/media_content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ContentSizeService].
final contentSizeServiceProvider = Provider<ContentSizeService>((ref) => const ContentSizeService());

/// Détermine le poids réel d'un contenu.
///
/// Le poids (`sizeInBytes`) porté par un contenu n'est pas fiable : un contenu reçu d'un pair pourrait mentir sur sa
/// taille pour échapper aux limites de stockage. Tout enregistrement recalcule donc le poids avec ce service.
class ContentSizeService extends Service {
  /// Crée un [ContentSizeService].
  const ContentSizeService();

  /// Retourne le poids réel de [content], selon son type concret.
  ///
  /// Somme des octets UTF-8 de ses champs texte, calculable directement depuis les données du domaine. Un
  /// [MediaContent] ne stocke que les adresses de ses médias, jamais les fichiers : son poids est celui de ces
  /// adresses. Un [DrawingContent] pèse son titre et ses opérations.
  ///
  /// - [content] : contenu à peser.
  int sizeInBytes(Content content) {
    if (content is TextContent) {
      return utf8.encode(content.title).length + utf8.encode(content.body).length;
    }

    if (content is LinkContent) {
      final fields = [
        content.title,
        content.url,
        content.body,
        content.ogTitle,
        content.ogDescription,
        content.ogImageUrl,
      ];
      return fields.whereType<String>().fold<int>(0, (total, field) => total + utf8.encode(field).length);
    }

    if (content is MediaContent) {
      final fields = [content.title, content.body, for (final media in content.media) media.url];
      return fields.whereType<String>().fold<int>(0, (total, field) => total + utf8.encode(field).length);
    }

    if (content is DrawingContent) {
      return utf8.encode(content.title).length + _drawingSizeInBytes(content.drawing);
    }

    return content.sizeInBytes;
  }

  /// Retourne le poids maximal de [drawing] une fois stocké.
  ///
  /// Une borne haute plutôt que le poids exact de son encodage, qui dépend du stockage : 4 octets par couleur, 12 par
  /// opération et 4 par point.
  ///
  /// - [drawing] : dessin à peser.
  int _drawingSizeInBytes(Drawing drawing) {
    var total = drawing.palette.length * 4;
    for (final operation in drawing.operations) {
      total += 12;
      if (operation is DrawingStroke) {
        total += operation.points.length * 4;
      }
    }
    return total;
  }
}
