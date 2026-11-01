import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_const.dart';
import 'package:bedbug/application/widgets/navbar/app_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/find_app_icon.dart';
import '../helpers/pump_app.dart';

/// Items les plus longs de l'app, ceux de l'italien.
const List<AppNavBarItem> _kItems = [
  AppNavBarItem(icon: AppIcons.home, label: 'Home'),
  AppNavBarItem(icon: AppIcons.add, label: 'Crea'),
  AppNavBarItem(icon: AppIcons.bluetooth, label: 'Scambio'),
  AppNavBarItem(icon: AppIcons.settings, label: 'Impostazioni'),
];

/// Monte la barre dans la hauteur que la home lui réserve.
Future<void> _pumpNavBar(WidgetTester tester, {ValueChanged<int>? onTap}) async {
  await pumpApp(
    tester,
    Scaffold(
      bottomNavigationBar: SizedBox(
        height: AppConst.homeNavBarBaseHeight,
        child: AppNavBar(selectedIndex: 3, items: _kItems, onTap: onTap ?? (_) {}),
      ),
    ),
  );
}

void main() {
  testWidgets('affiche chaque texte sous son icône, dans la couleur de son état', (tester) async {
    await _pumpNavBar(tester);

    for (final item in _kItems) {
      final iconBottom = tester.getBottomLeft(findAppIcon(item.icon)).dy;
      expect(tester.getTopLeft(find.text(item.label)).dy, greaterThanOrEqualTo(iconBottom));
    }
    expect(tester.widget<Text>(find.text('Impostazioni')).style?.color, AppColors.primary);
    expect(tester.widget<Text>(find.text('Home')).style?.color, AppColors.onLight);
  });

  testWidgets('tient sur un petit écran, sans débordement', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpNavBar(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('tient avec le plus grand texte système', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpNavBar(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('toute la largeur d\'un item réagit au tap, le texte compris', (tester) async {
    final tappedIndexes = <int>[];
    await _pumpNavBar(tester, onTap: tappedIndexes.add);

    await tester.tap(find.text('Crea'));
    await tester.tapAt(tester.getTopLeft(find.byType(AppNavBar)) + const Offset(1, 5));

    expect(tappedIndexes, [1, 0]);
  });
}
