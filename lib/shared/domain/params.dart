/// Classe de base abstraite pour les paramètres d'un use case ou d'un
/// repository.
abstract class Params {
  /// Constructeur constant pour permettre des sous-classes constantes.
  const Params();
}

/// Paramètres vides pour les opérations ne nécessitant aucune entrée.
class NoParams extends Params {
  /// Crée des [NoParams].
  const NoParams();
}
