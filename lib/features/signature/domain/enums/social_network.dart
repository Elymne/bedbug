/// Réseau sur lequel un utilisateur peut renvoyer vers son profil.
///
/// Sans serveur, rien ne garantit l'identité d'un auteur : un lien libre
/// pourrait pointer n'importe où (phishing). On ne stocke donc que
/// l'identifiant de l'utilisateur sur un réseau connu, vérifié selon les
/// règles de ce réseau, et l'URL est reconstruite localement à partir de
/// [urlTemplate]. C'est aussi bien plus léger à transférer qu'une URL complète.
enum SocialNetwork {
  /// YouTube : handle de 3 à 30 caractères (lettres, chiffres, `.`, `_`, `-`).
  youtube(0, 'https://www.youtube.com/@{handle}', r'^[A-Za-z0-9._-]{3,30}$'),

  /// Twitter (oui, Twitter) : 1 à 15 caractères (lettres, chiffres, `_`). Les URL `x.com` sont aussi acceptées.
  twitter(1, 'https://twitter.com/{handle}', r'^[A-Za-z0-9_]{1,15}$', alternateHosts: ['x.com']),

  /// Twitch : 4 à 25 caractères (lettres, chiffres, `_`).
  twitch(2, 'https://www.twitch.tv/{handle}', r'^[A-Za-z0-9_]{4,25}$'),

  /// DeviantArt : 3 à 20 caractères (lettres, chiffres, `-`).
  deviantArt(3, 'https://www.deviantart.com/{handle}', r'^[A-Za-z0-9-]{3,20}$'),

  /// ArtStation : 3 à 63 caractères (lettres, chiffres, `_`, `-`).
  artStation(4, 'https://www.artstation.com/{handle}', r'^[A-Za-z0-9_-]{3,63}$'),

  /// Pixiv : nom de profil `pixiv.me`, 3 à 32 caractères (lettres, chiffres, `_`, `-`).
  pixiv(5, 'https://pixiv.me/{handle}', r'^[A-Za-z0-9_-]{3,32}$'),

  /// Bluesky : handle complet sous forme de domaine (ex. `nom.bsky.social`).
  bluesky(6, 'https://bsky.app/profile/{handle}', r'^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,}$'),

  /// Ko-fi : 3 à 40 caractères (lettres, chiffres, `_`).
  kofi(7, 'https://ko-fi.com/{handle}', r'^[A-Za-z0-9_]{3,40}$'),

  /// OnlyFans : 3 à 30 caractères (lettres, chiffres, `.`, `_`, `-`).
  onlyFans(8, 'https://onlyfans.com/{handle}', r'^[A-Za-z0-9._-]{3,30}$'),

  /// GitHub : 1 à 39 caractères (lettres, chiffres, tirets isolés), ni début ni fin par un tiret.
  github(9, 'https://github.com/{handle}', r'^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$'),

  /// GitLab : 2 à 255 caractères (lettres, chiffres, `.`, `_`, `-`), sans commencer par un tiret.
  gitlab(10, 'https://gitlab.com/{handle}', r'^[A-Za-z0-9_.][A-Za-z0-9_.-]{1,254}$'),

  /// LinkedIn : identifiant d'URL publique, 3 à 100 caractères (lettres, chiffres, `-`).
  ///
  /// Proposé dans la liste, mais l'écran de profil refuse toujours de l'ajouter : c'est une blague assumée.
  linkedin(11, 'https://www.linkedin.com/in/{handle}', r'^[A-Za-z0-9-]{3,100}$');

  const SocialNetwork(this.value, this.urlTemplate, this.handlePattern, {this.alternateHosts = const []});

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Modèle d'URL du profil, où `{handle}` est remplacé par l'identifiant.
  final String urlTemplate;

  /// Expression régulière que doit respecter un identifiant sur ce réseau.
  final String handlePattern;

  /// Autres domaines acceptés quand l'utilisateur colle l'URL de son profil (ex. `x.com` pour Twitter).
  final List<String> alternateHosts;

  /// Domaine du réseau, sans `www.` (ex. `twitch.tv`).
  String get host {
    return _stripHostPrefix(_templateParts.first);
  }

