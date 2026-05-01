# Riverpod

Riverpod handles both **state management** and **dependency injection**. Every piece of shared state and every dependency is exposed via a provider.

## State management

- Only use a variable for `ref.watch` calls.
  - For `AsyncNotifier`, name the variable after the notifier with a `Watcher` suffix:

    ```dart
    // ✅ OK
    final exampleNotifierWatcher = ref.watch(exampleNotifierProvider);

    // ❌ Avoid
    final watcher = ref.watch(exampleNotifierProvider);
    ```

  - Otherwise, name it after the encapsulated state:

    ```dart
    final currentUser = ref.watch(currentUserProvider);
    ```

- If a notifier uses async functions, it must extend `AsyncNotifier`. `AsyncValue` already exposes `isLoading` — never add an `isLoading` field to the state.
- In `ref.listen`, always start with `if (next.isLoading) return;` before reading `next.value` or `next.hasError`. An `AsyncValue` in loading state can still expose the previous value, which would incorrectly trigger error logic on reload.
- Never store `ref.read` in a variable, especially in `build`:

  ```dart
  // ✅ OK
  ref.read(exampleNotifierProvider.notifier).doSomething();

  // ❌ Avoid in build()
  final notifier = ref.read(exampleNotifierProvider.notifier);
  ```

## Dependency injection

- All dependencies are injected via Riverpod providers.
- Use `ref.read` to inject dependencies — never `ref.watch`. Declare dependencies as `late final` attributes in notifiers:

  ```dart
  // ✅ OK
  late final exampleRepository = ref.read(exampleRepositoryProvider);

  // ❌ Avoid
  late final exampleRepository = ref.watch(exampleRepositoryProvider);
  ```

- Always store an injected dependency in a named attribute:

  ```dart
  // ✅ OK
  final exampleRepository = ref.read(exampleRepositoryProvider);

  // ❌ Avoid
  ref.read(exampleRepositoryProvider).doSomething();
  ```

## Notifiers

- Prefer one notifier per page or widget. Avoid splitting state across multiple notifiers for a single screen.
- The notifier name must match the page or widget it belongs to:

  ```dart
  // ✅ OK
  class LoginPage extends ... { ... }
  class LoginNotifier extends ... { ... }

  // ❌ Avoid
  class LoginPage extends ... { ... }
  class AuthNotifier extends ... { ... }  // nom non aligné avec la page
  ```

## Conventions

- All providers end with `Provider`:

  ```dart
  final exampleNotifierProvider = ...;
  final exampleRepositoryProvider = ...;
  ```

- A provider is always declared in the **same file** as the class it provides. Never group providers in a separate file.
- A provider is always declared **before** the class it provides:

  ```dart
  // ✅ OK
  final loginNotifierProvider =
      NotifierProvider<LoginNotifier, LoginState>(LoginNotifier.new);

  class LoginNotifier extends Notifier<LoginState> { ... }
  ```

- In a use case file, declaration order is always: **provider → use case class → failure enum → params class**.
- In a notifier file, declaration order is always: **provider → notifier class → notifier state class**.
