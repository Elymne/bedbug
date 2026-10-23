import 'package:bedbug/features/user/domain/entities/user.dart';

/// Identifiant de l'utilisateur du téléphone.
///
/// Identique à l'`authorId` attribué aux contenus créés localement, pour que
/// le profil configuré corresponde à l'auteur de ces contenus.
const String localUserId = 'local';

/// Contrat du repository gérant les utilisateurs.
abstract class UserRepository {
  /// Retourne l'utilisateur du téléphone, ou `null` s'il n'a jamais configuré son profil.
  Future<User?> getLocal();

  /// Retourne l'utilisateur d'identifiant [id], ou `null` s'il est inconnu de l'appareil.
  Future<User?> getById(String id);

  /// Retourne les utilisateurs dont le pseudo commence par [prefix], insensible à la casse.
  ///
  /// Triés par ordre alphabétique de pseudo et limités aux [limit] premiers.
  Future<List<User>> getAllWithPseudoStartingWith(String prefix, {required int limit});

  /// Persiste [entity] comme utilisateur du téléphone, en remplaçant le précédent.
  Future<User> saveLocal(User entity);

  /// Persiste [entities] en une seule opération, chacun sous son propre identifiant.
  ///
  /// Un utilisateur déjà présent avec le même identifiant est remplacé.
  Future<void> saveMany(List<User> entities);
}
