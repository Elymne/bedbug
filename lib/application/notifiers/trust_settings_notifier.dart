import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/screens/home/home_feed_notifier.dart';
import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/services/trust_rules_service.dart';
import 'package:bedbug/features/content/domain/usecases/delete_untrusted_contents_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/get_trust_settings_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/parse_domain_rule_usecase.dart';
import 'package:bedbug/features/content/domain/usecases/save_trust_settings_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [TrustSettingsNotifier].
final trustSettingsNotifierProvider = AsyncNotifierProvider<TrustSettingsNotifier, TrustSettings>(
  TrustSettingsNotifier.new,
);

/// Notifier portant les réglages de confiance de l'utilisateur : qui décide de ce que le téléphone peut contacter.
///
/// Partagé par tout ce qui affiche un média ou un lien, et par la section
/// des réglages qui les modifie : une modification s'applique aussitôt à
/// tout le fil. Les méthodes de modification retournent `null` en cas de
/// succès, ou le message d'erreur à afficher.
class TrustSettingsNotifier extends AsyncNotifier<TrustSettings> {
  /// Cas d'usage de lecture des réglages de confiance.
  late final _getTrustSettingsUsecase = ref.read(getTrustSettingsUsecaseProvider);

  /// Cas d'usage d'enregistrement des réglages de confiance.
  late final _saveTrustSettingsUsecase = ref.read(saveTrustSettingsUsecaseProvider);

  /// Cas d'usage de vérification d'une règle saisie.
  late final _parseDomainRuleUsecase = ref.read(parseDomainRuleUsecaseProvider);

  /// Service de rangement des règles dans les listes.
  late final _trustRulesService = ref.read(trustRulesServiceProvider);

  /// Cas d'usage de suppression des contenus de domaines absents des listes.
  late final _deleteUntrustedContentsUsecase = ref.read(deleteUntrustedContentsUsecaseProvider);

  @override
  Future<TrustSettings> build() async {
    final result = await _getTrustSettingsUsecase(const NoParams());
    // Des réglages illisibles ne doivent pas tout ouvrir : les réglages par défaut prennent le relais.
    return result.right ?? defaultTrustSettings;
  }

  /// Vérifie la saisie [input] et range la règle obtenue dans la liste [level] de [family].
  ///
  /// - [family] : famille d'URLs concernée.
  /// - [level] : liste de destination.
  /// - [input] : saisie de l'utilisateur (domaine, `*.domaine` ou URL).
  Future<String?> addRule({required UrlFamily family, required TrustLevel level, required String input}) async {
    final result = await _parseDomainRuleUsecase(ParseDomainRuleParams(input: input));
    final rule = result.right;
    if (rule == null) {
      return switch (result.left!) {
        ParseDomainRuleFailure.invalidFormat => ref.l10n.trustRuleInvalidError,
        ParseDomainRuleFailure.publicSuffix => ref.l10n.trustRulePublicSuffixError,
        ParseDomainRuleFailure.unknown => ref.l10n.settingsSaveError,
      };
    }
    return _save(_trustRulesService.withRule(_current, family, level, rule));
  }

  /// Retire [rule] des listes de [family].
  ///
  /// - [family] : famille d'URLs concernée.
  /// - [rule] : règle à retirer.
  Future<String?> removeRule({required UrlFamily family, required DomainRule rule}) {
    return _save(_trustRulesService.withoutRule(_current, family, rule));
  }

  /// Revient aux listes par défaut.
  Future<String?> resetToDefaults() {
    return _save(null);
  }

  /// Réglages actuels, ou réglages par défaut s'ils ne sont pas encore chargés.
  TrustSettings get _current {
    return state.value ?? defaultTrustSettings;
  }

  /// Enregistre [settings] (`null` pour les réglages par défaut) et les applique aussitôt.
  ///
  /// Un domaine retiré des listes emporte ses contenus : ils sont supprimés ici, et le fil rechargé s'il y en a eu.
  /// L'échec de cette suppression n'est pas celui de l'enregistrement : elle sera retentée au prochain démarrage.
  Future<String?> _save(TrustSettings? settings) async {
    final result = await _saveTrustSettingsUsecase(SaveTrustSettingsParams(settings: settings));
    final saved = result.right;
    if (saved == null) {
      return ref.l10n.settingsSaveError;
    }
    state = AsyncData(saved);
    final deletedContents = (await _deleteUntrustedContentsUsecase(const NoParams())).right ?? 0;
    if (deletedContents > 0) {
      ref.invalidate(homeFeedNotifierProvider);
    }
    return null;
  }
}
