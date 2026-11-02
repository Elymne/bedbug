/// Classe abstraite de base pour tous les services du domaine.
///
/// Les entités et les value objects ne portent que des données : aucune
/// règle de parsing, de validation ou de comparaison ne vit dedans. Mélanger
/// données et comportement rend les objets du domaine difficiles à lire et
/// cache les règles métier là où personne ne pense à les chercher.
///
/// Un service regroupe les petites briques de logique pure réutilisées par
/// plusieurs use cases, ou par l'application (analyser une adresse, vérifier
/// qu'un domaine est couvert par une règle, reconnaître un format). Une
/// logique qui ne sert qu'à un seul use case reste une fonction privée de ce
/// use case.
///
/// Un service est synchrone, sans accès aux données (pas de repository, pas
/// de gateway) : il ne dépend que d'autres services. Il ne lève jamais
/// d'exception et n'en attrape pas non plus : il s'appuie sur les API qui
/// n'en lèvent pas (`Uri.tryParse`, `int.tryParse`). C'est ce qui lui
/// permet de ne pas retourner d'`Either`, contrairement à un use case : un
/// échec s'exprime simplement par `null` ou par une valeur d'enum. Ce qui
/// demande un accès extérieur relève d'un use case.
abstract class Service {
  /// Constructeur constant pour permettre des sous-classes constantes.
  const Service();
}
