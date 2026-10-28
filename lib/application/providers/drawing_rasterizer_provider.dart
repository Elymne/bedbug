import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/features/content/domain/extensions/drawing_dimensions_extension.dart';
import 'package:bedbug/features/content/domain/object_values/drawing.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_operation.dart';
import 'package:bedbug/features/content/domain/object_values/drawing_point.dart';
import 'package:bedbug/features/content/domain/services/flood_fill_service.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// Rapport entre l'image d'un dessin et son repère : un pixel pour deux points.
///
/// Fixe, quel que soit l'écran : un remplissage se calcule sur cette image,
/// et doit donner la même zone sur tous les téléphones. Affichée sans
/// lissage, elle donne aussi aux dessins leur rendu « pixel » assumé.
const double drawingRasterScale = 0.5;

/// Écart maximal entre deux points confiés à `perfect_freehand`, en points du repère.
///
/// `perfect_freehand` lisse un trait en tirant chaque point vers le
/// précédent : prévu pour les points serrés d'un doigt, il couperait les
/// angles d'un trait simplifié, aux points espacés, jusqu'à ouvrir un
/// contour fermé. Les points sont donc resserrés avant.
const double _maxOutlineStep = 6;

/// Diamètre de chaque taille de pinceau, en points du repère.
const List<double> _brushDiameters = [6, 12, 24, 48];

/// Opacité du feutre (sur 255).
const int _markerAlpha = 140;

/// Nombre de points de la bombe projetés autour de chaque point du trait.
const int _sprayDotsPerPoint = 10;

/// Provider du [DrawingRasterizer].
final drawingRasterizerProvider = Provider<DrawingRasterizer>((ref) {
  return DrawingRasterizer(ref.read(floodFillServiceProvider));
});

/// Transforme un dessin (ses opérations) en image affichable.
///
/// Les opérations sont rejouées dans l'ordre, chaque calque sur sa propre
/// image : la gomme n'efface que son calque. Les traits passent par
/// `perfect_freehand`, qui donne la même forme pour les mêmes points sur
/// tous les téléphones ; le grain du crayon et la bombe tirent leur hasard
/// de la graine du trait. Un remplissage se calcule sur l'image de tous les
/// calques déjà dessinés.
class DrawingRasterizer {
  /// Crée un [DrawingRasterizer].
  const DrawingRasterizer(this._floodFillService);

  final FloodFillService _floodFillService;

  /// Retourne l'image de [drawing], calques superposés sur un fond blanc.
  ///
  /// - [drawing] : dessin à afficher, déjà vérifié.
  Future<ui.Image> render(Drawing drawing) async {
    final layers = List<ui.Image?>.filled(drawingLayerCount, null);
    // Traits en attente par calque : ils sont dessinés ensemble, en une seule image, jusqu'au prochain remplissage.
    final pendingStrokes = [for (var layer = 0; layer < drawingLayerCount; layer++) <DrawingStroke>[]];

    /// Dessine les traits en attente de chaque calque.
    void flushStrokes() {
      for (var layer = 0; layer < drawingLayerCount; layer++) {
        if (pendingStrokes[layer].isEmpty) {
          continue;
        }
        layers[layer] = _drawStrokes(layers[layer], pendingStrokes[layer], drawing);
        pendingStrokes[layer].clear();
      }
    }

    for (final operation in drawing.operations) {
      switch (operation) {
        case DrawingStroke():
          pendingStrokes[operation.layer].add(operation);
        case DrawingFill():
          flushStrokes();
          layers[operation.layer] = await _fill(layers, operation, drawing);
      }
    }
    flushStrokes();
    return _compose(layers, drawing);
  }

  /// Retourne la largeur, en pixels, de l'image de [drawing].
  ///
  /// - [drawing] : dessin.
  int rasterWidth(Drawing drawing) {
    return (drawing.width * drawingRasterScale).round();
  }

  /// Retourne la hauteur, en pixels, de l'image de [drawing].
  ///
  /// - [drawing] : dessin.
  int rasterHeight(Drawing drawing) {
    return (drawing.height * drawingRasterScale).round();
  }

