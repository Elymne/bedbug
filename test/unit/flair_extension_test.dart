import 'package:bedbug/features/content/domain/extensions/flair_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toFlair', () {
    test('retire le préfixe f/ ou /, les espaces et la casse', () {
      for (final input in ['france', ' France ', '/france', '//France', 'f/france', 'F/France', 'f//france']) {
        expect(input.toFlair(), 'france', reason: input);
      }
    });

    test('ne touche pas à un flair qui commence par f sans être préfixé', () {
      expect('fromage'.toFlair(), 'fromage');
      expect('f'.toFlair(), 'f');
    });

    test('retourne null quand il ne reste rien', () {
      for (final input in ['', '  ', '/', 'f/', ' f// ']) {
        expect(input.toFlair(), isNull, reason: input);
      }
    });
  });
}
