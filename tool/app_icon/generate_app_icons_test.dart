import 'dart:io';
import 'dart:ui' as ui;

import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bedbug de l'icône : un sourire en coin, malicieux.
const String _kBedbug = '(¬‿¬)';

/// Police du bedbug, la même que sur le splashscreen.
const String _kFontAsset = 'assets/fonts/DynaPuff_Condensed/DynaPuff-Bold.ttf';

/// Polices de secours pour les caractères absents de DynaPuff (`¬`, `‿`), prises dans les polices de Windows,
/// de la plus proche de DynaPuff gras à la plus complète.
///
/// Sur un téléphone, le système complète les glyphes manquants tout seul ;
/// dans un test, il n'y a pas de police système : il faut les charger.
const List<(String, String)> _kFallbackFonts = [
  ('IconFallbackBold', r'C:\Windows\Fonts\seguibl.ttf'),
  ('IconFallback', r'C:\Windows\Fonts\seguisym.ttf'),
];

/// Taille de police de référence, en pixels : celle du bedbug du splashscreen.
///
/// Le décalage des fantômes est donné à cette taille, puis mis à l'échelle
/// de la police de l'icône : 2 pixels sur une icône de 1024 ne se verraient
/// pas.
const double _kReferenceFontSize = 36;

/// Décalage des fantômes colorés pour un bedbug à la taille de police de référence, en pixels.
const double _kReferenceGhostOffset = 2;

/// Largeur du bedbug, en fraction du côté de l'icône.
const double _kContentRatio = 0.72;

/// Largeur du bedbug sur une icône « maskable », rognée en cercle par le système : il doit tenir dans la zone sûre.
const double _kMaskableContentRatio = 0.56;

/// Icônes à générer : chemin du fichier, côté en pixels, et `true` pour une icône maskable.
const List<(String, int, bool)> _kIcons = [
  ('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48, false),
  ('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72, false),
  ('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96, false),
  ('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144, false),
  ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png', 20, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png', 40, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png', 60, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png', 29, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png', 58, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png', 87, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png', 40, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png', 80, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png', 120, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png', 120, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png', 180, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png', 76, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png', 152, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png', 167, false),
  ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', 1024, false),
  ('web/favicon.png', 16, false),
  ('web/icons/Icon-192.png', 192, false),
  ('web/icons/Icon-512.png', 512, false),
  ('web/icons/Icon-maskable-192.png', 192, true),
  ('web/icons/Icon-maskable-512.png', 512, true),
];

/// Génère les icônes de l'app pour Android, iOS et le web.
///
/// Écrit comme un test pour profiter du moteur de rendu de Flutter (polices,
/// texte, export PNG) sans outil externe. Rangé hors de `test/` : il réécrit
/// des fichiers du projet, il ne doit tourner que sur demande.
///
/// ```sh
/// flutter test tool/app_icon/generate_app_icons_test.dart
/// ```
void main() {
  testWidgets('génère les icônes de l\'app', (tester) async {
    await tester.runAsync(() async {
      await _loadFonts();
      for (final (path, size, isMaskable) in _kIcons) {
        final bytes = await _renderIcon(size, isMaskable: isMaskable);
        File(path).writeAsBytesSync(bytes);
      }
    });
  });
}

/// Charge la police du bedbug et ses polices de secours, absentes par défaut d'un test.
Future<void> _loadFonts() async {
  await (FontLoader('IconBedbug')..addFont(rootBundle.load(_kFontAsset))).load();
  for (final (family, path) in _kFallbackFonts) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())))).load();
  }
}

/// Retourne l'icône de côté [size], encodée en PNG.
///
/// Un fond plein couleur surface (opaque : iOS refuse la transparence), et
/// le bedbug centré, précédé de deux fantômes décalés : primaire en haut à
/// gauche, secondaire en bas à droite.
///
/// - [size] : côté de l'icône, en pixels.
/// - [isMaskable] : `true` pour garder le bedbug dans la zone sûre d'une icône rognée par le système.
Future<Uint8List> _renderIcon(int size, {required bool isMaskable}) async {
  final side = size.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawRect(Rect.fromLTWH(0, 0, side, side), Paint()..color = AppColors.surface);

  // Mesuré à une taille de police arbitraire, puis remis à l'échelle de la largeur voulue.
  final measure = _bedbugPainter(100, AppColors.onLight);
  final fontSize = 100 * side * (isMaskable ? _kMaskableContentRatio : _kContentRatio) / measure.width;
  final ghostOffset = _kReferenceGhostOffset * fontSize / _kReferenceFontSize;

  for (final (color, offset) in [
    (AppColors.primary, Offset(-ghostOffset, -ghostOffset)),
    (AppColors.secondary, Offset(ghostOffset, ghostOffset)),
    (AppColors.onLight, Offset.zero),
  ]) {
    final painter = _bedbugPainter(fontSize, color);
    painter.paint(canvas, Offset((side - painter.width) / 2, (side - painter.height) / 2) + offset);
  }

  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

/// Retourne le texte du bedbug mis en page, en [color], à la taille de police [fontSize].
///
/// - [fontSize] : taille de police, en pixels.
/// - [color] : couleur du texte.
TextPainter _bedbugPainter(double fontSize, Color color) {
  return TextPainter(
    text: TextSpan(
      text: _kBedbug,
      style: TextStyle(
        fontFamily: 'IconBedbug',
        fontFamilyFallback: [for (final (family, _) in _kFallbackFonts) family],
        fontSize: fontSize,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}
