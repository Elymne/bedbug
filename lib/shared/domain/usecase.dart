import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';

/// Contrat de base pour tous les use cases de l'application.
///
/// [P] est le type des paramètres, doit étendre [Params].
/// [V] est le type de la valeur retournée en cas de succès.
abstract class Usecase<P extends Params, V, F> {
  /// Exécute le use case avec les [params] fournis.
  ///
  /// Retourne un [Either] contenant soit une erreur (Left), soit la valeur
  /// [V] (Right).
  Future<Either<F, V>> perform(P params);
}
