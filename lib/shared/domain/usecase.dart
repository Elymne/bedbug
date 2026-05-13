import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';

/// Contrat de base pour tous les use cases de l'application.
///
/// [P] est le type des paramètres, doit étendre [Params].
/// [F] est le type de l'échec retourné en cas d'erreur (Left).
/// [V] est le type de la valeur retournée en cas de succès (Right).
abstract class Usecase<P extends Params, F, V> {
  /// Exécute le use case avec les [params] fournis.
  ///
  /// Retourne un [Either] contenant soit un échec [F] (Left),
  /// soit la valeur de succès [V] (Right).
  Future<Either<F, V>> call(P params);
}
