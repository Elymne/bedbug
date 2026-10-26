import 'package:bedbug/application/widgets/ghost/app_ghost_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Monte une animation ghost sous un grand espace vide, donc hors écran au départ, et retourne le controller du défilement.
///
/// - [frames] : liste remplie à chaque frame produite par l'animation.
Future<ScrollController> _pumpOffScreenAnimation(WidgetTester tester, List<GhostOffsets?> frames) async {
  final scrollController = ScrollController();
  addTearDown(scrollController.dispose);
  await pumpApp(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            const SizedBox(height: 3000),
            AppGhostAnimation(
              isAnimating: true,
              builder: (context, offsets) {
                frames.add(offsets);
                return const SizedBox(width: 40, height: 40);
              },
            ),
          ],
        ),
      ),
    ),
  );
  // Laisse passer la vérification de visibilité faite après la première mise en page.
  await tester.pump();
  return scrollController;
}

void main() {
  testWidgets('une animation hors écran ne produit plus de frame', (tester) async {
    final frames = <GhostOffsets?>[];
    await _pumpOffScreenAnimation(tester, frames);
    final frameCount = frames.length;

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(frames.length, frameCount);
  });

  testWidgets('une animation qui revient à l\'écran reprend', (tester) async {
    final frames = <GhostOffsets?>[];
    final scrollController = await _pumpOffScreenAnimation(tester, frames);

    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    final frameCount = frames.length;
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(frames.length, greaterThan(frameCount));
  });
}
