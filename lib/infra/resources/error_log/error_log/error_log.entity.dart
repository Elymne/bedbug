import 'package:bedbug/core/domain/entity.dart';

/// Trace d'une erreur imprévue attrapée par un use case.
///
/// Les use cases transforment toute erreur en échec typé : l'utilisateur voit un message générique, et la cause réelle
/// serait perdue une fois l'application fermée. Ce journal la conserve sur l'appareil pour pouvoir comprendre après
/// coup ce qui s'est passé. Il ne voyage jamais.
class ErrorLog extends Entity {
  /// Crée un [ErrorLog].
  ///
  /// - [source] : nom du use case qui a attrapé l'erreur.
  /// - [errorType] : type de l'erreur attrapée.
  /// - [message] : description de l'erreur.
  /// - [stackTrace] : pile d'appels au moment de l'erreur.
  ErrorLog({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.source,
    required this.errorType,
    required this.message,
    required this.stackTrace,
  });

  /// Nom du use case qui a attrapé l'erreur.
  final String source;

  /// Type de l'erreur attrapée.
  final String errorType;

  /// Description de l'erreur.
  final String message;

  /// Pile d'appels au moment de l'erreur.
  final String stackTrace;
}
