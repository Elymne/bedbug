import 'package:bedbug/application/screens/avatar_picker/kaomoji_catalog.dart';
import 'package:bedbug/features/signature/domain/extensions/signature_text_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidPseudo', () {
    test('accepte lettres et tirets', () {
      expect('bedbug'.isValidPseudo, isTrue);
      expect('Bed-Bug'.isValidPseudo, isTrue);
    });

    test('refuse espaces, chiffres, accents, symboles et underscore', () {
      for (final pseudo in ['bed bug', 'bedbug42', 'éléphant', 'bed!bug', 'bed_bug', 'bed.bug']) {
        expect(pseudo.isValidPseudo, isFalse, reason: pseudo);
      }
    });

    test('refuse un pseudo trop court ou trop long', () {
      expect('ab'.isValidPseudo, isFalse);
      expect(('a' * (maxPseudoLength + 1)).isValidPseudo, isFalse);
    });
  });

  group('isValidAvatarText', () {
    test('accepte les émotes, emojis et lettres isolées', () {
      for (final avatar in ['(◕‿◕)', 'ʕ•ᴥ•ʔ', '(T_T)', 'ヽ(`Д´)ﾉ', '😀', '(-.-)Zzz']) {
        expect(avatar.isValidAvatarText, isTrue, reason: avatar);
      }
    });

    test('refuse les mots, en latin, accentués, pleine chasse ou cyrillique', () {
      for (final avatar in ['lol', '(◕‿◕) salut', 'été', 'ｌｏｌ', 'привет']) {
        expect(avatar.isValidAvatarText, isFalse, reason: avatar);
      }
    });

    test('refuse une icône vide', () {
      expect('   '.isValidAvatarText, isFalse);
    });

    test('accepte toutes les entrées du catalogue de kaomojis', () {
      for (final kaomoji in kaomojiCatalog.values.expand((kaomojis) => kaomojis)) {
        expect(kaomoji.isValidAvatarText, isTrue, reason: kaomoji);
      }
    });
  });
}
