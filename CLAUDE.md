# BedBug

Open-source local social network: messages and contents are transmitted from device to device (Wi-Fi / BLE).

This file only describes the architecture, the folder structure, the libraries and the coding rules. Anything that can
be learned by reading the code (existing widgets, entities, use cases…) does not belong here.

## Architecture

Clean Architecture, object-oriented. Data access is organised by **data scope**, business logic by **business scope**,
and a separate **application** layer holds UI and framework concerns.

```
lib/
  resources/     persisted data: entities, value objects, repositories and their implementations, by data scope
  gateways/      external sources (HTTP, gallery, BLE…): interfaces and implementations, by source
  services/      small pure logic bricks, by business scope
  usecases/      business operations, by business scope
  application/   UI and framework orchestration
  core/          cross-cutting technical code, no business logic
```

### Dependency rules

```
application → usecases → services
                       → resources, gateways
core → used by all
```

- `application` calls use cases and services. It only touches `resources` / `gateways` to read their types (entities,
  value objects, enums) or to wire providers.
- `usecases` depend on `services`, `resources` and `gateways`, whatever their scope: a use case of one business scope
  freely uses the data of several data scopes. A use case never depends on another use case.
- `services` depend on other services and on the types of `resources` / `gateways`, never on a repository or a gateway.
- `gateways` may use the types of `resources`.
- `core` depends on nothing.

### Resources

One folder per **data** scope (`content`, `exchange`, `settings`, `signature`, `error_log`…), not per business concern.
Inside a scope, one folder per resource: every entity and every value object gets its own folder (`content/comment/`,
`content/reaction_merge/`, `exchange/exchange_log/`…), even when the scope holds a single one. A resource folder holds
everything about that data:

```
resources/<scope>/<resource>/
  <name>.entity.dart            entity
  <name>.value_object.dart      value object
  <name>.enum.dart              enum tied to the resource
  <resource>.extension.dart     extensions on the resource types themselves (computed getters), in one file
  <name>.repository.dart        repository interface
  <name>.repository.hive.dart   repository implementation, suffixed with its technology
  <name>.model.hive.dart        Hive DTO (+ generated <name>.model.hive.g.dart)
  <resource>.config.dart        public constants of the resource (limits, defaults, box names)
resources/
  data.exception.dart           invalid or corrupted data
  datasource.exception.dart     storage failure
  hive.initializer.dart         Hive setup, box opening
  hive.type_ids.dart            HiveTypeIds
```

### Gateways

One folder per external source (`media`, `public_suffix`, `og_metadata`, `exchange`…), then one folder per gateway
(`media/media_http/`, `exchange/peer_link/`), same naming as resources: `<name>.gateway.dart` for the interface,
`<name>.gateway.<technology>.dart` for each implementation (`media_http.gateway.dio.dart`, `peer_link.gateway.ble.dart`),
plus the value objects, enums, exceptions and `<gateway>.config.dart` of that gateway.

### Constants

Public top-level constants never sit in an entity, repository, gateway, service or use case file: they go in the
`.config.dart` of their folder (`storage.config.dart`, `fetch_media.config.dart`). Private constants (`_name`) stay in
the file that uses them.

### Exceptions

- Only `resources` and `gateways` throw. Their exceptions live next to them (`<name>.exception.dart`).
- From the use cases onwards, everything goes through `Either`.

### Services

```
services/<business_scope>/<name>.service.dart
services/<business_scope>/<name>.config.dart    public constants of the service, absent if none
```

### Use cases

One folder per use case, inside its business scope (`content`, `feed`, `reaction`, `comment`, `trust`, `storage`,
`exchange`, `signature`, `settings`…):

```
usecases/<business_scope>/<name>/
  <name>.usecase.dart   provider, use case, its constants and private helpers
  <name>.params.dart    params class, absent with NoParams
  <name>.failure.dart   failure enum
  <name>.config.dart    public constants of the use case, absent if none
  <name>.result.dart    return type defined by this use case only; absent when it returns void, a primitive, or an
                        existing entity / value object
```

### Application

The only layer aware of the framework.

