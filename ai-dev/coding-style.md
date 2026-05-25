# Coding style

## General

- Line length: **120 characters** (`dart.lineLength: 120`).
- Prefer block functions over arrow functions. Use `=>` only if the full expression fits in under 60 characters on one line:

  ```dart
  // ✅ OK — short and readable
  String get label => user.fullName;

  // ✅ OK — block for longer expressions
  String format(String value) {
    return value.trim().toLowerCase();
  }

  // ❌ Avoid
  String format(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(' ', '_');
  ```

- Follow `analysis_options.yaml` strictly (strict-casts, strict-inference, strict-raw-types, prefer*const*\*, avoid_dynamic_calls, etc.).
- Document every **class**, **function**, and **function parameter** — **always in French**. Includes `@override` and private methods.
- Never use `else` or `else if`. Use early returns or guards:

  ```dart
  // ✅ OK
  if (condition) return valueA;
  return valueB;

  // ❌ Avoid
  if (condition) {
    return valueA;
  } else {
    return valueB;
  }
  ```

- Avoid ternary expressions unless they fit on a single line:

  ```dart
  // ✅ OK
  final label = isActive ? 'Active' : 'Inactive';

  // ❌ Avoid
  final description = isExpired
      ? 'Account expired on ${user.expirationDate}'
      : 'Account is valid';
  ```

- Don't extract private functions unless the block is complex or reused. Inline simple expressions directly.
- Constructors are always declared first in a class, before fields. (consistent with `sort_constructors_first`)
- For injected dependencies, always use the short `this.` constructor form. Never use `: _field = param`:

  ```dart
  // ✅ OK
  UserRepository(this._database, this._logger);

  // ❌ Avoid
  UserRepository({required Database database, required Logger logger})
      : _database = database,
        _logger = logger;
  ```

## Naming

- Never use single-character identifiers, including in lambdas and loops:

  ```dart
  // ✅ OK
  users.map((user) => user.fullName);
  for (final product in products) { ... }

  // ❌ Avoid
  users.map((u) => u.fullName);
  for (final p in products) { ... }
  ```

- `bool` variables and parameters always use the `is` prefix:

  ```dart
  // ✅ OK
  final bool isSaving;

  // ❌ Avoid
  final bool saving;
  ```

- Infrastructure class names are prefixed with the concrete service they depend on, so the external technology is immediately visible from the name:

  ```dart
  // ✅ OK
  class FirestoreUserRepository ...   // uses Firestore
  class FireauthAuthModel ...          // uses Firebase Auth
  class DioProductRepository ...       // uses Dio

  // ❌ Avoid
  class FirebaseUserRepository ...    // "Firebase" is ambiguous (Auth? Firestore?)
  class RemoteProductRepository ...   // hides the actual technology
  ```
