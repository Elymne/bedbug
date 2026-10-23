import 'package:bedbug/features/user/domain/enums/social_network.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeHandle', () {
    test('accepte un identifiant valide, avec ou sans préfixe du réseau', () {
      expect(SocialNetwork.twitch.normalizeHandle('  bedbug_live '), 'bedbug_live');
      expect(SocialNetwork.youtube.normalizeHandle('@bedbug'), 'bedbug');
      expect(SocialNetwork.youtube.normalizeHandle('bedbug'), 'bedbug');
      expect(SocialNetwork.bluesky.normalizeHandle('bedbug.bsky.social'), 'bedbug.bsky.social');
    });

    test('refuse un identifiant hors des règles du réseau', () {
      expect(SocialNetwork.twitter.normalizeHandle('un_pseudo_beaucoup_trop_long'), isNull);
      expect(SocialNetwork.twitch.normalizeHandle('abc'), isNull);
      expect(SocialNetwork.github.normalizeHandle('-bedbug'), isNull);
      expect(SocialNetwork.github.normalizeHandle('bed--bug'), isNull);
      expect(SocialNetwork.bluesky.normalizeHandle('bedbug'), isNull);
      expect(SocialNetwork.twitch.normalizeHandle('bed bug'), isNull);
    });

    test("extrait l'identifiant d'une URL collée vers le bon réseau", () {
      expect(SocialNetwork.twitch.normalizeHandle('https://www.twitch.tv/bedbug'), 'bedbug');
      expect(SocialNetwork.youtube.normalizeHandle('youtube.com/@bedbug?si=abc'), 'bedbug');
      expect(SocialNetwork.linkedin.normalizeHandle('https://linkedin.com/in/bed-bug/'), 'bed-bug');
      expect(SocialNetwork.twitter.normalizeHandle('https://x.com/bedbug'), 'bedbug');
      expect(
        SocialNetwork.bluesky.normalizeHandle('https://bsky.app/profile/bedbug.bsky.social'),
        'bedbug.bsky.social',
      );
    });

    test("refuse une URL d'un autre site ou d'une autre page du réseau", () {
      expect(SocialNetwork.github.normalizeHandle('https://www.twitch.tv/bedbug'), isNull);
      expect(SocialNetwork.linkedin.normalizeHandle('https://www.linkedin.com/company/bedbug'), isNull);
      expect(SocialNetwork.twitch.normalizeHandle('https://evil.example/twitch.tv/bedbug'), isNull);
    });
  });

  test('displayPrefix montre le début de l\'URL construite', () {
    expect(SocialNetwork.twitch.displayPrefix, 'twitch.tv/');
    expect(SocialNetwork.youtube.displayPrefix, 'youtube.com/@');
    expect(SocialNetwork.linkedin.displayPrefix, 'linkedin.com/in/');
    expect(SocialNetwork.bluesky.displayPrefix, 'bsky.app/profile/');
  });
}
