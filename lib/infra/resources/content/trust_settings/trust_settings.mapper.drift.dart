import 'package:bedbug/infra/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/drift.config.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:drift/drift.dart';

/// Conversion entre les [TrustSettings] et la ligne unique de la table `trust_settings_store`.
///
/// Les règles sont stockées sous leur forme saisie (`imgur.com`, `*.imgur.com`) et réanalysées à la lecture : une
/// règle stockée qui ne passerait plus les vérifications est ignorée plutôt que de faire confiance à un ancien format.
abstract final class TrustSettingsDriftMapper {
  /// Reconstruit les réglages de la ligne, sans les règles devenues invalides.
  ///
  /// Lève une [DataException] si la ligne ne peut pas être convertie.
  ///
  /// [row] : ligne lue dans la table `trust_settings_store`.
  static TrustSettings toEntity(TrustSettingsRow row) {
    try {
      return TrustSettings(
        mediaPolicy: UrlTrustPolicy(
          trustedRules: _toRules(row.mediaTrustedPatterns),
          greyRules: _toRules(row.mediaGreyPatterns),
        ),
        linkPolicy: UrlTrustPolicy(
          trustedRules: _toRules(row.linkTrustedPatterns),
          greyRules: _toRules(row.linkGreyPatterns),
        ),
      );
    } catch (error) {
      throw DataException('TrustSettingsDriftMapper', error);
    }
  }

  /// Construit la ligne unique à écrire pour des réglages, toujours sous [singleRowId].
  ///
  /// [entity] : réglages à écrire.
  static TrustSettingsStoreCompanion toCompanion(TrustSettings entity) {
    return TrustSettingsStoreCompanion.insert(
      id: const Value(singleRowId),
      mediaTrustedPatterns: _toPatterns(entity.mediaPolicy.trustedRules),
      mediaGreyPatterns: _toPatterns(entity.mediaPolicy.greyRules),
      linkTrustedPatterns: _toPatterns(entity.linkPolicy.trustedRules),
      linkGreyPatterns: _toPatterns(entity.linkPolicy.greyRules),
    );
  }

  /// Réanalyse les règles stockées, en ignorant celles qui ne sont plus valides.
  ///
  /// [patterns] : règles stockées, sous leur forme saisie.
  static List<DomainRule> _toRules(List<String> patterns) {
    return [for (final pattern in patterns) ?DomainRule.parse(pattern)];
  }

  /// Écrit les règles sous leur forme saisie.
  ///
  /// [rules] : règles à stocker.
  static List<String> _toPatterns(List<DomainRule> rules) {
    return [for (final rule in rules) DomainRule.patternOf(rule)];
  }
}
