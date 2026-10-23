import 'package:bedbug/application/screens/settings/linkedin_click_counter_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/clown_bedbug_dialog.dart';
import 'package:bedbug/application/screens/settings/widgets/linkedin_click_challenge_dialog.dart';
import 'package:bedbug/application/screens/settings/widgets/social_links_editor.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../helpers/pump_app.dart';

void main() {
  /// Intercepte les appels au canal plateforme et retourne la liste des méthodes appelées.
  ///
  /// Permet de vérifier que l'app demande à se fermer (`SystemNavigator.pop`)
  /// sans réellement fermer quoi que ce soit pendant le test.
  List<String> recordPlatformCalls(WidgetTester tester) {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    return calls;
  }

  /// Monte l'éditeur, choisit LinkedIn, saisit un identifiant et appuie sur « Ajouter ».
  Future<FormControl<Map<SocialNetwork, String>>> startLinkedinAdd(WidgetTester tester) async {
    // Écran assez haut pour que le menu déroulant affiche les 12 réseaux,
    // LinkedIn (le dernier) compris.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final control = FormControl<Map<SocialNetwork, String>>(value: const {});
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SocialLinksEditor(control: control, accentColor: AppColors.primary),
        ),
      ),
    );

    await tester.tap(find.byType(ReactiveDropdownField<SocialNetwork>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LinkedIn').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bedbug');
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();
    return control;
  }

  testWidgets("même après les 100 clics et le bedbug clown, LinkedIn n'est pas ajouté et l'app se ferme", (
    tester,
  ) async {
    final platformCalls = recordPlatformCalls(tester);
    final control = await startLinkedinAdd(tester);

    await tester.tap(find.text("J'assume, je suis un leader"));
    await tester.pumpAndSettle();
    expect(find.byType(LinkedinClickChallengeDialog), findsOneWidget);

    for (var click = 0; click < linkedinRequiredClicks - 1; click++) {
      await tester.tap(find.text('Je suis sûr'));
      await tester.pump();
    }
    expect(find.text('99 / 100'), findsOneWidget);
    expect(control.value, isEmpty);

    await tester.tap(find.text('Je suis sûr'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ClownBedbugDialog), findsOneWidget);
    expect(find.text('BOUFON !'), findsWidgets);
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));

    await tester.tap(find.text("Je l'ai mérité"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ClownBedbugDialog), findsNothing);
    expect(control.value, isEmpty);
    expect(platformCalls, contains('SystemNavigator.pop'));
  });

  testWidgets("abandonner pendant les 100 clics n'ajoute pas le lien et ne ferme pas l'app", (tester) async {
    final platformCalls = recordPlatformCalls(tester);
    final control = await startLinkedinAdd(tester);

    await tester.tap(find.text("J'assume, je suis un leader"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Je suis sûr'));
    await tester.pump();
    await tester.tap(find.text("J'abandonne"));
    await tester.pumpAndSettle();

    expect(find.byType(LinkedinClickChallengeDialog), findsNothing);
    expect(control.value, isEmpty);
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
  });
}
