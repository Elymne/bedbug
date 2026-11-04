import 'package:bedbug/application/app_root.widget.dart';
import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/notifiers/passive_exchange.notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/avatar_picker/avatar_picker.screen.dart';
import 'package:bedbug/application/screens/content_detail/text_content_detail.screen.dart';
import 'package:bedbug/application/screens/create/create.screen.dart';
import 'package:bedbug/application/screens/drawing_editor/drawing_editor.screen.dart';
import 'package:bedbug/application/screens/drawing_format/drawing_format.screen.dart';
import 'package:bedbug/application/screens/exchange/exchange.screen.dart';
import 'package:bedbug/application/screens/exchange_logs/exchange_logs.screen.dart';
import 'package:bedbug/application/screens/home/home.screen.dart';
import 'package:bedbug/application/screens/search/search.screen.dart';
import 'package:bedbug/application/screens/settings/debug_section/debug_section.widget.dart';
import 'package:bedbug/application/screens/settings/exchange_stats_section/exchange_stats_section.widget.dart';
import 'package:bedbug/application/screens/settings/language_section/language_section.widget.dart';
import 'package:bedbug/application/screens/settings/own_contents_section/own_contents_section.widget.dart';
import 'package:bedbug/application/screens/settings/publishing_section/publishing_section.widget.dart';
import 'package:bedbug/application/screens/settings/settings.screen.dart';
import 'package:bedbug/application/screens/settings/signature_section/signature_section.widget.dart';
import 'package:bedbug/application/screens/settings/storage_section/storage_section.widget.dart';
import 'package:bedbug/application/screens/settings/trust_section/trust_section.widget.dart';
import 'package:bedbug/application/screens/signature/signature.screen.dart';
import 'package:bedbug/application/screens/signature_setup/signature_setup.screen.dart';
import 'package:bedbug/application/screens/tag_picker/tag_picker.screen.dart';
import 'package:bedbug/core/config/app_config.dart';
import 'package:bedbug/resources/content/content/tag.enum.dart';
import 'package:bedbug/resources/hive.initializer.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Dossier des données Hive du smoke test, à part de celles de l'app : le test les efface à chaque lancement.
const String _kSmokeHiveDirectory = 'smoke_test';

/// Temps laissé à une page pour s'ouvrir et se construire.
///
/// Les pages animées en boucle (effet ghost, ciel de l'échange) ne se « stabilisent » jamais : on avance l'horloge
/// d'une durée fixe plutôt que d'attendre la fin des animations.
const Duration _kPageSettleDuration = Duration(milliseconds: 1200);

/// Délai maximal pour qu'une page attendue apparaisse.
const Duration _kAppearTimeout = Duration(seconds: 15);

