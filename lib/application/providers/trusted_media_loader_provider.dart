import 'dart:typed_data';

import 'package:bedbug/application/notifiers/trust_settings_notifier.dart';
import 'package:bedbug/features/trust/domain/object_values/trust_settings.dart';
import 'package:bedbug/features/trust/domain/usecases/fetch_media_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [TrustedMediaLoader].
final trustedMediaLoaderProvider = Provider<TrustedMediaLoader>((ref) {
  return TrustedMediaLoader(ref.read(fetchMediaUsecaseProvider), () => ref.read(trustSettingsNotifierProvider.future));
});

/// Télécharge le contenu d'une image ou d'un gif distant, selon les réglages de confiance du moment.
///
/// Sert de source aux images affichées : c'est par lui, et donc par
/// [FetchMediaUsecase], que passe chaque octet d'image venu du réseau.
class TrustedMediaLoader {
  /// Crée un [TrustedMediaLoader].
  ///
  /// - [_fetchMediaUsecase] : cas d'usage de chargement d'un média, qui vérifie chaque redirection.
  /// - [_readTrustSettings] : lecture des réglages de confiance actuels.
  TrustedMediaLoader(this._fetchMediaUsecase, this._readTrustSettings);

  final FetchMediaUsecase _fetchMediaUsecase;

  final Future<TrustSettings> Function() _readTrustSettings;

  /// Retourne le contenu du média [url], ou lève une erreur s'il est refusé ou indisponible.
  ///
  /// L'erreur est levée plutôt que retournée : c'est ce qu'attend le
  /// mécanisme de chargement des images de Flutter pour afficher l'état
  /// d'erreur.
  ///
  /// - [url] : adresse du média, telle que reçue.
  /// - [isConfirmed] : `true` si l'utilisateur a confirmé vouloir l'afficher malgré un domaine inconnu.
  Future<Uint8List> load(String url, {required bool isConfirmed}) async {
    final trustSettings = await _readTrustSettings();
    final result = await _fetchMediaUsecase(
      FetchMediaParams(rawUrl: url, policy: trustSettings.mediaPolicy, isConfirmed: isConfirmed),
    );
    final fetchedMedia = result.right;
    if (fetchedMedia == null) {
      throw StateError('Média refusé ou indisponible : ${result.left}');
    }
    return fetchedMedia.bytes;
  }
}
