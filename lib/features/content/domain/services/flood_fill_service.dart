import 'dart:typed_data';

import 'package:bedbug/shared/domain/service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écart de couleur toléré par défaut, somme des écarts des canaux rouge, vert, bleu et alpha.
///
/// Les bords d'un trait sont adoucis (anticrénelage) : sans tolérance, le
/// remplissage s'arrêterait avant le trait et laisserait un liseré.
const int defaultFillTolerance = 96;

/// Provider du [FloodFillService].
final floodFillServiceProvider = Provider<FloodFillService>((ref) => const FloodFillService());

/// Calcule la zone couverte par un pot de peinture, sur une image en mémoire.
///
/// Un dessin vectoriel n'a pas de « zone fermée » : seulement des traits qui
/// se croisent. Le remplissage se calcule donc sur l'image déjà dessinée :
/// on part du point touché et on s'étend à tous les pixels voisins de même
/// couleur. L'image a toujours la même taille, quel que soit l'écran : le
/// même dessin donne la même zone sur tous les téléphones.
class FloodFillService extends Service {
  /// Crée un [FloodFillService].
  const FloodFillService();

  /// Retourne le masque de la zone à remplir depuis ([x], [y]) : 255 pour un pixel à peindre, 0 sinon.
  ///
  /// La zone est agrandie d'un pixel tout autour, pour recouvrir le bord
  /// adouci des traits qui l'entourent. Un point hors de l'image, ou une
  /// image de taille incohérente, donne un masque vide.
  ///
  /// - [rgba] : pixels de l'image, 4 octets par pixel (rouge, vert, bleu, alpha), ligne par ligne.
  /// - [width] : largeur de l'image, en pixels.
  /// - [height] : hauteur de l'image, en pixels.
  /// - [x] : abscisse du point de départ, en pixels.
  /// - [y] : ordonnée du point de départ, en pixels.
  /// - [tolerance] : écart de couleur toléré avec le pixel de départ.
  Uint8List fillMask(Uint8List rgba, int width, int height, int x, int y, {int tolerance = defaultFillTolerance}) {
    final mask = Uint8List(width < 0 || height < 0 ? 0 : width * height);
    if (width <= 0 || height <= 0 || rgba.length != width * height * 4) {
      return mask;
    }
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return mask;
    }

    final seedOffset = (y * width + x) * 4;
    final seed = [rgba[seedOffset], rgba[seedOffset + 1], rgba[seedOffset + 2], rgba[seedOffset + 3]];

    /// Indique si le pixel [index] fait partie de la zone, sans avoir déjà été visité.
    bool isFillable(int index) {
      if (mask[index] != 0) {
        return false;
      }
      final offset = index * 4;
      final distance =
          (rgba[offset] - seed[0]).abs() +
          (rgba[offset + 1] - seed[1]).abs() +
          (rgba[offset + 2] - seed[2]).abs() +
          (rgba[offset + 3] - seed[3]).abs();
      return distance <= tolerance;
    }

    // Remplissage par lignes : chaque ligne est parcourue d'un bord à l'autre,
    // et seuls les débuts de segments des lignes voisines sont empilés.
    final pending = <int>[y * width + x];
    while (pending.isNotEmpty) {
      final start = pending.removeLast();
      if (!isFillable(start)) {
        continue;
      }
      final row = start ~/ width;
      final rowStart = row * width;
      var left = start;
      while (left > rowStart && isFillable(left - 1)) {
        left--;
      }
      var right = start;
      while (right < rowStart + width - 1 && isFillable(right + 1)) {
        right++;
      }
      for (var index = left; index <= right; index++) {
        mask[index] = 255;
      }
      for (final neighbourRow in [row - 1, row + 1]) {
        if (neighbourRow < 0 || neighbourRow >= height) {
          continue;
        }
        var isInSegment = false;
        for (var column = left - rowStart; column <= right - rowStart; column++) {
          final index = neighbourRow * width + column;
          final isCandidate = isFillable(index);
          if (isCandidate && !isInSegment) {
            pending.add(index);
          }
          isInSegment = isCandidate;
        }
      }
    }

    return _grow(mask, width, height);
  }

  /// Retourne [mask] agrandi d'un pixel dans les quatre directions.
  ///
  /// - [mask] : masque à agrandir.
  /// - [width] : largeur du masque, en pixels.
  /// - [height] : hauteur du masque, en pixels.
  Uint8List _grow(Uint8List mask, int width, int height) {
    final grown = Uint8List.fromList(mask);
    for (var row = 0; row < height; row++) {
      for (var column = 0; column < width; column++) {
        final index = row * width + column;
        if (mask[index] == 0) {
          continue;
        }
        if (column > 0) {
          grown[index - 1] = 255;
        }
        if (column < width - 1) {
          grown[index + 1] = 255;
        }
        if (row > 0) {
          grown[index - width] = 255;
        }
        if (row < height - 1) {
          grown[index + width] = 255;
        }
      }
    }
    return grown;
  }
}
