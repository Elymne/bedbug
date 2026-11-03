/// Police dans laquelle un auteur choisit d'afficher un texte court : la bulle d'une réaction, la description d'une signature.
///
/// Comme la couleur et l'intensité du ghost, c'est une façon de donner du
/// style à ce qu'on écrit. Seule la valeur est stockée et transmise, jamais la
/// police elle-même : chaque appareil embarque les mêmes polices, ce qui garde
/// le texte léger à transférer de pair à pair, et l'app utilisable sans
/// connexion.
enum TextFont {
  /// Police par défaut de l'application.
  standard(0),

  /// Snowburst One : lettres faites de flocons.
  snowburstOne(1),

  /// Crafty Girls : écriture manuscrite ronde.
  craftyGirls(2),

  /// Molle : script italique épais.
  molle(3),

  /// Audiowide : lettres futuristes arrondies.
  audiowide(4),

  /// Silkscreen : pixels.
  silkscreen(5),

  /// Gugi : capitales géométriques.
  gugi(6),

  /// Eater : lettres dégoulinantes d'horreur.
  eater(7),

  /// Kablammo : lettres de bande dessinée qui tressautent.
  kablammo(8),

  /// Rock Salt : marqueur griffonné.
  rockSalt(9),

  /// Lakki Reddy : calligraphie décorative.
  lakkiReddy(10);

  const TextFont(this.value);

  /// Valeur entière persistée. Stable indépendamment de l'ordre de déclaration.
  final int value;

  /// Retourne la [TextFont] correspondant à [value], ou [standard] si elle est inconnue.
  ///
  /// Une valeur inconnue peut provenir d'une version plus récente de l'app :
  /// le texte reste alors lisible dans la police par défaut plutôt que de
  /// faire échouer la lecture.
  ///
  /// - [value] : valeur entière persistée.
  static TextFont fromValue(int value) {
    for (final font in TextFont.values) {
      if (font.value == value) {
        return font;
      }
    }
    return standard;
  }
}
