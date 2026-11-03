import 'package:bedbug/application/screens/avatar_picker/kaomoji_catalog.dart';
import 'package:bedbug/resources/signature/signature/signature.config.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidPseudo', () {
    test('accepte lettres et tirets', () {
      expect(Signature.isValidPseudo('bedbug'), isTrue);
      expect(Signature.isValidPseudo('Bed-Bug'), isTrue);
    });

    test('refuse espaces, chiffres, accents, symboles et underscore', () {
      for (final pseudo in ['bed bug', 'bedbug42', 'éléphant', 'bed!bug', 'bed_bug', 'bed.bug']) {
        expect(Signature.isValidPseudo(pseudo), isFalse, reason: pseudo);
      }
    });

    test('refuse un pseudo trop court ou trop long', () {
      expect(Signature.isValidPseudo('ab'), isFalse);
      expect(Signature.isValidPseudo('a' * (maxPseudoLength + 1)), isFalse);
    });
  });

  group('isValidAvatarText', () {
    test('accepte les émotes, emojis et lettres isolées', () {
      for (final avatar in ['(◕‿◕)', 'ʕ•ᴥ•ʔ', '(T_T)', 'ヽ(`Д´)ﾉ', '😀', '(-.-)Zzz']) {
        expect(Signature.isValidAvatarText(avatar), isTrue, reason: avatar);
      }
    });

    test('refuse les mots, en latin, accentués, pleine chasse ou cyrillique', () {
      for (final avatar in ['lol', '(◕‿◕) salut', 'été', 'ｌｏｌ', 'привет']) {
        expect(Signature.isValidAvatarText(avatar), isFalse, reason: avatar);
      }
    });

    test('refuse une icône vide', () {
      expect(Signature.isValidAvatarText('   '), isFalse);
    });

    test('accepte toutes les entrées du catalogue de kaomojis', () {
      for (final kaomoji in kaomojiCatalog.values.expand((kaomojis) => kaomojis)) {
        expect(Signature.isValidAvatarText(kaomoji), isTrue, reason: kaomoji);
      }
    });
  });
}
