import 'package:bedbug/application/widgets/scroll/app_sticky_top.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hauteur de la zone gardée visible.
const double _kStickyHeight = 100;

/// Hauteur du contenu qui défile sous la zone gardée visible.
const double _kBodyHeight = 1500;

/// Hauteur du bloc placé avant le formulaire dans la liste.
const double _kIntroHeight = 200;

/// Monte une liste dont le second élément porte une zone [AppStickyTop] au-dessus d'un long contenu.
Future<ScrollController> _pumpList(WidgetTester tester, {required VoidCallback onBodyTap}) async {
  final controller = ScrollController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: controller,
          children: [
            const SizedBox(height: _kIntroHeight),
            Column(
              verticalDirection: VerticalDirection.up,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _kBodyHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBodyTap,
                    child: const Text('corps'),
                  ),
                ),
                const AppStickyTop(
                  child: SizedBox(height: _kStickyHeight, child: Text('zone')),
                ),
              ],
            ),
            const SizedBox(height: _kBodyHeight),
          ],
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  testWidgets('suit la liste tant que son haut est visible', (tester) async {
    final controller = await _pumpList(tester, onBodyTap: () {});

    expect(tester.getTopLeft(find.text('zone')).dy, _kIntroHeight);

    controller.jumpTo(50);
    await tester.pump();

    expect(tester.getTopLeft(find.text('zone')).dy, _kIntroHeight - 50);
  });

  testWidgets('reste collée en haut une fois son emplacement dépassé', (tester) async {
    final controller = await _pumpList(tester, onBodyTap: () {});

    controller.jumpTo(_kIntroHeight + 400);
    await tester.pump();

    expect(tester.getTopLeft(find.text('zone')).dy, 0);
  });

  testWidgets('ne sort pas de son parent et part avec lui quand il quitte l\'écran', (tester) async {
    final controller = await _pumpList(tester, onBodyTap: () {});

    // Il ne reste que 50 pixels du parent à l'écran : moins que la hauteur de la zone.
    controller.jumpTo(_kIntroHeight + _kBodyHeight + _kStickyHeight - 50);
    await tester.pump();

    expect(tester.getBottomLeft(find.text('zone')).dy, 50);
  });

  testWidgets('retient les taps sur la zone collée, et laisse passer ceux à côté', (tester) async {
    var tapCount = 0;
    final controller = await _pumpList(tester, onBodyTap: () => tapCount++);

    controller.jumpTo(_kIntroHeight + 400);
    await tester.pump();

    await tester.tapAt(const Offset(10, _kStickyHeight / 2));
    expect(tapCount, 0);

    await tester.tapAt(const Offset(10, _kStickyHeight + 50));
    expect(tapCount, 1);
  });
}
