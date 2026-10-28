import 'dart:io';

import 'package:bedbug/features/content/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/content/domain/services/domain_rule_service.dart';
import 'package:bedbug/features/content/domain/services/url_safety_service.dart';
import 'package:bedbug/features/content/domain/usecases/parse_domain_rule_usecase.dart';
import 'package:bedbug/features/content/infrastructure/gateways/public_suffix_package_public_suffix_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // La vraie liste embarquée, lue depuis le disque : c'est elle que l'app utilise.
  final gateway = PublicSuffixPackagePublicSuffixGateway(() => File(publicSuffixListAssetPath).readAsString());
  const urlSafetyService = UrlSafetyService();
  const domainRuleService = DomainRuleService(urlSafetyService);
  final usecase = ParseDomainRuleUsecase(gateway, urlSafetyService, domainRuleService);

  /// Analyse [input] avec le use case.
  Future<(ParseDomainRuleFailure?, DomainRule?)> parse(String input) async {
    final result = await usecase(ParseDomainRuleParams(input: input));
    return (result.left, result.right);
  }

  test('accepte les règles sur un domaine ordinaire, ou un sous-domaine de suffixe privé', () async {
    for (final input in ['imgur.com', '*.imgur.com', 'i.imgur.com', 'bbc.co.uk', '*.bbc.co.uk', 'user.github.io']) {
      final (failure, rule) = await parse(input);
      expect(failure, isNull, reason: input);
      expect(rule, isNotNull, reason: input);
    }
  });

  test('nettoie les espaces autour et met en minuscules', () async {
    expect((await parse('  I.Imgur.COM \n')).$2, const DomainRule(host: 'i.imgur.com', isIncludingSubdomains: false));
  });

  test("d'une URL collée, ne garde que le domaine exact", () async {
    expect(
      (await parse('https://media.giphy.com/media/xyz/giphy.gif')).$2,
      const DomainRule(host: 'media.giphy.com', isIncludingSubdomains: false),
    );
    expect((await parse('http://media.giphy.com/x.gif')).$1, ParseDomainRuleFailure.invalidFormat);
  });

  test('refuse les suffixes publics officiels et privés', () async {
    for (final input in [
      'co.uk',
      '*.co.uk',
      'com.au',
      'github.io',
      '*.github.io',
      'blogspot.com',
      '*.blogspot.com',
      'herokuapp.com',
      'appspot.com',
      's3.amazonaws.com',
    ]) {
      final (failure, _) = await parse(input);
      expect(failure, ParseDomainRuleFailure.publicSuffix, reason: input);
    }
  });

  test('applique les règles génériques et les exceptions de la liste', () async {
    // `*.ck` : tout domaine directement sous `ck` est un suffixe public…
    expect((await parse('anything.ck')).$1, ParseDomainRuleFailure.publicSuffix);
    // … sauf l'exception `!www.ck`.
    expect((await parse('www.ck')).$1, isNull);
  });

  test("une extension inconnue n'est pas un suffixe public en soi : le domaine dessous est acceptable", () async {
    expect((await parse('example.zzzunknown')).$1, isNull);
  });

  test('refuse les saisies mal formées avant même de consulter la liste', () async {
    for (final input in ['', 'com', '*.com', 'https://i.imgur.com@evil.com', 'іmgur.com']) {
      expect((await parse(input)).$1, ParseDomainRuleFailure.invalidFormat, reason: Uri.encodeFull(input));
    }
  });

  test('une liste illisible fait refuser la règle plutôt que de laisser passer', () async {
    final brokenGateway = PublicSuffixPackagePublicSuffixGateway(() => Future<String>.error(Exception('illisible')));
    final result = await ParseDomainRuleUsecase(brokenGateway, urlSafetyService, domainRuleService)(
      const ParseDomainRuleParams(input: 'imgur.com'),
    );
    expect(result.left, ParseDomainRuleFailure.publicSuffix);
  });
}