/// Smoke test de l'app sur un vrai téléphone : elle démarre, chaque page s'ouvre sans planter, et un contenu peut
/// être publié.
///
/// Ne vérifie pas le détail des pages : seulement qu'aucune ne lève d'erreur. Contrairement aux tests de `test/`, il
/// passe par le vrai Hive sur disque, les vraies polices et le vrai moteur de rendu. L'échange Bluetooth n'est pas
/// lancé : la demande de permission est une fenêtre système, hors de portée du test.
///
/// À lancer avant chaque version, téléphone Android branché :
/// `flutter test integration_test/app_smoke_test.dart`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('premier lancement, tour de toutes les pages, publication d\'un contenu', (tester) async {
    // Démarrage comme `main.dart`, sur une base vide à part : le test repart toujours du premier lancement.
    await AppConfig.init();
    await initHive(subDirectory: _kSmokeHiveDirectory);
    await Hive.deleteFromDisk();
    await initHive(subDirectory: _kSmokeHiveDirectory);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(passiveExchangeNotifierProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AppRoot()));

    // Premier lancement : le splash mène à la création de la signature, qui ouvre sa popup d'explication.
    await _pumpUntilFound(tester, find.byType(SignatureSetupScreen));
    final l10n = AppLocalizations.of(tester.element(find.byType(SignatureSetupScreen)))!;
    await _pumpUntilFound(tester, find.text(l10n.signatureSetupInfoConfirm));
    await tester.tap(find.text(l10n.signatureSetupInfoConfirm));
    await tester.pump(_kPageSettleDuration);

    await tester.enterText(find.byType(ReactiveTextField<String>).first, 'smoke');
    await tester.pump();
    await tester.ensureVisible(find.text(l10n.signatureSetupSubmit));
    await tester.tap(find.text(l10n.signatureSetupSubmit));
    await _pumpUntilFound(tester, find.byType(HomeScreen));
    _expectNoException(tester, 'création de la signature');

    // Tour des pages : chacune s'ouvre, se construit sans erreur, puis se referme.
    final router = container.read(routerProvider);
    final pages = <(String, Object?, Type)>[
      (createPath, null, CreateScreen),
      (exchangePath, null, ExchangeScreen),
      (searchPath, null, SearchScreen),
      ('$signaturesPath/$localSignatureId', null, SignatureScreen),
      (avatarPickerPath, null, AvatarPickerScreen),
      (tagPickerPath, const <Tag>[], TagPickerScreen),
      (drawingFormatPath, null, DrawingFormatScreen),
      (drawingEditorPath, null, DrawingEditorScreen),
      (settingsPath, null, SettingsScreen),
      (settingsSignaturePath, null, SignatureSection),
      (settingsLanguagePath, null, LanguageSection),
      (settingsPublishingPath, null, PublishingSection),
      (settingsTrustPath, null, TrustSection),
      (settingsStoragePath, null, StorageSection),
      (settingsOwnContentsPath, null, OwnContentsSection),
      (settingsExchangeStatsPath, null, ExchangeStatsSection),
      (settingsDebugPath, null, DebugSection),
      (exchangeLogsPath, null, ExchangeLogsScreen),
    ];
    for (final (path, extra, pageType) in pages) {
      router.push(path, extra: extra);
      await _pumpUntilFound(tester, find.byType(pageType));
      await tester.pump(_kPageSettleDuration);
      _expectNoException(tester, path);
      router.pop();
      await tester.pump(_kPageSettleDuration);
    }

    // Publication d'un texte : écriture dans Hive, puis ouverture du contenu publié.
    router.push(createPath);
    await _pumpUntilFound(tester, find.byType(CreateScreen));
    await tester.pump(_kPageSettleDuration);
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextTitleLabel), 'Smoke test');
    await tester.enterText(find.widgetWithText(TextField, l10n.createTextBodyLabel), 'Publié par le smoke test.');
    await tester.enterText(find.widgetWithText(TextField, l10n.createFlairLabel), 'smoke');
    await tester.pump();
    await tester.ensureVisible(find.text(l10n.createSaveButton));
    await tester.tap(find.text(l10n.createSaveButton));
    await _pumpUntilFound(tester, find.byType(TextContentDetailScreen));
    await tester.pump(_kPageSettleDuration);
    _expectNoException(tester, 'publication d\'un contenu');
  });
}

/// Avance l'horloge jusqu'à ce que [finder] trouve un widget, ou échoue après [_kAppearTimeout].
///
/// Une page met un temps variable à apparaître (splash, chargement depuis Hive, transition) : attendre une durée
/// fixe rendrait le test fragile sur un téléphone lent.
///
/// - [tester] : testeur du widget.
/// - [finder] : widget attendu.
Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(_kAppearTimeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Introuvable après ${_kAppearTimeout.inSeconds} s : $finder');
}

/// Vérifie qu'aucune erreur n'a été levée pendant la construction de la page.
///
/// - [tester] : testeur du widget.
/// - [step] : étape en cours, rappelée dans le message d'échec.
void _expectNoException(WidgetTester tester, String step) {
  expect(tester.takeException(), isNull, reason: 'erreur pendant : $step');
}
