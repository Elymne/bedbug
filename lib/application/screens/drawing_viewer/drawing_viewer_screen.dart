import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/drawing/app_drawing_image.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Zoom maximal autorisé dans la visionneuse de dessin.
const double _kMaxZoom = 4;

/// Paramètres de la visionneuse de dessin, transmis via `extra` à la navigation.
class DrawingViewerParams {
  /// Crée des [DrawingViewerParams].
  ///
  /// - [drawing] : dessin à afficher.
  /// - [cacheKey] : clé de l'image calculée, la même que sur la page d'origine pour ne pas la recalculer.
  const DrawingViewerParams({required this.drawing, required this.cacheKey});

  /// Dessin à afficher.
  final Drawing drawing;

  /// Clé de l'image calculée.
  final String cacheKey;
}

/// Visionneuse plein écran d'un dessin, zoomable.
///
/// Un dessin peut être en portrait, ou plein de détails trop petits pour la
/// largeur d'un téléphone : n'importe qui peut l'ouvrir en grand et zoomer
/// dedans, comme sur une image.
class DrawingViewerScreen extends ConsumerWidget {
  /// Crée un [DrawingViewerScreen].
  ///
  /// - [params] : dessin à afficher.
  const DrawingViewerScreen({super.key, required this.params});

  /// Dessin à afficher.
  final DrawingViewerParams params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.onLightDeep,
      body: Stack(
        children: [
          InteractiveViewer(
            maxScale: _kMaxZoom,
            child: SizedBox.expand(
              child: Center(
                child: AppDrawingImage(drawing: params.drawing, cacheKey: params.cacheKey),
              ),
            ),
          ),
          SafeArea(
            child: IconButton(
              onPressed: context.pop,
              tooltip: context.loc.close,
              icon: const AppIcon(AppIcons.close, color: AppColors.onDark),
            ),
          ),
        ],
      ),
    );
  }
}
