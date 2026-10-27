import 'dart:io';

import 'package:bedbug/features/trust/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/trust/domain/usecases/parse_domain_rule_usecase.dart';
import 'package:bedbug/features/trust/infrastructure/gateways/public_suffix_package_public_suffix_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // La vraie liste embarquée, lue depuis le disque : c'est elle que l'app utilise.
  final gateway = PublicSuffixPackagePublicSuffixGateway(() => File(publicSuffixListAssetPath).readAsString());
  final usecase = ParseDomainRuleUsecase(gateway);

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
    final result = await ParseDomainRuleUsecase(brokenGateway)(const ParseDomainRuleParams(input: 'imgur.com'));
    expect(result.left, ParseDomainRuleFailure.publicSuffix);
  });
}