  /// Dessine [stroke] sur [canvas], dont le repère est celui du dessin.
  ///
  /// Sert aussi au trait en cours de tracé, dessiné par-dessus l'image du
  /// dessin : la gomme y est alors montrée comme un trait blanc translucide,
  /// faute de calque à effacer.
  ///
  /// - [canvas] : surface de dessin, mise à l'échelle du repère du dessin.
  /// - [stroke] : trait à dessiner.
  /// - [palette] : palette du dessin.
  /// - [isPreview] : `true` pour le trait en cours de tracé.
  void paintStroke(Canvas canvas, DrawingStroke stroke, List<int> palette, {bool isPreview = false}) {
    final color = Color(palette[stroke.colorIndex]);
    final diameter = _brushDiameters[stroke.size];
    switch (stroke.brush) {
      case DrawingBrush.pen:
        canvas.drawPath(_outline(stroke.points, size: diameter, thinning: 0.6), Paint()..color = color);
      case DrawingBrush.marker:
        canvas.drawPath(
          _outline(stroke.points, size: diameter * 1.6, thinning: 0),
          Paint()..color = color.withAlpha(_markerAlpha),
        );
      case DrawingBrush.pencil:
        _paintPencil(canvas, stroke, color, diameter);
      case DrawingBrush.spray:
        _paintSpray(canvas, stroke, color, diameter);
      case DrawingBrush.eraser:
        final outline = _outline(stroke.points, size: diameter * 1.4, thinning: 0);
        if (isPreview) {
          canvas.drawPath(outline, Paint()..color = AppColors.surface.withAlpha(200));
          return;
        }
        canvas.drawPath(outline, Paint()..blendMode = BlendMode.clear);
    }
  }

