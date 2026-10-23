import 'package:bedbug/features/signature/domain/entities/signature.dart';

/// Identifiant de la signature de l'utilisateur du téléphone.
///
/// Identique à l'`authorId` attribué aux contenus créés localement, pour que
/// la signature configurée dans les options s'affiche sur ces contenus.
const String localSignatureId = 'local';

/// Contrat du repository gérant les [Signature].
abstract class SignatureRepository {
  /// Retourne la signature de l'utilisateur du téléphone, ou `null` s'il ne l'a jamais configurée.
  Future<Signature?> getLocal();

  /// Retourne la signature d'identifiant [id], ou `null` si elle est inconnue de l'appareil.
  Future<Signature?> getById(String id);

  /// Retourne les signatures dont le pseudo commence par [prefix], insensible à la casse.
  ///
  /// Triées par ordre alphabétique de pseudo et limitées aux [limit] premières.
  Future<List<Signature>> getAllWithPseudoStartingWith(String prefix, {required int limit});

  /// Persiste [entity] comme signature de l'utilisateur du téléphone, en remplaçant la précédente.
  Future<Signature> saveLocal(Signature entity);

  /// Persiste [entities] en une seule opération, chacune sous son propre identifiant.
  ///
  /// Une signature déjà présente avec le même identifiant est remplacée.
  Future<void> saveMany(List<Signature> entities);
}
