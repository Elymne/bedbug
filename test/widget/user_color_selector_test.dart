import 'package:bedbug/application/screens/settings/widgets/user_color_selector.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('une pastille prédéfinie applique sa couleur', (tester) async {
    final control = FormControl<Color>(value: AppColors.primary);
    await pumpApp(tester, Scaffold(body: UserColorSelector(control: control)));

    // Deuxième pastille de la palette : AppColors.info.
    await tester.tap(find.byType(GestureDetector).at(1));
    await tester.pumpAndSettle();

    expect(control.value, AppColors.info);
  });

  // Non-régression : avec flex_color_picker 4.x (dépendant de `material_ui`),
  // le dialog plantait faute de MaterialLocalizations et ne s'ouvrait jamais.
  testWidgets('la pastille libre ouvre le color picker et applique la couleur saisie', (tester) async {
    final control = FormControl<Color>(value: AppColors.primary);
    await pumpApp(tester, Scaffold(body: UserColorSelector(control: control)));

    await tester.tap(find.byIcon(Icons.colorize));
    await tester.pumpAndSettle();
    expect(find.byType(ColorPicker), findsOneWidget);

    await tester.enterText(find.byType(TextField), '00FF00');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextButton).last);
    await tester.pumpAndSettle();

    expect(control.value?.toARGB32(), 0xFF00FF00);
  });
}
