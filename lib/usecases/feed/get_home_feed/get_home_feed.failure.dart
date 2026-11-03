import 'package:bedbug/usecases/feed/get_home_feed/get_home_feed.usecase.dart';

/// Échecs possibles du [GetHomeFeedUsecase].
enum GetHomeFeedFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la récupération des contenus.
  unknown,
}
