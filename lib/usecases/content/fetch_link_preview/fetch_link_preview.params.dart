import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/usecases/content/fetch_link_preview/fetch_link_preview.usecase.dart';

/// Paramètres du [FetchLinkPreviewUsecase].
class FetchLinkPreviewParams extends Params {
  /// Crée des [FetchLinkPreviewParams].
  ///
  /// - [rawUrl] : adresse du lien, telle que saisie.
  /// - [policy] : politique de confiance des liens de l'utilisateur.
  const FetchLinkPreviewParams({required this.rawUrl, required this.policy});

  /// Adresse du lien, telle que saisie.
  final String rawUrl;

  /// Politique de confiance des liens de l'utilisateur.
  final UrlTrustPolicy policy;
}