  /// Début de l'URL du profil, sans le schéma, tel qu'affiché devant l'identifiant (ex. `youtube.com/@`, `linkedin.com/in/`).
  String get displayPrefix {
    final segments = _templateParts.skip(1).toList();
    final leadingSegments = segments.take(_handleSegmentIndex).map((segment) => '$segment/').join();
    return '$host/$leadingSegments$_handlePrefix';
  }

  /// Retourne l'URL du profil correspondant à [handle] sur ce réseau.
  ///
  /// - [handle] : identifiant de l'utilisateur sur ce réseau, déjà normalisé.
  String profileUrl(String handle) {
    return urlTemplate.replaceFirst('{handle}', Uri.encodeComponent(handle));
  }

  /// Retourne l'identifiant normalisé tiré de [input], ou `null` s'il n'est pas valide sur ce réseau.
  ///
  /// L'utilisateur peut taper son identifiant (avec ou sans le préfixe du
  /// réseau, comme le `@` de YouTube) ou coller l'URL complète de son profil.
  /// Une URL n'est acceptée que si elle pointe vers ce réseau : une URL
  /// Twitch collée pour GitHub est refusée. L'identifiant obtenu doit enfin
  /// respecter [handlePattern].
  ///
  /// - [input] : saisie brute de l'utilisateur.
  String? normalizeHandle(String input) {
    var handle = input.trim();
    if (handle.contains('/')) {
      final urlHandle = _handleFromUrl(handle);
      if (urlHandle == null) {
        return null;
      }
      handle = urlHandle;
    }

    if (_handlePrefix.isNotEmpty && handle.startsWith(_handlePrefix)) {
      handle = handle.substring(_handlePrefix.length);
    }
    if (!RegExp(handlePattern).hasMatch(handle)) {
      return null;
    }
    return handle;
  }

  /// Retourne le [SocialNetwork] correspondant à [value], ou `null` si inconnu.
  ///
  /// Une valeur inconnue peut provenir d'une version plus récente de l'app :
  /// le lien est alors ignoré plutôt que de faire échouer la lecture.
  static SocialNetwork? fromValue(int value) {
    for (final network in SocialNetwork.values) {
      if (network.value == value) {
        return network;
      }
    }
    return null;
  }

  /// Extrait le segment d'identifiant d'une URL collée, ou `null` si l'URL ne pointe pas vers ce réseau.
  ///
  /// L'URL doit reprendre le chemin de [urlTemplate] : `linkedin.com/in/nom`
  /// est accepté, `linkedin.com/company/nom` ne l'est pas.
  String? _handleFromUrl(String url) {
    final withoutScheme = url.replaceFirst(RegExp('^[A-Za-z]+://'), '');
    final parts = withoutScheme.split(RegExp('[?#]')).first.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return null;
    }

    final urlHost = _stripHostPrefix(parts.first.toLowerCase());
    if (urlHost != host && !alternateHosts.contains(urlHost)) {
      return null;
    }

    final segments = parts.skip(1).toList();
    final templateSegments = _templateParts.skip(1).toList();
    if (segments.length <= _handleSegmentIndex) {
      return null;
    }
    for (var index = 0; index < _handleSegmentIndex; index++) {
      if (segments[index].toLowerCase() != templateSegments[index]) {
        return null;
      }
    }
    return Uri.decodeComponent(segments[_handleSegmentIndex]);
  }

  /// Hôte puis segments de chemin de [urlTemplate], sans le schéma.
  List<String> get _templateParts {
    return urlTemplate.replaceFirst('https://', '').split('/');
  }

  /// Position, parmi les segments de chemin de [urlTemplate], de celui qui contient `{handle}`.
  int get _handleSegmentIndex {
    return _templateParts.skip(1).toList().indexWhere((segment) => segment.contains('{handle}'));
  }

  /// Texte précédant `{handle}` dans son segment (ex. `@` pour YouTube), vide le plus souvent.
  String get _handlePrefix {
    final segment = _templateParts.skip(1).elementAt(_handleSegmentIndex);
    return segment.substring(0, segment.indexOf('{handle}'));
  }

  /// Retire les préfixes d'hôte sans importance (`www.`, `m.`) pour comparer les domaines.
  String _stripHostPrefix(String hostName) {
    return hostName.replaceFirst(RegExp(r'^(www\.|m\.)'), '');
  }
}
