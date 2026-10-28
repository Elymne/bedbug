import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/content/domain/object_values/url_trust_policy.dart';
import 'package:bedbug/features/content/domain/services/domain_rule_service.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'trust_settings_hive_model.g.dart';

/// DTO Hive représentant les [TrustSettings] persistés localement.
///
/// Les règles sont stockées sous leur forme saisie (`imgur.com`,
/// `*.imgur.com`) et réanalysées à la lecture : une règle stockée qui ne
/// passerait plus les vérifications est ignorée plutôt que de faire
/// confiance à un ancien format.
@HiveType(typeId: HiveTypeIds.trustSettings)
class TrustSettingsHiveModel extends HiveObject {
  /// Crée un [TrustSettingsHiveModel].
  ///
  /// - [mediaTrustedPatterns] : règles de la whitelist des médias.
  /// - [mediaGreyPatterns] : règles de la greylist des médias.
  /// - [linkTrustedPatterns] : règles de la whitelist des liens.
  /// - [linkGreyPatterns] : règles de la greylist des liens.
  /// - [unknownDomainBehavior] : valeur de [UnknownDomainBehavior].
  TrustSettingsHiveModel({
    required this.mediaTrustedPatterns,
    required this.mediaGreyPatterns,
    required this.linkTrustedPatterns,
    required this.linkGreyPatterns,
    required this.unknownDomainBehavior,
  });

  /// Crée un [TrustSettingsHiveModel] depuis des [TrustSettings].
  ///
  /// - [entity] : réglages à stocker.
  /// - [domainRuleService] : service qui écrit chaque règle sous sa forme saisie.
  factory TrustSettingsHiveModel.fromEntity(TrustSettings entity, DomainRuleService domainRuleService) {
    return TrustSettingsHiveModel(
      mediaTrustedPatterns: [for (final rule in entity.mediaPolicy.trustedRules) domainRuleService.patternOf(rule)],
      mediaGreyPatterns: [for (final rule in entity.mediaPolicy.greyRules) domainRuleService.patternOf(rule)],
      linkTrustedPatterns: [for (final rule in entity.linkPolicy.trustedRules) domainRuleService.patternOf(rule)],
      linkGreyPatterns: [for (final rule in entity.linkPolicy.greyRules) domainRuleService.patternOf(rule)],
      unknownDomainBehavior: entity.unknownDomainBehavior.value,
    );
  }

  /// Règles de la whitelist des médias.
  @HiveField(0, defaultValue: <String>[])
  final List<String> mediaTrustedPatterns;

  /// Règles de la greylist des médias.
  @HiveField(1, defaultValue: <String>[])
  final List<String> mediaGreyPatterns;

  /// Règles de la whitelist des liens.
  @HiveField(2, defaultValue: <String>[])
  final List<String> linkTrustedPatterns;

  /// Règles de la greylist des liens.
  @HiveField(3, defaultValue: <String>[])
  final List<String> linkGreyPatterns;

  /// Sort des domaines inconnus, valeur de [UnknownDomainBehavior].
  @HiveField(4, defaultValue: 0)
  final int unknownDomainBehavior;

  /// Convertit ce modèle en [TrustSettings].
  ///
  /// - [domainRuleService] : service qui réanalyse chaque règle stockée.
  TrustSettings toEntity(DomainRuleService domainRuleService) {
    try {
      return TrustSettings(
        mediaPolicy: UrlTrustPolicy(
          trustedRules: _toRules(mediaTrustedPatterns, domainRuleService),
          greyRules: _toRules(mediaGreyPatterns, domainRuleService),
        ),
        linkPolicy: UrlTrustPolicy(
          trustedRules: _toRules(linkTrustedPatterns, domainRuleService),
          greyRules: _toRules(linkGreyPatterns, domainRuleService),
        ),
        unknownDomainBehavior: UnknownDomainBehavior.fromValue(unknownDomainBehavior),
      );
    } catch (error) {
      throw DataException('TrustSettingsHiveModel', error);
    }
  }

  /// Réanalyse les règles stockées, en ignorant celles qui ne sont plus valides.
  ///
  /// - [patterns] : règles stockées, sous leur forme saisie.
  /// - [domainRuleService] : service qui réanalyse chaque règle.
  List<DomainRule> _toRules(List<String> patterns, DomainRuleService domainRuleService) {
    return [for (final pattern in patterns) ?domainRuleService.parse(pattern)];
  }
}
