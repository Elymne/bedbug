/// Icônes de l'application, dessinées pour elle : grille de 24, traits arrondis de 2, aucun remplissage.
///
/// Chaque valeur correspond au fichier `assets/icons/<nom>.svg`. Pour ajouter une
/// icône, déposer son SVG dans ce dossier et déclarer ici une valeur du même nom.
/// À afficher avec `AppIcon`.
enum AppIcons {
  /// Plus.
  add,

  /// Plus dans un cercle.
  addCircle,

  /// Flèche de retour.
  arrowBack(isDirectional: true),

  /// Page de texte.
  article,

  /// Bluetooth.
  bluetooth,

  /// Trame de points, pour ce qui est flouté.
  blur,

  /// Image déchirée.
  brokenImage,

  /// Pinceau.
  brush,

  /// Insecte.
  bug,

  /// Croix dans un cercle.
  cancel,

  /// Coche.
  check,

  /// Coche dans un cercle.
  checkCircle,

  /// Chevron vers la droite.
  chevronRight(isDirectional: true),

  /// Croix.
  close,

  /// Pile de photos.
  collections,

  /// Corbeille.
  delete,

  /// Corbeille et lignes, pour tout effacer.
  deleteAll,

  /// Téléchargement.
  download,

  /// Crayon.
  edit,

  /// Lignes de texte et crayon.
  editNote,

  /// Gomme.
  eraser,

  /// Chevron vers le bas.
  expandMore,

  /// Œil ouvert.
  eye,

  /// Œil barré.
  eyeOff,

  /// Pipette.
  eyedropper,

  /// Pot de peinture.
  fill,

  /// Quatre coins, pour ajuster à l'écran.
  fitScreen,

  /// Globe.
  globe,

  /// Grille de quatre cases.
  grid,

  /// Maison.
  home,

  /// Image.
  image,

  /// Rectangle horizontal.
  landscape,

  /// Pile de calques.
  layers,

  /// Maillons de chaîne.
  link,

  /// Dossiers empilés.
  media,

  /// Lignes de texte.
  notes,

  /// Palette de peintre.
  palette,

  /// Stylo et trait dessiné.
  pen,

  /// Silhouette.
  person,

  /// Triangle de lecture.
  play,

  /// Triangle de lecture dans un cercle.
  playCircle,

  /// Rectangle vertical.
  portrait,

  /// Visage et plus.
  reaction,

  /// Flèche de rétablissement.
  redo(isDirectional: true),

  /// Horloge et flèche de retour en arrière.
  restore,

  /// Loupe.
  search,

  /// Curseurs de réglage.
  settings,

  /// Bouclier.
  shield,

  /// Cylindre de stockage.
  storage,

  /// Flèches haut et bas.
  swapVertical,

  /// Caractères à traduire.
  translate,

  /// Flèche d'annulation.
  undo(isDirectional: true),

  /// Badge coché.
  verified,

  /// Caméra barrée.
  videoOff,

  /// Wi-Fi barré.
  wifiOff,

  /// Loupe et plus.
  zoomIn;

  /// Crée une valeur de [AppIcons].
  ///
  /// - [isDirectional] : `true` si l'icône indique un sens, à retourner dans une langue écrite de droite à gauche.
  const AppIcons({this.isDirectional = false});

  /// Indique si l'icône indique un sens, à retourner dans une langue écrite de droite à gauche.
  final bool isDirectional;

  /// Chemin du fichier SVG de l'icône.
  String get assetPath {
    return 'assets/icons/$name.svg';
  }
}
