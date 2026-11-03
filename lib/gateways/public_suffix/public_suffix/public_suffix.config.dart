/// Chemin de la Public Suffix List embarquée dans l'application.
///
/// Embarquée plutôt que téléchargée : l'app doit fonctionner sans connexion.
/// Mise à jour par `dart run tool/update_public_suffix_list.dart`, lancé chaque semaine par un workflow.
const String publicSuffixListAssetPath = 'assets/data/public_suffix_list.dat';
