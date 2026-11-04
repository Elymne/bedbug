# BedBug

Open-source local social network: messages and contents are transmitted from device to device (Wi-Fi / BLE).
Targets Android and iOS only: no web or desktop platform.

This file only describes the architecture, the folder structure, the libraries and the coding rules. Anything that can
be learned by reading the code (existing widgets, entities, use cases…) does not belong here.

## Architecture

Clean Architecture, object-oriented. Data access is organised by **data scope**, business logic by **business scope**,
and a separate **application** layer holds UI and framework concerns.

```
lib/
  resources/     persisted data: entities, value objects, repositories and their implementations, by data scope
  gateways/      external sources (HTTP, gallery, BLE…): interfaces and implementations, by source
  services/      "sub use cases" reused by several use cases, by business scope
  usecases/      business operations, by business scope
  application/   UI and framework orchestration
  core/          cross-cutting technical code, no business logic
```

### Dependency rules

```
application → usecases → services → resources, gateways
                       ↘ resources, gateways
core → used by all
```

- `application` only calls use cases. It touches `resources` / `gateways` to read their types (entities, value
  objects, enums), to call their static rules (`SafeUrl.parse`), or to wire providers.
- `usecases` depend on `services`, `resources` and `gateways`, whatever their scope: a use case of one business scope
  freely uses the data of several data scopes. A use case never depends on another use case.
- `services` depend on `resources`, `gateways` and other services, never on a use case.
- `gateways` may use the types of `resources`.
- `core` depends on nothing.

### Resources

One folder per **data** scope (`content`, `exchange`, `settings`, `signature`, `error_log`…), not per business concern.
Inside a scope, one folder per resource: every entity and every value object gets its own folder (`content/comment/`,
`content/drawing/`, `exchange/exchange_log/`…), even when the scope holds a single one. Exception: a small value
object that only exists as a part of another object stays in its owner's file (`UrlTrustPolicy` in
`trust_settings.value_object.dart`, `DrawingOperation` and `DrawingPoint` in `drawing.value_object.dart`). Such a part
does not extend `ValueObject`: only its owner does, since the part never lives on its own. A resource
folder holds everything about that data:

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
`<name>.gateway.<technology>.dart` for each implementation (`media_http.gateway.dio.dart`, `peer_link.gateway.ble.dart`).
The messages a gateway reads or writes (value objects, enums) live in its interface file, next to the contract
(`ExchangeBundle` in `exchange_codec.gateway.dart`, `MediaHttpResponse` in `media_http.gateway.dart`); its exceptions
and constants go in `<gateway>.exception.dart` and `<gateway>.config.dart`.

### Constants

Public top-level constants and default values (`const`, or `final` when they cannot be `const`, like `anonymousSignature`)
never sit in an entity, repository, gateway, service, use case, screen, widget or notifier file: they go in the
`.config.dart` of their folder (`storage.config.dart`, `fetch_media.config.dart`, `home.config.dart`,
`app_nav_bar.config.dart`). Private constants (`_name`) stay in
the file that uses them.

### Exceptions

- Only `resources` and `gateways` throw. Their exceptions live next to them (`<name>.exception.dart`).
- From the use cases onwards, everything goes through `Either`.

### Services

Same layout as use cases: one folder per service, inside its business scope.

