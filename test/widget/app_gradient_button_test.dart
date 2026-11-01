import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/buttons/app_form_submit_button.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../helpers/pump_app.dart';

/// Retourne la couleur de fond actuelle du bouton affiché.
Color? _backgroundColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
  return (container.decoration! as BoxDecoration).color;
}

void main() {
  testWidgets('sans onTap, le bouton passe en gris et ne réagit pas', (tester) async {
    await pumpApp(tester, const AppGradientButton(onTap: null, child: Text('ok')));

    expect(_backgroundColor(tester), AppColors.border);
    final style = tester.widget<AnimatedDefaultTextStyle>(find.byType(AnimatedDefaultTextStyle)).style;
    expect(style.color, AppColors.disabled);
  });

  testWidgets('avec onTap, le bouton garde son fond plein et réagit', (tester) async {
    var tapCount = 0;
    await pumpApp(tester, AppGradientButton(onTap: () => tapCount++, child: const Text('ok')));

    await tester.tap(find.text('ok'));

    expect(_backgroundColor(tester), AppColors.onLight);
    expect(tapCount, 1);
  });

  testWidgets('en chargement, le bouton garde son fond plein et ignore les taps', (tester) async {
    var tapCount = 0;
    await pumpApp(tester, AppGradientButton(isLoading: true, onTap: () => tapCount++, child: const Text('ok')));

    await tester.tap(find.byType(AppGradientButton));

    expect(_backgroundColor(tester), AppColors.onLight);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tapCount, 0);
  });

  testWidgets('AppFormSubmitButton suit la validité du formulaire, dans les deux sens', (tester) async {
    final control = FormControl<String>(validators: [Validators.required]);
    final form = FormGroup({'name': control});
    addTearDown(form.dispose);
    await pumpApp(tester, AppFormSubmitButton(form: form, onTap: () {}, child: const Text('ok')));
    expect(tester.widget<AppGradientButton>(find.byType(AppGradientButton)).onTap, isNull);

    control.value = 'bedbug';
    await tester.pump();
    expect(tester.widget<AppGradientButton>(find.byType(AppGradientButton)).onTap, isNotNull);

    control.value = '';
    await tester.pump();
    expect(tester.widget<AppGradientButton>(find.byType(AppGradientButton)).onTap, isNull);
  });
}
