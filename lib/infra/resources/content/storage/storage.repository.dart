import 'package:bedbug/infra/resources/content/storage/storage.value_object.dart';

/// Contrat du repository gérant la configuration [Storage] et le poids réel des données.
///
/// La configuration est unique, toujours remplacée en entier. Le poids utilisé, lui, n'est jamais stocké : il est
/// mesuré sur le stockage lui-même, ce qui le garde juste quoi qu'il arrive (crash, écriture oubliée).
abstract class StorageRepository {
  /// Retourne la configuration de stockage persistée, ou `null` si elle n'a jamais été enregistrée.
  Future<Storage?> get();

  /// Enregistre [storage], à la place de la configuration précédente.
  ///
  /// - [storage] : configuration à enregistrer.
  Future<void> save(Storage storage);

  /// Retourne le poids réellement occupé par les données de l'app, en octets.
  ///
  /// Compte tout ce qui est écrit (contenus, réactions, signatures, index, journaux), sans la place libérée par les
  /// suppressions.
  Future<int> getUsedSizeInBytes();

  /// Rend au système la place libérée par les dernières suppressions.
  ///
  /// À appeler après une suppression massive, pour que le fichier rétrécisse vraiment.
  Future<void> releaseFreePages();
}
