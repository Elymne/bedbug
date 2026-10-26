import 'package:bedbug/application/widgets/scroll/app_scroll_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Hauteur de l'élément révélé dans les tests.
const double _itemHeight = 100;

/// Opacité courante de l'élément révélé.
double _opacity(WidgetTester tester) {
  final fade = tester.widget<FadeTransition>(
    find.descendant(of: find.byType(AppScrollReveal), matching: find.byType(FadeTransition)),
  );
  return fade.opacity.value;
}

/// Laisse les animations d'apparition ou de disparition se terminer.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 800));
}

/// Monte un élément révélé sous un grand espace vide, donc hors écran au départ, et retourne le controller du défilement.
Future<ScrollController> _pumpScrolledReveal(WidgetTester tester) async {
  final scrollController = ScrollController();
  addTearDown(scrollController.dispose);
  await pumpApp(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: const Column(
          children: [
            SizedBox(height: 2000),
            AppScrollReveal(child: SizedBox(height: _itemHeight, width: 100)),
            SizedBox(height: 2000),
          ],
        ),
      ),
    ),
  );
  await _settle(tester);
  return scrollController;
}

void main() {
  testWidgets('hors défilement, l\'élément est affiché', (tester) async {
    await pumpApp(tester, const AppScrollReveal(child: SizedBox(height: _itemHeight)));
    await _settle(tester);

    expect(_opacity(tester), 1);
  });

  testWidgets('un élément hors écran reste invisible', (tester) async {
    await _pumpScrolledReveal(tester);

    expect(_opacity(tester), 0);
  });

  testWidgets('un élément qui entre entièrement à l\'écran apparaît', (tester) async {
    final scrollController = await _pumpScrolledReveal(tester);

    scrollController.jumpTo(1900);
    await _settle(tester);

    expect(_opacity(tester), 1);
  });

  testWidgets('un élément qui commence à sortir de l\'écran disparaît', (tester) async {
    final scrollController = await _pumpScrolledReveal(tester);
    scrollController.jumpTo(1900);
    await _settle(tester);

    // L'élément commence à 2000 : décaler de 2050 en coupe le haut.
    scrollController.jumpTo(2050);
    await _settle(tester);

    expect(_opacity(tester), 0);
  });
}
