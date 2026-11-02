import 'package:bedbug/resources/error_log/error_log.entity.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'error_log.model.hive.g.dart';

/// DTO Hive représentant un [ErrorLog] persisté localement.
@HiveType(typeId: HiveTypeIds.errorLog)
class ErrorLogHiveModel extends HiveObject {
  /// Crée un [ErrorLogHiveModel].
  ErrorLogHiveModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.source,
    required this.errorType,
    required this.message,
    required this.stackTrace,
  });

  /// Crée un [ErrorLogHiveModel] depuis une entité [ErrorLog].
  factory ErrorLogHiveModel.fromEntity(ErrorLog entity) {
    return ErrorLogHiveModel(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      source: entity.source,
      errorType: entity.errorType,
      message: entity.message,
      stackTrace: entity.stackTrace,
    );
  }

  /// Identifiant unique de la trace.
  @HiveField(0)
  final String id;

  /// Date de l'erreur.
  @HiveField(1)
  final DateTime createdAt;

  /// Date de dernière mise à jour.
  @HiveField(2)
  final DateTime updatedAt;

  /// Nom du use case qui a attrapé l'erreur.
  @HiveField(3)
  final String source;

  /// Type de l'erreur attrapée.
  @HiveField(4)
  final String errorType;

  /// Description de l'erreur.
  @HiveField(5)
  final String message;

  /// Pile d'appels au moment de l'erreur.
  @HiveField(6)
  final String stackTrace;

  /// Convertit ce modèle en entité [ErrorLog].
  ErrorLog toEntity() {
    return ErrorLog(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: source,
      errorType: errorType,
      message: message,
      stackTrace: stackTrace,
    );
  }
}
