import 'dart:io';

import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Retourne l'image SVG affichée.
SvgPicture _picture(WidgetTester tester) {
  return tester.widget<SvgPicture>(find.byType(SvgPicture));
}

void main() {
  test('chaque icône déclarée a son fichier, et chaque fichier sa déclaration', () {
    final files = Directory('assets/icons').listSync().map((file) => file.path.replaceAll(r'\', '/')).toSet();

    expect(files, AppIcons.values.map((icon) => icon.assetPath).toSet());
  });

  test('chaque icône respecte le style : traits arrondis, aucun remplissage', () {
    for (final icon in AppIcons.values) {
      final svg = File(icon.assetPath).readAsStringSync();

      expect(svg, contains('viewBox="0 0 24 24"'), reason: icon.name);
      expect(svg, contains('stroke-linecap="round"'), reason: icon.name);
      expect(svg, contains('stroke-linejoin="round"'), reason: icon.name);
      expect(RegExp('fill="([^"]*)"').allMatches(svg).map((match) => match.group(1)).toSet(), {
        'none',
      }, reason: icon.name);
    }
  });

  testWidgets('chaque icône se décode avec flutter_svg', (tester) async {
    await tester.runAsync(() async {
      for (final icon in AppIcons.values) {
        final loader = SvgStringLoader(File(icon.assetPath).readAsStringSync());
        final pictureInfo = await vg.loadPicture(loader, null);
        expect(pictureInfo.size, const Size(24, 24), reason: icon.name);
        pictureInfo.picture.dispose();
      }
    });
  });

  testWidgets('prend la couleur et la taille du thème d\'icônes', (tester) async {
    await pumpApp(
      tester,
      const IconTheme(
        data: IconThemeData(color: AppColors.primary, size: 18),
        child: AppIcon(AppIcons.check),
      ),
    );

    expect(_picture(tester).width, 18);
    expect(_picture(tester).height, 18);
    expect(_picture(tester).colorFilter, const ColorFilter.mode(AppColors.primary, BlendMode.srcIn));
  });

  testWidgets('forcée plus grande par son parent, elle garde sa taille au lieu de s\'étirer', (tester) async {
    await pumpApp(
      tester,
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: const AppIcon(AppIcons.check, size: 24),
        ),
      ),
    );

    expect(tester.getSize(find.byType(SvgPicture)), const Size(24, 24));
  });

  testWidgets('chaque fichier est bien déclaré dans les assets de l\'app', (tester) async {
    await tester.runAsync(() async {
      for (final icon in AppIcons.values) {
        final bytes = await rootBundle.load(icon.assetPath);
        expect(bytes.lengthInBytes, greaterThan(0), reason: icon.name);
      }
    });
  });

  testWidgets('sa couleur et sa taille passent avant celles du thème', (tester) async {
    await pumpApp(
      tester,
      const IconTheme(
        data: IconThemeData(color: AppColors.primary, size: 18),
        child: AppIcon(AppIcons.check, color: AppColors.failure, size: 40),
      ),
    );

    expect(_picture(tester).width, 40);
    expect(_picture(tester).colorFilter, const ColorFilter.mode(AppColors.failure, BlendMode.srcIn));
  });

  testWidgets('un bouton désactivé grise son icône', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: IconButton(onPressed: null, disabledColor: AppColors.disabled, icon: AppIcon(AppIcons.check)),
      ),
    );

    expect(_picture(tester).colorFilter, const ColorFilter.mode(AppColors.disabled, BlendMode.srcIn));
  });

  testWidgets('seules les icônes indiquant un sens se retournent de droite à gauche', (tester) async {
    await pumpApp(tester, const AppIcon(AppIcons.arrowBack));
    expect(_picture(tester).matchTextDirection, isTrue);

    await pumpApp(tester, const AppIcon(AppIcons.check));
    expect(_picture(tester).matchTextDirection, isFalse);
  });
}
