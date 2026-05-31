import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/infrastructure/hive_type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'user_hive_model.g.dart';

/// DTO Hive représentant un [User] persisté localement.
@HiveType(typeId: HiveTypeIds.user)
class UserHiveModel extends HiveObject {
  /// Crée un [UserHiveModel].
  ///
  /// - [id] : identifiant unique de l'utilisateur.
  /// - [createdAt] : date de création en millisecondes depuis l'époque.
  /// - [updatedAt] : date de mise à jour en millisecondes depuis l'époque.
  /// - [pseudo] : nom d'affichage de l'utilisateur.
  /// - [email] : adresse e-mail, nullable.
  UserHiveModel({required this.id, required this.createdAt, required this.updatedAt, required this.pseudo, this.email});

  /// Crée un [UserHiveModel] depuis une entité [User].
  factory UserHiveModel.fromEntity(User entity) {
    return UserHiveModel(
      id: entity.id,
      createdAt: entity.createdAt.millisecondsSinceEpoch,
      updatedAt: entity.updatedAt.millisecondsSinceEpoch,
      pseudo: entity.pseudo,
      email: entity.email,
    );
  }

  /// Identifiant unique de l'utilisateur.
  @HiveField(0)
  final String id;

  /// Date de création en millisecondes depuis l'époque Unix.
  @HiveField(1)
  final int createdAt;

  /// Date de mise à jour en millisecondes depuis l'époque Unix.
  @HiveField(2)
  final int updatedAt;

  /// Nom d'affichage de l'utilisateur.
  @HiveField(3)
  final String pseudo;

  /// Adresse e-mail de l'utilisateur, nullable.
  @HiveField(4)
  final String? email;

  /// Convertit ce modèle en entité [User].
  User toEntity() {
    try {
      return User(
        id: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        pseudo: pseudo,
        email: email,
      );
    } catch (error) {
      throw DataException('UserHiveModel', error);
    }
  }
}
