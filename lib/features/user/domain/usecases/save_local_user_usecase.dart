import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/enums/social_network.dart';
import 'package:bedbug/features/user/domain/extensions/profile_text_extension.dart';
import 'package:bedbug/features/user/domain/repositories/user_repository.dart';
import 'package:bedbug/features/user/infrastructure/datasources/hive_user_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveLocalUserUsecase].
final saveLocalUserUsecaseProvider = Provider<SaveLocalUserUsecase>(
  (ref) => SaveLocalUserUsecase(ref.read(userRepositoryProvider)),
);

/// Enregistre le profil de l'utilisateur du téléphone.
///
/// Ce profil sera diffusé avec les contenus de l'utilisateur : il est donc
/// normalisé ici, une fois pour toutes, plutôt que de faire confiance à la
/// saisie brute (espaces en bordure, identifiants collés sous forme d'URL ou
/// préfixés de `@`, réseaux laissés vides). Le pseudo et l'icône doivent
/// respecter les règles de `ProfileTextExtension` (pas d'espace ni de symbole
/// dans le pseudo, pas de mot dans l'icône) et la vitesse du ghost est ramenée
/// dans ses bornes. La date de création d'origine est conservée d'un
/// enregistrement à l'autre.
class SaveLocalUserUsecase extends Usecase<SaveLocalUserParams, SaveLocalUserFailure, User> {
  /// Crée un [SaveLocalUserUsecase].
  SaveLocalUserUsecase(this._userRepository);

  final UserRepository _userRepository;

  @override
  Future<Either<SaveLocalUserFailure, User>> call(SaveLocalUserParams params) async {
    try {
      final pseudo = params.pseudo.trim();
      final avatarText = params.avatarText.trim();
      if (!pseudo.isValidPseudo || !avatarText.isValidAvatarText) {
        return const Left(SaveLocalUserFailure.invalidProfile);
      }

      final socialLinks = <SocialNetwork, String>{};
      for (final entry in params.socialLinks.entries) {
        final handle = entry.key.normalizeHandle(entry.value);
        if (handle != null) {
          socialLinks[entry.key] = handle;
        }
      }

      final existing = await _userRepository.getLocal();
      final now = DateTime.now();
      final user = await _userRepository.saveLocal(
        User(
          id: localUserId,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          pseudo: pseudo,
          email: existing?.email,
          avatarText: avatarText,
          colorArgb: params.colorArgb,
          ghostSpeed: params.ghostSpeed.clamp(minGhostSpeed, maxGhostSpeed),
          socialLinks: socialLinks,
        ),
      );
      return Right(user);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveLocalUserUsecase', error, stackTrace);
      return const Left(SaveLocalUserFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveLocalUserUsecase', error, stackTrace);
      return const Left(SaveLocalUserFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveLocalUserUsecase', error, stackTrace);
      return const Left(SaveLocalUserFailure.unknown);
    }
  }
}

/// Échecs possibles du [SaveLocalUserUsecase].
enum SaveLocalUserFailure {
  /// Le pseudo ou l'icône ne respecte pas les règles de `ProfileTextExtension`.
  invalidProfile,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de l'enregistrement du profil.
  unknown,
}

/// Paramètres du [SaveLocalUserUsecase].
class SaveLocalUserParams extends Params {
  /// Crée des [SaveLocalUserParams].
  ///
  /// - [pseudo] : pseudo saisi.
  /// - [avatarText] : icône texte saisie.
  /// - [colorArgb] : couleur de l'effet ghost de l'icône en ARGB 32 bits, `null` pour la couleur par défaut.
  /// - [ghostSpeed] : vitesse de l'effet ghost (ramenée dans ses bornes par le use case).
  /// - [socialLinks] : identifiants saisis par réseau, bruts (normalisés par le use case).
  const SaveLocalUserParams({
    required this.pseudo,
    required this.avatarText,
    required this.colorArgb,
    required this.ghostSpeed,
    required this.socialLinks,
  });

  /// Pseudo saisi.
  final String pseudo;

  /// Icône texte saisie.
  final String avatarText;

  /// Couleur de l'effet ghost de l'icône en ARGB 32 bits, `null` pour la couleur par défaut.
  final int? colorArgb;

  /// Vitesse de l'effet ghost.
  final double ghostSpeed;

  /// Identifiants saisis par réseau, bruts.
  final Map<SocialNetwork, String> socialLinks;
}
