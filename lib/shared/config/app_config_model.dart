/// Modèle de configuration de l'application chargé depuis un fichier JSON d'assets.
class AppConfigModel {
  /// Crée un [AppConfigModel] avec les champs de configuration Firebase.
  /// Vide pour l'instant.
  AppConfigModel();

  /// Désérialise un [AppConfigModel] depuis un [Map] JSON.
  ///
  /// - [json] : map décodée depuis le fichier de configuration.
  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel();
  }
}