```
application/
  screens/<screen>/   one folder per screen: the screen, its local notifiers and its local widgets/
  widgets/            widgets reused across screens, grouped by kind
  notifiers/          notifiers shared across screens
  providers/          technical providers shared across screens
  exchange/           device-to-device session, orchestrating the exchange use cases
  router/             router and route paths
  style/              colors, text styles, theme, constants
  validators/         form validators
  formatters/         input formatters
  l10n/               ARB files and localization
```

### Core

Purely technical code: no business rule, no domain knowledge, no UI or widget.

```
core/
  domain/          base classes (Usecase, Service, Params, Entity, ValueObject, Either)
  extensions/      cross-cutting extensions
  logger/
  config/
```

### Use case rules

- Extend `Usecase<P extends Params, F, V>` and implement `call(params)`, returning `Future<Either<F, V>>`.
- Never throw: failures are explicit and typed (failure enum).
- Use `NoParams` when no input is required.
- A use case never depends on another use case, only on repositories, gateways and services, even if it duplicates code.
  Only the application layer calls use cases.
- Logic needed by a single use case stays a private method of that use case.
- Every use case receives `ErrorLogRepository`. Its final `catch (error, stackTrace)` (the unexpected errors, not the
  `on XException` ones) logs with `AppLogger.error`, then calls `_errorLogRepository.record(...)`, which never throws.

### Service rules

- Extend `Service`. A service holds small pure logic bricks reused by several use cases or by the application
  (parsing an address, matching a domain rule, detecting a file format).
- Synchronous, no data access (no repository, no gateway): a service may only depend on other services. Anything
  that needs more is a use case.
- Never throw, and never return an `Either`: a failure is expressed by `null` or by an enum value. No `try/catch`
  either: use the non-throwing APIs (`Uri.tryParse`, `int.tryParse`) and guard indexes and lengths.
- Provided through a provider, like everything else.

### Entities and value objects

- `Entity`: persisted object with `id`, `createdAt`, `updatedAt`.
- `ValueObject`: computed data, composite structure or concept without identity. It lives in `resources` (or in
  `gateways` when it belongs to an external source), never in `usecases`, except for a type returned by a single use
  case (`<name>.result.dart`).
- Both are immutable (`final` fields, `const` constructor) with value-based equality.
- Instances are dumb data: fields, equality, `toString` and `copyWith` only, no instance logic.
- The rules tied to the resource itself (validating a field, normalising a value) are **static methods of the entity
  or value object** (`Comment.isValidBody(body)`, `Signature.isValidPseudo(pseudo)`): pure, synchronous, never throw,
  no data access. They take the raw value rather than the object, so forms can check a field before the object
  exists. Never write them as extensions on a base type (`String`, `int`…).

### Enums and extensions

- Tied to a single class → same file as the class.
- Tied to an entity / value object → its resource folder `resources/<scope>/<resource>/` (or its gateway folder).
- Tied to a use case → that use case's folder.

### Repositories

- Declared as a standalone `abstract class` (no shared `Repository<Entity, Params>` base) in `<name>.repository.dart`,
  implemented next to it in `<name>.repository.<technology>.dart`.
- A repository only declares the methods its entity actually needs. No imposed CRUD: an entity that is never updated or
  deleted exposes neither `update` nor `delete`.
- The interface exists only to swap the storage implementation, to ease testing (mocks) and to stay symmetric with use
  cases. It is not meant to impose a shape.
- No generic pagination system (`Page<T>`, `RepositoryParams`…): each listing method declares the parameters and return
  type it needs.

### Core principles

- One file = one responsibility.
- Never mix UI, business logic and data access.
- File names are `snake_case`, with dot-separated suffixes for their role and technology (`reaction.entity.dart`,
  `reaction.repository.hive.dart`).

## Code style

### General

- Line length: **120 characters**.
- Follow `analysis_options.yaml` strictly.
- Never use `=>` on named functions (methods, getters, top-level functions). Reserve it for lambdas:

  ```dart
  // ✅ OK
  users.map((user) => user.fullName);

  String format(String value) {
    return value.trim().toLowerCase();
  }

  // ❌ Avoid
  String format(String value) => value.trim().toLowerCase();
  ```

