import 'dart:ui' as ui;

import 'package:bedbug/application/providers/drawing_rasterizer_provider.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider de l'image d'un dessin, calculée une fois par [DrawingImageRequest.key].
///
/// Le fil repasse sans cesse sur les mêmes dessins : leur image est gardée
/// tant qu'un widget l'affiche, plutôt que de rejouer toutes leurs
/// opérations à chaque défilement.
final drawingImageProvider = FutureProvider.autoDispose.family<ui.Image, DrawingImageRequest>((ref, request) {
  return ref.read(drawingRasterizerProvider).render(request.drawing);
});

/// Demande d'image d'un dessin, identifiée par sa seule [key].
///
/// Comparer deux dessins revient à comparer toutes leurs opérations : la
/// clé (l'identifiant du contenu, par exemple) le fait en un instant.
class DrawingImageRequest {
  /// Crée une [DrawingImageRequest].
  ///
  /// - [key] : clé qui identifie ce dessin, à changer dès que le dessin change.
  /// - [drawing] : dessin à afficher.
  const DrawingImageRequest({required this.key, required this.drawing});

  /// Clé qui identifie ce dessin.
  final String key;

  /// Dessin à afficher.
  final Drawing drawing;

  @override
  bool operator ==(Object other) {
    return other is DrawingImageRequest && other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}
