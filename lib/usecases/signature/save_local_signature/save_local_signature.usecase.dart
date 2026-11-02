import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature.repository.dart';
import 'package:bedbug/resources/signature/signature.repository.hive.dart';
import 'package:bedbug/resources/signature/signature_text.extension.dart';
import 'package:bedbug/resources/signature/social_network.enum.dart';
import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.failure.dart';
import 'package:bedbug/usecases/signature/save_local_signature/save_local_signature.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveLocalSignatureUsecase].
final saveLocalSignatureUsecaseProvider = Provider<SaveLocalSignatureUsecase>((ref) {
  return SaveLocalSignatureUsecase(ref.read(signatureRepositoryProvider));
});

/// Enregistre le profil de l'utilisateur du téléphone.
///
/// Ce profil sera diffusé avec les contenus de l'utilisateur : il est donc
/// normalisé ici, une fois pour toutes, plutôt que de faire confiance à la
/// saisie brute (espaces en bordure, identifiants collés sous forme d'URL ou
/// préfixés de `@`, réseaux laissés vides, description vide). Le pseudo,
/// l'icône et la description doivent respecter les règles de
/// `SignatureTextExtension` (pas d'espace ni de symbole dans le pseudo, pas de
/// mot dans l'icône, description courte sur une ligne) et la vitesse du ghost est ramenée
/// dans ses bornes. La date de création d'origine est conservée d'un
/// enregistrement à l'autre.
class SaveLocalSignatureUsecase extends Usecase<SaveLocalSignatureParams, SaveLocalSignatureFailure, Signature> {
  /// Crée un [SaveLocalSignatureUsecase].
  SaveLocalSignatureUsecase(this._signatureRepository);

  final SignatureRepository _signatureRepository;

  @override
  Future<Either<SaveLocalSignatureFailure, Signature>> call(SaveLocalSignatureParams params) async {
    try {
      final pseudo = params.pseudo.trim();
      final avatarText = params.avatarText.trim();
      final bio = params.bio?.trim() ?? '';
      if (!pseudo.isValidPseudo || !avatarText.isValidAvatarText || !bio.isValidSignatureBio) {
        return const Left(SaveLocalSignatureFailure.invalidProfile);
      }

      final socialLinks = <SocialNetwork, String>{};
      for (final entry in params.socialLinks.entries) {
        final handle = entry.key.normalizeHandle(entry.value);
        if (handle != null) {
          socialLinks[entry.key] = handle;
        }
      }

      final existing = await _signatureRepository.getLocal();
      final now = DateTime.now();
      final signature = await _signatureRepository.saveLocal(
        Signature(
          id: localSignatureId,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          pseudo: pseudo,
          avatarText: avatarText,
          colorArgb: params.colorArgb,
          ghostSpeed: params.ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
          socialLinks: socialLinks,
          bio: bio.isEmpty ? null : bio,
          bioFont: params.bioFont,
        ),
      );
      return Right(signature);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveLocalSignatureUsecase', error, stackTrace);
      return const Left(SaveLocalSignatureFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveLocalSignatureUsecase', error, stackTrace);
      return const Left(SaveLocalSignatureFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveLocalSignatureUsecase', error, stackTrace);
      return const Left(SaveLocalSignatureFailure.unknown);
    }
  }
}
