/// Représente une valeur pouvant être de l'un de deux types possibles.
///
/// [L] est le type d'échec (Left), [R] est le type de succès (Right).
/// Utiliser [isFailure] ou [isSuccess] avant d'accéder à [left] ou [right].
sealed class Either<L, R> {
  const Either();

  /// Retourne `true` si c'est un [Left] (échec).
  bool get isFailure => this is Left<L, R>;

  /// Retourne `true` si c'est un [Right] (succès).
  bool get isSuccess => this is Right<L, R>;

  /// Retourne la valeur d'échec [Left], ou `null` si c'est un [Right].
  L? get left => switch (this) {
    Left<L, R>(:final value) => value,
    Right<L, R>() => null,
  };

  /// Retourne la valeur de succès [Right], ou `null` si c'est un [Left].
  R? get right => switch (this) {
    Right<L, R>(:final value) => value,
    Left<L, R>() => null,
  };

  /// Exécute [onFailure] si c'est un [Left], ou [onSuccess] si c'est un [Right].
  ///
  /// - [onFailure] : appelé avec la valeur d'échec [Left].
  /// - [onSuccess] : appelé avec la valeur de succès [Right].
  T fold<T>({
    required T Function(L failure) onFailure,
    required T Function(R success) onSuccess,
  }) => switch (this) {
    Left<L, R>(:final value) => onFailure(value),
    Right<L, R>(:final value) => onSuccess(value),
  };
}

/// Côté échec de [Either].
final class Left<L, R> extends Either<L, R> {
  ///
  const Left(this.value);

  /// La valeur d'échec encapsulée.
  final L value;
}

/// Côté succès de [Either].
final class Right<L, R> extends Either<L, R> {
  ///
  const Right(this.value);

  /// La valeur de succès encapsulée.
  final R value;
}