  /// Retourne [base] avec [strokes] dessinés par-dessus.
  ///
  /// - [base] : image du calque, `null` s'il est encore vide.
  /// - [strokes] : traits à dessiner, dans l'ordre.
  /// - [drawing] : dessin, qui donne la palette et la taille de l'image.
  ui.Image _drawStrokes(ui.Image? base, List<DrawingStroke> strokes, Drawing drawing) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (base != null) {
      canvas.drawImage(base, Offset.zero, Paint());
    }
    canvas.scale(drawingRasterScale);
    for (final stroke in strokes) {
      paintStroke(canvas, stroke, drawing.palette);
    }
    return recorder.endRecording().toImageSync(rasterWidth(drawing), rasterHeight(drawing));
  }

  /// Retourne le calque de [fill] avec la zone de son point de départ remplie.
  ///
  /// La zone est calculée sur l'image de tous les calques superposés : un
  /// contour tracé sur un calque délimite un remplissage posé sur un autre.
  ///
  /// - [layers] : images actuelles des calques.
  /// - [fill] : remplissage à appliquer.
  /// - [drawing] : dessin, qui donne la palette et la taille de l'image.
  Future<ui.Image> _fill(List<ui.Image?> layers, DrawingFill fill, Drawing drawing) async {
    final composite = _compose(layers, drawing);
    final pixels = await composite.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    final base = layers[fill.layer];
    if (pixels == null) {
      return base ?? _blank(drawing);
    }
    final mask = _floodFillService.fillMask(
      pixels.buffer.asUint8List(),
      rasterWidth(drawing),
      rasterHeight(drawing),
      (fill.point.x * drawingRasterScale).floor(),
      (fill.point.y * drawingRasterScale).floor(),
    );
    final fillImage = await _maskImage(mask, Color(drawing.palette[fill.colorIndex]), drawing);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (base != null) {
      canvas.drawImage(base, Offset.zero, Paint());
    }
    canvas.drawImage(fillImage, Offset.zero, Paint());
    return recorder.endRecording().toImageSync(rasterWidth(drawing), rasterHeight(drawing));
  }

  /// Retourne les calques superposés sur un fond blanc.
  ///
  /// - [layers] : images des calques, du fond vers le dessus.
  /// - [drawing] : dessin, dont le repère fixe la taille de l'image.
  ui.Image _compose(List<ui.Image?> layers, Drawing drawing) {
    final width = rasterWidth(drawing);
    final height = rasterHeight(drawing);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color = AppColors.surface);
    for (final layer in layers) {
      if (layer != null) {
        canvas.drawImage(layer, Offset.zero, Paint());
      }
    }
    return recorder.endRecording().toImageSync(width, height);
  }

  /// Retourne une image transparente, à la taille de [drawing].
  ///
  /// - [drawing] : dessin.
  ui.Image _blank(Drawing drawing) {
    return ui.PictureRecorder().endRecording().toImageSync(rasterWidth(drawing), rasterHeight(drawing));
  }

  /// Retourne l'image de [mask], peinte en [color] là où il vaut 255, transparente ailleurs.
  ///
  /// - [mask] : masque d'un remplissage, un octet par pixel.
  /// - [color] : couleur du remplissage.
  /// - [drawing] : dessin, dont le repère fixe la taille de l'image.
  Future<ui.Image> _maskImage(Uint8List mask, Color color, Drawing drawing) {
    final rgba = Uint8List(mask.length * 4);
    final red = (color.r * 255).round();
    final green = (color.g * 255).round();
    final blue = (color.b * 255).round();
    for (var index = 0; index < mask.length; index++) {
      if (mask[index] == 0) {
        continue;
      }
      rgba[index * 4] = red;
      rgba[index * 4 + 1] = green;
      rgba[index * 4 + 2] = blue;
      rgba[index * 4 + 3] = 255;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      rasterWidth(drawing),
      rasterHeight(drawing),
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  /// Retourne le contour d'un trait passant par [points], calculé par `perfect_freehand`.
  ///
  /// - [points] : points du trait.
  /// - [size] : diamètre du trait, en points du repère.
  /// - [thinning] : effet de la vitesse sur l'épaisseur (0 pour une épaisseur constante).
  Path _outline(List<DrawingPoint> points, {required double size, required double thinning}) {
    final outline = getStroke(
      _densify(points),
      options: StrokeOptions(size: size, thinning: thinning, smoothing: 0.5, streamline: 0.5, isComplete: true),
    );
    final path = Path();
    if (outline.isEmpty) {
      return path;
    }
    path.moveTo(outline.first.dx, outline.first.dy);
    for (final offset in outline.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }
    return path..close();
  }

  /// Retourne [points] resserrés : des points intermédiaires sont ajoutés là où deux points sont trop espacés.
  ///
  /// - [points] : points du trait.
  List<PointVector> _densify(List<DrawingPoint> points) {
    final dense = <PointVector>[];
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      if (index > 0) {
        final previous = points[index - 1];
        final distance = sqrt(pow(point.x - previous.x, 2) + pow(point.y - previous.y, 2));
        final steps = (distance / _maxOutlineStep).ceil();
        for (var step = 1; step < steps; step++) {
          final ratio = step / steps;
          dense.add(
            PointVector(previous.x + (point.x - previous.x) * ratio, previous.y + (point.y - previous.y) * ratio),
          );
        }
      }
      dense.add(PointVector(point.x.toDouble(), point.y.toDouble()));
    }
    return dense;
  }

  /// Dessine un trait de crayon : un trait fin, troué de petits points pour imiter le grain du papier.
  ///
  /// - [canvas] : surface de dessin.
  /// - [stroke] : trait à dessiner.
  /// - [color] : couleur du trait.
  /// - [diameter] : diamètre du pinceau, en points du repère.
  void _paintPencil(Canvas canvas, DrawingStroke stroke, Color color, double diameter) {
    final path = _outline(stroke.points, size: diameter * 0.7, thinning: 0.2);
    final bounds = path.getBounds();
    canvas
      ..saveLayer(bounds.inflate(2), Paint())
      ..drawPath(path, Paint()..color = color);
    final random = _SeededRandom(stroke.seed);
    final grainCount = (bounds.width * bounds.height / 30).clamp(0, 4000).toInt();
    final grainPaint = Paint()..blendMode = BlendMode.dstOut;
    for (var grain = 0; grain < grainCount; grain++) {
      final position = Offset(bounds.left + random.next() * bounds.width, bounds.top + random.next() * bounds.height);
      canvas.drawCircle(position, 1.2, grainPaint);
    }
    canvas.restore();
  }

  /// Dessine un trait de bombe : un nuage de petits points autour de chaque point du trait.
  ///
  /// - [canvas] : surface de dessin.
  /// - [stroke] : trait à dessiner.
  /// - [color] : couleur du trait.
  /// - [diameter] : diamètre du pinceau, en points du repère.
  void _paintSpray(Canvas canvas, DrawingStroke stroke, Color color, double diameter) {
    final random = _SeededRandom(stroke.seed);
    final paint = Paint()..color = color;
    final radius = diameter * 1.2;
    final dotRadius = (diameter / 14).clamp(1.5, 4.0);
    for (final point in stroke.points) {
      for (var dot = 0; dot < _sprayDotsPerPoint; dot++) {
        // Plus de points près du centre : la distance suit le carré d'un tirage.
        final distance = radius * random.next() * random.next();
        final angle = random.next() * 2 * pi;
        canvas.drawCircle(Offset(point.x + distance * cos(angle), point.y + distance * sin(angle)), dotRadius, paint);
      }
    }
  }
}

/// Générateur pseudo-aléatoire à graine (mulberry32).
///
/// Écrit ici plutôt que `Random(seed)` de Dart, dont la suite n'est pas
/// garantie identique d'une version à l'autre : le grain d'un crayon doit
/// tomber au même endroit sur tous les téléphones.
class _SeededRandom {
  _SeededRandom(this._state);

  /// État courant du générateur, sur 32 bits (initialisé par la graine du trait).
  int _state;

  /// Retourne un nombre entre 0 (inclus) et 1 (exclu).
  double next() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var value = _state;
    value = _multiply32(value ^ (value >> 15), value | 1);
    value ^= (value + _multiply32(value ^ (value >> 7), value | 61)) & 0xFFFFFFFF;
    return ((value ^ (value >> 14)) & 0xFFFFFFFF) / 4294967296;
  }

  /// Produit de [first] et [second] tronqué à 32 bits.
  ///
  /// Les entiers natifs de Dart font 64 bits et débordent en gardant leurs
  /// bits faibles : ce sont justement les 32 bits attendus.
  int _multiply32(int first, int second) {
    return (first * second) & 0xFFFFFFFF;
  }
}
