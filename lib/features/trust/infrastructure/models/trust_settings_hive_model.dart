import 'package:bedbug/features/trust/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/trust/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/trust/domain/object_values/url_trust_policy.dart';
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
  factory TrustSettingsHiveModel.fromEntity(TrustSettings entity) {
    return TrustSettingsHiveModel(
      mediaTrustedPatterns: [for (final rule in entity.mediaPolicy.trustedRules) rule.pattern],
      mediaGreyPatterns: [for (final rule in entity.mediaPolicy.greyRules) rule.pattern],
      linkTrustedPatterns: [for (final rule in entity.linkPolicy.trustedRules) rule.pattern],
      linkGreyPatterns: [for (final rule in entity.linkPolicy.greyRules) rule.pattern],
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
  TrustSettings toEntity() {
    try {
      return TrustSettings(
        mediaPolicy: UrlTrustPolicy(
          trustedRules: _toRules(mediaTrustedPatterns),
          greyRules: _toRules(mediaGreyPatterns),
        ),
        linkPolicy: UrlTrustPolicy(trustedRules: _toRules(linkTrustedPatterns), greyRules: _toRules(linkGreyPatterns)),
        unknownDomainBehavior: UnknownDomainBehavior.fromValue(unknownDomainBehavior),
      );
    } catch (error) {
      throw DataException('TrustSettingsHiveModel', error);
    }
  }

  /// Réanalyse les règles stockées, en ignorant celles qui ne sont plus valides.
  List<DomainRule> _toRules(List<String> patterns) {
    return [for (final pattern in patterns) ?DomainRule.tryParse(pattern)];
  }
}