- An arrow lambda is only allowed when it fits on a single line once formatted. As soon as the formatter has to break
  it (body wrapping over several lines, or lambda pushed onto its own line), use a block body with `return`. This
  applies in particular to provider definitions:

  ```dart
  // ✅ OK — fits on one line
  final ogMetadataServiceProvider = Provider<OgMetadataService>((ref) => OgMetadataService());

  // ✅ OK — too long for one line → block body
  final saveContentUsecaseProvider = Provider<SaveContentUsecase>((ref) {
    return SaveContentUsecase(ref.read(contentRepositoryProvider), ref.read(storageRepositoryProvider));
  });

  // ❌ Avoid — lambda pushed onto its own line
  final saveContentUsecaseProvider = Provider<SaveContentUsecase>(
    (ref) => SaveContentUsecase(ref.read(contentRepositoryProvider), ref.read(storageRepositoryProvider)),
  );
  ```

- Always use braces `{}` for `if`, `for`, `while`…, even for single-line bodies.
- Never use `else` or `else if`: use early returns and guards.
- Ternary expressions only when they fit on a single line.
- Don't extract private functions unless the block is complex or reused.
- Constructors come first in a class, then fields, then public methods (including `build`), then private methods.
- Inject dependencies with the short `this.` constructor form, never `: _field = param`:

  ```dart
  // ✅ OK
  UserRepository(this._database, this._logger);
  ```

### Documentation

- Document every class, function and function parameter, **always in French**, including `@override` and private
  members.
- For non-trivial functions, and **always** for use cases, the doc comment explains **why** the function exists (the
  underlying need, the business justification), not a paraphrase of its signature:

  ```dart
  // ✅ OK
  /// Retourne une copie de ce contenu avec ses scores mis à jour.
  ///
  /// Les scores ([broadcastScore], [survivalScore]) sont recalculés périodiquement à mesure que les contenus
  /// vieillissent ou changent de statut ; cette méthode permet d'appliquer ces nouvelles valeurs sans reconstruire
  /// manuellement chaque sous-type de [Content].

  // ❌ Avoid
  /// Copie ce contenu avec de nouveaux scores.
  ```

### Naming

- No single-character identifiers, including in lambdas and loops.
- `bool` variables and parameters always use the `is` prefix (`isSaving`).
- Implementation classes are prefixed with the concrete technology they depend on (`HiveContentRepository`,
  `GalImageGalleryGateway`), never a vague word (`RemoteProductRepository`, `FirebaseUserRepository`).

## Flutter

- Use `const` everywhere possible.
- Never use `setState`.
- Prefer inlining widget code in `build`. When extraction is needed:
  - display-only widget (no state, no logic, no callback) → a private function returning a widget is acceptable;
  - widget with logic or callbacks, or reused across files → a public widget class in its own file.
- Avoid `initState` when attributes can be initialized directly with `late final` (`widget` is accessible there).
- In `Column` / `Row`, space children with `SizedBox`, or with the `spacing` attribute when spacing is uniform. Reserve
  `Padding` for isolated widgets.
- `State` / `ConsumerState` classes are always private and named `_State`.
- Never use color literals (`Color(0xFF…)`) in widgets: always use `AppColors`, adding the color there first if needed.
- Before creating a widget, check `application/widgets/` for an existing one.
- Never use `Icon` or `Icons`: always `AppIcon` with a value of `AppIcons`. A new icon is an SVG in `assets/icons/` (24×24
  grid, stroke width 2, round caps and joins, no fill), declared in `AppIcons` under the same name as the file.

## Libraries

| Concern               | Library                                                 |
| --------------------- | ------------------------------------------------------- |
| State management + DI | `flutter_riverpod`                                      |
| Routing               | `go_router`                                             |
| Forms                 | `reactive_forms`                                        |
| Local persistence     | `hive_ce` (+ `hive_ce_generator`), `shared_preferences` |
| Localization          | `flutter_localizations`, `intl`                         |
| HTTP                  | `dio`                                                   |
| Icons                 | `flutter_svg`                                           |

