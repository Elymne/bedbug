import 'dart:math';

import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/enums/social_network.dart';
import 'package:bedbug/features/user/domain/repositories/user_repository.dart';
import 'package:bedbug/features/user/infrastructure/datasources/hive_user_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SeedUsersUsecase].
final seedUsersUsecaseProvider = Provider<SeedUsersUsecase>(
  (ref) => SeedUsersUsecase(ref.read(userRepositoryProvider)),
);

/// Pseudos factices, tous conformes à la règle des pseudos (lettres et tirets).
const List<String> _pseudos = [
  'Punaise-Royale',
  'Lit-Superpose',
  'Matelas-Fou',
  'Draps-Froids',
  'Oreiller-Ninja',
  'Couette-Joyeuse',
  'Sommier-Rebelle',
  'Grillon-Nocturne',
  'Moustique-Zen',
  'Acarien-Furtif',
  'Plume-Mystere',
  'Tapis-Volant',
];

/// Icônes factices, toutes conformes à la règle des icônes (pas de mot).
const List<String> _avatarTexts = [
  '( ノ ^o^)ノ',
  'ʕ•ᴥ•ʔ',
  '(=^･ω･^=)',
  '(╯°□°)╯︵ ┻━┻',
  r'¯\_(ツ)_/¯',
  '(ง •̀_•́)ง',
  '(づ｡◕‿‿◕｡)づ',
  '(-.-)Zzz',
];

/// Couleurs de ghost factices, en ARGB 32 bits.
const List<int> _colorArgbs = [0xFFFF7DA4, 0xFF51C2FF, 0xFF9BDDB1, 0xFF9B59B6, 0xFFFF9D4D, 0xFFFFD166];

/// Réseaux sur lesquels les utilisateurs factices peuvent avoir un lien.
///
/// Choisis parce que leur format accepte un pseudo à tiret tel quel (ou, pour
/// Bluesky, sous forme de domaine).
const List<SocialNetwork> _seedNetworks = [
  SocialNetwork.github,
  SocialNetwork.gitlab,
  SocialNetwork.deviantArt,
  SocialNetwork.bluesky,
];

/// Génère quelques utilisateurs factices au profil tiré au hasard.
///
/// Sans pair à proximité, l'appareil ne connaît aucun autre utilisateur que
/// lui-même : la recherche par utilisateur et l'affichage des auteurs n'ont
/// alors rien à montrer. Ce use case crée des profils variés (pseudo, icône,
/// couleur, vitesse du ghost, réseaux) à associer aux contenus factices.
///
/// Les identifiants sont stables (`seed-user-0`, `seed-user-1`…) : relancer
/// le seed remplace les utilisateurs factices précédents au lieu de les
/// accumuler, et ne touche jamais au profil de l'utilisateur du téléphone.
/// Retourne les identifiants créés, à passer au seed des contenus.
class SeedUsersUsecase extends Usecase<SeedUsersParams, SeedUsersFailure, List<String>> {
  /// Crée un [SeedUsersUsecase].
  SeedUsersUsecase(this._userRepository);

  final UserRepository _userRepository;

  @override
  Future<Either<SeedUsersFailure, List<String>>> call(SeedUsersParams params) async {
    try {
      final random = Random(params.randomSeed);
      final pseudos = [..._pseudos]..shuffle(random);
      final now = DateTime.now();
      final count = min(params.count, pseudos.length);

      final users = [
        for (var index = 0; index < count; index++)
          User(
            id: 'seed-user-$index',
            createdAt: now,
            updatedAt: now,
            pseudo: pseudos[index],
            avatarText: _avatarTexts[random.nextInt(_avatarTexts.length)],
            colorArgb: _colorArgbs[random.nextInt(_colorArgbs.length)],
            ghostSpeed: _randomGhostSpeed(random),
            socialLinks: _randomSocialLinks(random, pseudos[index]),
          ),
      ];

      await _userRepository.saveMany(users);
      return Right([for (final user in users) user.id]);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SeedUsersUsecase', error, stackTrace);
      return const Left(SeedUsersFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SeedUsersUsecase', error, stackTrace);
      return const Left(SeedUsersFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SeedUsersUsecase', error, stackTrace);
      return const Left(SeedUsersFailure.unknown);
    }
  }

  /// Tire une vitesse de ghost entre [minGhostSpeed] et [maxGhostSpeed], par pas de 0,25 comme le curseur.
  double _randomGhostSpeed(Random random) {
    final steps = ((maxGhostSpeed - minGhostSpeed) / 0.25).round();
    return minGhostSpeed + random.nextInt(steps + 1) * 0.25;
  }

  /// Tire de zéro à deux liens vers les réseaux de [_seedNetworks], construits à partir de [pseudo].
  ///
  /// Chaque identifiant passe par `normalizeHandle` : un lien ne respectant
  /// pas le format du réseau n'est simplement pas ajouté.
  Map<SocialNetwork, String> _randomSocialLinks(Random random, String pseudo) {
    final networks = [..._seedNetworks]..shuffle(random);
    final links = <SocialNetwork, String>{};
    for (final network in networks.take(random.nextInt(3))) {
      final rawHandle = network == SocialNetwork.bluesky ? '${pseudo.toLowerCase()}.bsky.social' : pseudo.toLowerCase();
      final handle = network.normalizeHandle(rawHandle);
      if (handle != null) {
        links[network] = handle;
      }
    }
    return links;
  }
}

/// Échecs possibles du [SeedUsersUsecase].
enum SeedUsersFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la génération des utilisateurs.
  unknown,
}

/// Paramètres du [SeedUsersUsecase].
class SeedUsersParams extends Params {
  /// Crée des [SeedUsersParams].
  ///
  /// - [count] : nombre d'utilisateurs à générer, au plus le nombre de pseudos disponibles. Par défaut : 5.
  /// - [randomSeed] : graine du tirage, pour un seed reproductible (tests). `null` pour un tirage aléatoire.
  const SeedUsersParams({this.count = 5, this.randomSeed});

  /// Nombre d'utilisateurs à générer.
  final int count;

  /// Graine du tirage, `null` pour un tirage aléatoire.
  final int? randomSeed;
}
