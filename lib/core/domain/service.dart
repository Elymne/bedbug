import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/params.dart';

/// Contrat de base pour tous les services du domaine : des « sous use cases » réutilisables.
///
/// Quand plusieurs use cases enchaînent la même suite d'opérations (supprimer un contenu et tout ce qui s'y rattache,
/// intégrer une réaction en respectant ses plafonds), cette suite devient un service : elle est écrite une seule fois,
/// et chaque use case l'appelle au lieu de la recopier.
///
/// Un service a la même forme qu'un use case : une seule opération, asynchrone, qui ne lève jamais et retourne un
/// [Either] avec un échec typé. Il peut dépendre de repositories, de gateways et d'autres services, mais jamais d'un
/// use case. Seuls les use cases appellent les services : l'application n'appelle que des use cases.
///
/// [P] est le type des paramètres, doit étendre [Params].
/// [F] est le type de l'échec retourné en cas d'erreur (Left).
/// [V] est le type de la valeur retournée en cas de succès (Right).
abstract class Service<P extends Params, F, V> {
  /// Exécute le service avec les [params] fournis.
  ///
  /// Retourne un [Either] contenant soit un échec [F] (Left),
  /// soit la valeur de succès [V] (Right).
  Future<Either<F, V>> call(P params);
}
