/// Icône texte d'une signature dont l'auteur n'en a pas encore choisi.
const String defaultSignatureAvatarText = '(◕‿◕)';

/// Vitesse minimale de l'effet ghost (multiplicateur de la vitesse normale).
///
/// Strictement positive : une vitesse nulle figerait l'animation sur une
/// durée infinie.
const double minGhostSpeed = 0.25;

/// Vitesse maximale de l'effet ghost (multiplicateur de la vitesse normale).
///
/// Au-delà, le tremblement devient un scintillement pénible à regarder.
const double maxGhostSpeed = 5;

/// Vitesse de l'effet ghost d'une signature dont l'auteur ne l'a pas réglée.
const double defaultGhostSpeed = 1;

/// Longueur maximale, en caractères, de la description d'une signature.
///
/// La description est une phrase pour se présenter, pas une biographie : elle
/// voyage avec la signature de pair à pair et doit rester légère.
const int maxSignatureBioLength = 250;

/// Identifiant de signature porté par les contenus publiés anonymement.
const String anonymousSignatureId = 'anonymous';

/// Identifiant de la signature de l'utilisateur du téléphone.
///
/// Identique au `signatureId` attribué aux contenus créés localement, pour que
/// la signature configurée dans les options s'affiche sur ces contenus.
const String localSignatureId = 'local';

/// Longueur minimale d'un pseudo.
const int minPseudoLength = 3;

/// Longueur maximale d'un pseudo.
const int maxPseudoLength = 24;
