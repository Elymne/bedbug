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

  /// Persiste [entity] comme utilisateur du téléphone, en remplaçant le précédent.
  Future<User> saveLocal(User entity);
}
