import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/tag_color_x.dart';
import 'package:bedbug/application/widgets/tags/app_tag.dart';
import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:bedbug/features/content/domain/enums/tag_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('une seule couleur s\'affiche sans erreur, et le texte se lit', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: AppTag(label: 'Info', colors: [AppColors.info]),
      ),
    );

    expect(find.text('Info'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plusieurs couleurs s\'affichent sans erreur, et le texte se lit', (tester) async {
    await pumpApp(
      tester,
      const Center(
        child: AppTag(label: 'Pride', colors: [AppColors.primary, AppColors.orange, AppColors.purple]),
      ),
    );

    expect(find.text('Pride'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('les couleurs d\'un tag suivent l\'ordre de son catalogue', () {
    expect(Tag.info.flutterColors, [TagColor.blue.flutterColor]);
  });
}