```
services/<business_scope>/<name>/
  <name>.service.dart   provider, service, its constants and private helpers
  <name>.params.dart    params class, absent with NoParams
  <name>.failure.dart   failure enum
  <name>.config.dart    public constants of the service, absent if none
  <name>.result.dart    return type defined by this service only; absent otherwise
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
  screens/<screen>/   one folder per screen (see "State ownership" below):
    <screen>.screen.dart
    <screen>.config.dart
    <widget>/           one folder per widget of the screen: <widget>.widget.dart, plus <widget>.notifier.dart
                        when it watches a notifier of its own (and <widget>.config.dart if needed)
  widgets/            widgets reused across screens, grouped by kind, each next to the technical helpers only its
                      kind uses (`widgets/media/trusted_media_loader.dart`)
  notifiers/          global notifiers: watched by several widgets
  exchange/           device-to-device session, orchestrating the exchange use cases
  drawing/            drawing rendering (rasterizer, flood fill), shared by the editor and the drawing widgets
  router/             router and route paths
  style/              colors, text styles, theme
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
- A use case never depends on another use case, only on repositories, gateways and services. Code shared by several
  use cases becomes a service. Only the application layer calls use cases.
- Logic needed by a single use case stays a private method of that use case.
- Every use case receives `ErrorLogRepository`. Its final `catch (error, stackTrace)` (the unexpected errors, not the
  `on XException` ones) logs with `AppLogger.error`, then calls `_errorLogRepository.record(...)`, which never throws.

### Service rules

- A service is a "sub use case": a sequence of operations that several use cases would otherwise duplicate
  (`DeleteContentsService`: delete contents with their reactions, comments, traces and weight; `MergeReactionService`:
  integrate a reaction within its limits). It is written once, and each use case calls it.
- Extend `Service<P extends Params, F, V>` and implement `call(params)`, returning `Future<Either<F, V>>`: same shape
  and same error rules as a use case (typed failure enum, catch-all logged and recorded in `ErrorLogRepository`).
- May depend on repositories, gateways and other services, never on a use case. Only use cases call services.
- The calling use case maps the service failure to its own failure enum.
- A pure, synchronous rule about a single resource is not a service: it is a static method of that resource (see
  below).

### Entities and value objects

- `Entity`: object with its own identity, followed over time (`id`, `createdAt`, `updatedAt`): it is found again by
  its `id` even when its values change (a content, a signature, a reaction).
- `ValueObject`: object defined only by its values, without identity: two value objects with the same values are
  interchangeable. It may be persisted, on its own (a single setting always replaced as a whole: `UserSettings`,
  `TrustSettings`, `Storage`) or inside an entity (`Drawing` in `DrawingContent`). It lives in `resources` (or in
  `gateways` when it belongs to an external source), never in `usecases` or `services`, except for a type returned by a
  single use case or service (`<name>.result.dart`).
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
  `reaction.repository.hive.dart`). In `application`: `<name>.screen.dart`, `<name>.widget.dart`,
  `<name>.notifier.dart`.

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
  final ogMetadataGatewayProvider = Provider<OgMetadataGateway>((ref) => DioOgMetadataGateway());

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
- Never store `ref.read` in a variable inside `build`: call `ref.read(provider.notifier).doSomething()` (or read
  `ref.read(provider.notifier).someControl`) directly.
- A notifier using async functions extends `AsyncNotifier`. Never add an `isLoading` field: `AsyncValue` has it.
- In `ref.listen`, always start with `if (next.isLoading) return;` before reading `next.value` or `next.hasError`.

#### Dependency injection

- All dependencies are injected through providers, with `ref.read`, never `ref.watch`.
- Store each injected dependency in a named `late final` attribute of the notifier:

  ```dart
  late final exampleRepository = ref.read(exampleRepositoryProvider);
  ```

#### State ownership

- A screen is static: it only lays out widgets and never calls `ref.watch`. Whatever needs a state is cut out into the
  smallest widget that displays it, and that widget watches the state itself, so a change rebuilds only that widget.
- A widget watches **at most one** notifier. A widget that would watch two is either split into several widgets, or
  its two notifiers are merged into one. This applies to global widgets (`application/widgets/`) too.
- Only `ref.watch` counts: any widget may `ref.listen` to react to what happens in the app, and may call
  `ref.read(provider.notifier).doSomething()` to trigger an action.

#### Notifiers

- A notifier watched by a **single** widget belongs to it: same name as the widget (`HomeFeed` ↔ `HomeFeedNotifier`),
  in a folder named after the widget inside its screen (`home/home_feed/home_feed.widget.dart` +
  `home_feed.notifier.dart`).
- A notifier watched by **several** widgets is global: it goes in `application/notifiers/` and is named after the
  action it allows.
- Exception, for a screen built around one piece of state that many of its own widgets edit (`drawing_editor`): the
  notifiers shared by several widgets of that screen only go in a `notifiers/` folder of the screen
  (`screens/drawing_editor/notifiers/drawing_editor.notifier.dart`), named after what they manage.
- Business state (data from a use case) and ephemeral UI state (scroll-driven animation, cursor position…) never share
  a notifier.

#### Conventions

- Every provider name ends with `Provider`.
- A provider is declared in the same file as the class it provides, right before it.
- Use case file order: provider → use case (failure, params and result live in their own files).
- Notifier file order: provider → notifier → state class.

### go_router

- The router is a `Provider<GoRouter>` declared in the same file as the route paths.
- Every route path is a top-level `const String` in the router file, before the provider.
- Always `pageBuilder`, never `builder`.
- Sub-routes use a relative path (no leading `/`).
- Read path parameters through `state.pathParameters`.
- Always provide an `errorBuilder` pointing to a dedicated error page.

### reactive_forms

- Never use `TextEditingController`, `ValueNotifier` or `GlobalKey<FormState>`.
- By default, a form lives in the `State` of the widget that displays it: its controls are typed `late final`
  attributes, and the form is disposed in `dispose()`.

  ```dart
  late final _emailControl = FormControl<String>(validators: [AppValidators.required, AppValidators.email]);
  late final FormGroup _form = FormGroup({'email': _emailControl});
  ```

- When several widgets share the same form, it moves to the notifier that manages it, instead of passing its controls
  from widget to widget: the `FormGroup` and its controls become public typed attributes of the notifier, created in
  `build()` and disposed with `ref.onDispose(form.dispose)` (disposing a `FormGroup` disposes its controls). The
  notifier must stay watched by a widget for as long as the form is displayed. Widgets read the controls they display
  from it (`ref.read(provider.notifier).emailControl`), and the form logic lives there: submission (validation,
  building the object, calling the use case) and the operations on several controls. Widgets keep the display, the
  localized validation messages, the snackbars and the navigation.

  ```dart
  late FormControl<String> emailControl;
  late FormGroup form;

  @override
  Future<void> build() async {
    emailControl = FormControl<String>(validators: [AppValidators.required, AppValidators.email]);
    form = FormGroup({'email': emailControl});
    ref.onDispose(form.dispose);
  }
  ```

- Either way, declare each `FormControl<T>` as its own typed attribute, then reference it in the `FormGroup`, so values
  are read without casts. Never bind a field by name (`formControlName`) nor read a control through
  `form.control('name')`. Reusable field widgets of `application/widgets/` take a `FormControl<T>` parameter.
- Validators come from `AppValidators` and are declared on the `FormControl`. Each one is a `const` instance of a private
  class extending `Validator<dynamic>`, never a plain function.
- Before submitting, check `form.valid`; if invalid, call `form.markAllAsTouched()` and return.
- Text fields use `ReactiveTextField<String>`, dropdowns `ReactiveDropdownField<T>`. To rebuild a part of the UI when a
  control or a group changes, use `ReactiveValueListenableBuilder` (or `ReactiveStatusListenableBuilder`).

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

## Git

- Never run any git command (read or write: `status`, `log`, `diff`, `add`, `commit`, `push`, `rebase`…) unless
  explicitly asked to.
- Never add any Claude attribution to commits or pull requests (`Co-Authored-By`, "Generated with Claude Code").