### Riverpod

Riverpod handles both state management and dependency injection.

#### Widgets

- Always `ConsumerWidget` / `ConsumerStatefulWidget`. Never `StatelessWidget` / `StatefulWidget`.

#### State

- Only store `ref.watch` results in a variable. For an `AsyncNotifier`, suffix the variable with `Watcher`
  (`exampleNotifierWatcher`); otherwise name it after the state (`currentUser`).
- Never store `ref.read` in a variable inside `build`: call `ref.read(provider.notifier).doSomething()` directly.
- A notifier using async functions extends `AsyncNotifier`. Never add an `isLoading` field: `AsyncValue` has it.
- In `ref.listen`, always start with `if (next.isLoading) return;` before reading `next.value` or `next.hasError`.

#### Dependency injection

- All dependencies are injected through providers, with `ref.read`, never `ref.watch`.
- Store each injected dependency in a named `late final` attribute of the notifier:

  ```dart
  late final exampleRepository = ref.read(exampleRepositoryProvider);
  ```

#### Notifiers

- One notifier per concern, not one catch-all notifier per screen. Business state (data from a use case) and ephemeral
  UI state (scroll-driven animation, cursor position…) never share a notifier.
- Name each notifier after its concern (`HomeFeedNotifier`, `HomeBarsOffsetNotifier`), not only after its screen.
- A `ref.watch` on high-frequency UI state is scoped to the closest widget that needs it (local `Consumer`), never at
  the top of the screen's `build`.

#### Conventions

- Every provider name ends with `Provider`.
- A provider is declared in the same file as the class it provides, right before it.
- Use case file order: provider → use case (failure, params and result live in their own files).
- Notifier file order: provider → notifier → state class.

### go_router

- The router is a `Provider<GoRouter>` declared in the same file as the route paths.
- Every route path is a top-level `const String` in the router file, before the provider.
- Always `pageBuilder`, never `builder`: `NoTransitionPage` on web, `MaterialPage` / `CupertinoPage` on mobile.
- Sub-routes use a relative path (no leading `/`).
- Read path parameters through `state.pathParameters`.
- Always provide an `errorBuilder` pointing to a dedicated error page.

### reactive_forms

- Never use `TextEditingController`, `ValueNotifier` or `GlobalKey<FormState>`.
- The `FormGroup` and its controls are `late final` attributes of the widget's `State`, not of the notifier. Dispose the
  form in `dispose()`.
- Declare each `FormControl<T>` as its own typed `late final` attribute, then reference it in the `FormGroup`, so values
  are read without casts:

  ```dart
  late final _emailControl = FormControl<String>(validators: [AppValidators.required, AppValidators.email]);
  late final FormGroup _form = FormGroup({'email': _emailControl});
  ```

- Validators come from `AppValidators` and are declared on the `FormControl`. Each one is a `const` instance of a private
  class extending `Validator<dynamic>`, never a plain function.
- Before submitting, check `_form.valid`; if invalid, call `_form.markAllAsTouched()` and return.
- Text fields use `ReactiveTextField<String>`, dropdowns `ReactiveDropdownField<T>`. For custom fields, pass the
  `FormControl<T>` to the child widget and react with `ListenableBuilder`.

### Hive

- Hive models live in `resources/<scope>/<resource>/<name>.model.hive.dart`, annotated with `@HiveType` / `@HiveField`.
- Every `typeId` is declared in `HiveTypeIds`. Never reuse a removed `typeId`.
- Regenerate with `build_runner` after each model change (see README).

### Localization

- No hardcoded user-facing string: everything goes through the ARB files in `application/l10n/`.
- Every key has a companion `@key` entry with a mandatory `description`.
- Keys are camelCase `<screen><Context>` (`homeEmptyList`). Generic strings use a short unprefixed name (`close`).
- Run `flutter gen-l10n` after each ARB change. Never edit `generated/`.
- In widgets: `AppLocalizations.of(context)!`. In notifiers and providers: `ref.l10n`.
