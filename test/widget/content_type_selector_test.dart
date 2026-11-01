import 'package:bedbug/application/screens/create/widgets/content_type_selector.dart';
import 'package:bedbug/application/widgets/ghost/app_ghost_icon.dart';
import 'package:bedbug/features/content/domain/enums/content_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/find_app_icon.dart';
import '../helpers/pump_app.dart';

/// Monte le sélecteur sur le type texte et retourne la liste des types tapés.
Future<List<ContentType>> _pumpSelector(WidgetTester tester, {bool isLocked = false}) async {
  final selectedTypes = <ContentType>[];
  await pumpApp(
    tester,
    Scaffold(
      body: ContentTypeSelector(selectedType: ContentType.text, isLocked: isLocked, onTypeSelected: selectedTypes.add),
    ),
  );
  return selectedTypes;
}

void main() {
  testWidgets('anime le type sélectionné et affiche les autres en grand', (tester) async {
    await _pumpSelector(tester);

    expect(find.byType(AppGhostIcon), findsOneWidget);
    expect(tester.getSize(findAppIcon(AppIcons.link)), const Size(32, 32));
  });

  testWidgets('tient sur le plus petit écran courant', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpSelector(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('un tap dans la marge d\'une case la sélectionne aussi', (tester) async {
    final selectedTypes = await _pumpSelector(tester);

    await tester.tapAt(tester.getTopLeft(findAppIcon(AppIcons.link)) - const Offset(10, 10));

    expect(selectedTypes, [ContentType.link]);
  });

  testWidgets('un type verrouillé ne réagit pas', (tester) async {
    final selectedTypes = await _pumpSelector(tester, isLocked: true);

    await tester.tap(findAppIcon(AppIcons.link));

    expect(selectedTypes, isEmpty);
  });
}
