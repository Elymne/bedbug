/// Nombre de calques d'un dessin.
const int drawingLayerCount = 3;

/// Nombre de tailles de pinceau.
const int drawingBrushSizeCount = 4;

/// Nombre de couleurs d'une palette.
///
/// C'est le verrou le plus efficace contre une photo convertie en dessin :
/// une photo a besoin de milliers de nuances, et n'est plus qu'une affiche
/// grossière avec 16.
const int drawingPaletteSize = 16;

/// Nombre maximal d'opérations (traits et remplissages) d'un dessin.
const int maxDrawingOperations = 500;

/// Nombre maximal de remplissages d'un dessin : chacun demande de recalculer une zone à l'affichage.
const int maxDrawingFills = 50;

/// Nombre maximal de points d'un trait.
const int maxDrawingStrokePoints = 1000;

/// Nombre maximal de points d'un dessin, tous traits confondus.
const int maxDrawingPoints = 20000;

/// Plus grande graine acceptée (entier non signé sur 32 bits).
const int maxDrawingSeed = 0xFFFFFFFF;

/// Palette proposée pour un nouveau dessin, en couleurs ARGB opaques.
const List<int> defaultDrawingPalette = [
  0xFF1A1A1A, // noir
  0xFFFFFFFF, // blanc
  0xFF8C8C8C, // gris
  0xFF4A4A4A, // gris foncé
  0xFFE53935, // rouge
  0xFFFB8C00, // orange
  0xFFFDD835, // jaune
  0xFF7CB342, // vert
  0xFF2E7D32, // vert foncé
  0xFF26C6DA, // cyan
  0xFF1E88E5, // bleu
  0xFF283593, // bleu nuit
  0xFF8E24AA, // violet
  0xFFF48FB1, // rose
  0xFF795548, // marron
  0xFFFFE0B2, // beige
];

/// Nom de la box Hive du brouillon de dessin.
const String drawingDraftBoxName = 'drawing_draft';
