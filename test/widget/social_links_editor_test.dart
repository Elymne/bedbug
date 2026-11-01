import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/select_options/select_options_screen.dart';
import 'package:bedbug/application/screens/settings/linkedin_click_counter_notifier.dart';
import 'package:bedbug/application/screens/settings/widgets/clown_bedbug_dialog.dart';
import 'package:bedbug/application/screens/settings/widgets/linkedin_click_challenge_dialog.dart';
import 'package:bedbug/application/screens/settings/widgets/social_handle_dialog.dart';
import 'package:bedbug/application/screens/settings/widgets/social_links_editor.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/widgets/buttons/app_gradient_button.dart';
import 'package:bedbug/features/signature/domain/enums/social_network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Laisse s'ouvrir la popup de saisie, dont le champ actif empêche `pumpAndSettle` de rendre la main.
Future<void> _settleDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Monte l'éditeur avec le vrai enchaînement de pages, et retourne son contrôle.
Future<FormControl<Map<SocialNetwork, String>>> _pumpEditor(
  WidgetTester tester, {
  Map<SocialNetwork, String> links = const {},
}) async {
  // Écran assez haut pour que la page des réseaux les affiche tous, LinkedIn (le dernier) compris.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final control = FormControl<Map<SocialNetwork, String>>(value: links);
  final router = GoRouter(
    initialLocation: '/editor',
    routes: [
      GoRoute(
        path: '/editor',
        builder: (context, state) {
          return Scaffold(
            body: SingleChildScrollView(
              child: SocialLinksEditor(control: control, accentColor: AppColors.primary),
            ),
          );
        },
      ),
      GoRoute(
        path: selectOptionsPath,
        builder: (context, state) => SelectOptionsScreen(params: state.extra! as SelectOptionsParams),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: router,
      ),
    ),
  );
  return control;
}

/// Choisit [networkName] dans la selectbox, ce qui ouvre la popup de saisie.
Future<void> _pickNetwork(WidgetTester tester, String networkName) async {
  await tester.tap(find.text('Ajouter un réseau'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(networkName));
  await _settleDialog(tester);
}

/// Retourne le bouton de validation de la popup.
AppGradientButton _submitButton(WidgetTester tester) {
  return tester.widget<AppGradientButton>(find.byType(AppGradientButton));
}

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
    final control = await _pumpEditor(tester);
    await _pickNetwork(tester, 'LinkedIn');
    await tester.enterText(find.byType(TextField), 'bedbug');
    await tester.pump();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    return control;
  }

  testWidgets('choisir un réseau ouvre la popup, valider ajoute le lien normalisé et vide la selectbox', (
    tester,
  ) async {
    final control = await _pumpEditor(tester);
    final network = SocialNetwork.values.first;
    final networkName = network.name[0].toUpperCase() + network.name.substring(1);

    await tester.tap(find.text('Ajouter un réseau'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await _settleDialog(tester);
    expect(find.byType(SocialHandleDialog), findsOneWidget, reason: 'la popup doit survivre à la fermeture de la page');

    await tester.enterText(find.byType(TextField), '  bedbug  ');
    await tester.pump();
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    expect(find.byType(SocialHandleDialog), findsNothing, reason: networkName);
    expect(control.value, {network: 'bedbug'});
    expect(find.text('Réseau'), findsOneWidget, reason: 'la selectbox doit redevenir vide');
  });

  testWidgets('le bouton de la popup reste désactivé tant que la saisie est vide ou invalide', (tester) async {
    await _pumpEditor(tester);
    await tester.tap(find.text('Ajouter un réseau'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await _settleDialog(tester);
    expect(_submitButton(tester).onTap, isNull);

    await tester.enterText(find.byType(TextField), 'https://autre-site.example/bedbug');
    await tester.pump();
    expect(_submitButton(tester).onTap, isNull);

    await tester.enterText(find.byType(TextField), 'bedbug');
    await tester.pump();
    expect(_submitButton(tester).onTap, isNotNull);
  });

  testWidgets('annuler la popup n\'ajoute rien et vide la selectbox', (tester) async {
    final control = await _pumpEditor(tester);
    await tester.tap(find.text('Ajouter un réseau'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await _settleDialog(tester);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.byType(SocialHandleDialog), findsNothing);
    expect(control.value, isEmpty);
    expect(find.text('Réseau'), findsOneWidget);
  });

  testWidgets('un réseau déjà renseigné n\'est plus proposé', (tester) async {
    final network = SocialNetwork.values.first;
    await _pumpEditor(tester, links: {network: 'bedbug'});

    await tester.tap(find.text('Ajouter un réseau'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(SocialNetwork.values.length - 1));
  });

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
