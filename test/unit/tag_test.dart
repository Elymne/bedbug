import 'package:bedbug/features/content/domain/enums/tag.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque tag a sa propre valeur : elle identifie le tag en base et chez les pairs', () {
    final values = Tag.values.map((tag) => tag.value).toSet();

    expect(values, hasLength(Tag.values.length));
  });

  test('chaque tag a son propre libellé, sans quoi le sélecteur les confondrait', () {
    final texts = Tag.values.map((tag) => tag.text).toSet();

    expect(texts, hasLength(Tag.values.length));
  });

  test('chaque tag a au moins une couleur, sans quoi il ne pourrait pas se dessiner', () {
    for (final tag in Tag.values) {
      expect(tag.colors, isNotEmpty, reason: tag.name);
    }
  });

  test('les tags déjà publiés gardent leur valeur', () {
    expect(Tag.info.value, 0);
    expect(Tag.alert.value, 1);
    expect(Tag.question.value, 2);
    expect(Tag.spoiler.value, 3);
  });
}
