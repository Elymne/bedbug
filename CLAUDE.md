# dslc_tools

Flutter reference skeleton for the team. Used as a reusable base for all future projects.

## Architecture

# Clean Architecture — Feature-based (Revised)

This project follows **Clean Architecture** with an **object-oriented** approach, organised around **features for business logic**, and a separate **application layer for UI and framework concerns**.

The architecture enforces a strict separation:

- **Features** → business logic only (domain + infrastructure)
- **Application** → UI and framework orchestration
- **Shared** → cross-cutting technical code (no business logic)

---

### High-level structure

The source code is split into three top-level folders:

```
features/
application/
shared/
```

---

### Features (Business layer)

Each feature is a **self-contained business module**.

It contains only business logic and its implementation, split into two layers:

```
features/
  feature_name/
    domain/
    infrastructure/
```

A feature **does not know anything about UI or frameworks**.

---

#### Domain

The **core business logic layer**, completely independent from external systems.

##### Contains

- Entities
- Value objects
- Repository interfaces
- Gateway interfaces
- Use cases
- Domain extensions

##### Rules

- No external dependencies
- No framework imports
- No exceptions thrown
- Errors handled via `Either`

##### Structure

```
domain/
  entities/
  object_values/
  repositories/
  gateways/
  usecases/
  extensions/
  enums/ (only if global to the feature)
```

---

#### Infrastructure

The **implementation layer** of domain contracts.

##### Contains

- Gateway implementations
- Datasources that are Repository implementations (API, DB, SDK)
- Models (DTOs, serialization)

##### Structure

```
infrastructure/
  datasources/
  models/
  gateways/
```

##### Rules

- Can use external libraries
- Can throw exceptions
- Implements domain interfaces only

---

### Application (UI & Framework layer)

The `application/` layer is completely separated from features.

It is responsible for:

- UI (pages, widgets)
- State management (notifiers, controllers)
- Orchestration of use cases
- Framework interaction (Flutter, etc.)

#### Structure

```
application/
  pages/
  widgets/
  controllers/
  notifiers/
```

#### Notes

- Pages can contain their own local widgets and state
- Application depends on **domain only**
- Never depends directly on infrastructure
- This is the **only layer aware of the framework**

---

### Shared (Technical layer)

`shared/` contains only **cross-cutting technical code**.

It must **never contain business logic**, and **never contain UI or widgets**.

Widgets and UI components shared across the app belong in `application/widgets/`, not here.

#### Typical contents

- Base classes and interfaces (`UseCase`, `Repository`, `Either`)
- Error handling (exceptions)
- Logger
- Helpers / utilities
- Technical extensions
- Configuration (SDKs, tools)
- Localization system

#### Example structure

```
shared/
  usecase/
  repository/
  exceptions/
  logger/
  helpers/
  extensions/
  config/
```

#### Rules

- No feature-specific logic
- No business rules
- No domain knowledge
- Structure emerges naturally (no forced layering)

---

### Dependency rules

Strict dependency direction:

```
application → domain → (interfaces) → infrastructure
shared → used by all
```

#### Constraints

- Application depends on **domain only**
- Domain depends on **nothing**
- Infrastructure depends on **domain + shared**
- Shared depends on **nothing**
- Features are isolated from each other

---

### Use cases

Each use case:

- Extends `UseCase<Success, Failure, Params>`
- Exposes `execute(params)`
- Returns `Either<Failure, Success>`

#### Rules

- No exceptions
- Failures are explicit and typed
- Use `NoParams` when no input is required

---

### Entities and Value Objects

#### Entity

Base class for persisted objects:

- `id`
- `createdAt`
- `updatedAt`

##### Rules

- Immutable (`final`)
- `const` constructor
- Equality based on values

---

#### ValueObject

Used for:

- Computed data
- Composite structures
- Concepts without identity

##### Rules

- Immutable (`final`)
- `const` constructor
- Equality based on values

---

### Enums

- Tied to a class → same file
- Shared in feature → `domain/enums/`

---

### Domain extensions

- Feature-specific → `feature/domain/extensions/`
- Cross-cutting → `shared/extensions/`

---

### Repository pattern

Each repository:

- Declared in domain
- Implemented in infrastructure
- Extends `Repository<Entity, Params>`

#### Features

- CRUD operations
- `getMany(params)` → returns `Page<Entity>`

#### Page

`Page<T>` et `OrderBy` sont déclarés dans `shared/domain/`.

`Page<T>` contient :
- `items` : éléments de la page courante
- `hasNextPage` : seul champ garanti, toujours renseigné
- `totalItems` : optionnel — `null` si l'implémentation ne peut pas le calculer
- `totalPages` : optionnel — `null` si l'implémentation ne peut pas le calculer

Dans cette application, la pagination n'est pas utilisée — `limit` est toujours `null`, ce qui retourne tous les éléments en une seule fois (`hasNextPage: false`, `totalItems` renseigné, `totalPages: 1`). Le système est conservé car il pourrait être activé sur ce projet ou réutilisé tel quel sur d'autres projets suivant la même architecture.

#### RepositoryParams

`RepositoryParams` est la classe de base commune à tous les params de `getMany`, déclarée dans `shared/domain/` :
- `page` : numéro de page, commence à 1 (défaut : 1)
- `limit` : nombre max d'éléments. `null` = tous les éléments sans pagination
- `orderBy` : tri optionnel

Chaque repository déclare une sous-classe concrète dans son `domain/repositories/` qui y ajoute ses filtres métier.

#### PageNotFoundException

Levée par l'implémentation infrastructure quand la page demandée n'existe pas.
Les use cases doivent la catcher explicitement et la mapper vers un failure dédié.

---

### Core principles

- One file = one responsibility
- No mixing UI, business, and data access
- Business logic isolated in features
- UI decoupled from infrastructure
- Shared is purely technical

## Code style

### General

- Line length: **120 characters** (`dart.lineLength: 120`).
- Prefer block functions over arrow functions. Never use `=>` on named functions (methods, getters, top-level functions). Reserve `=>` strictly for lambdas (anonymous functions passed as arguments or assigned to variables):

  ```dart
  // ✅ OK — lambda in a collection
  users.map((user) => user.fullName);

  // ✅ OK — block for named functions, even short ones
  String format(String value) {
    return value.trim().toLowerCase();
  }

  // ❌ Avoid — arrow on a named function
  String format(String value) => value.trim().toLowerCase();
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

### Naming

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

## Flutter

### Widgets

- Use `const` everywhere possible — widget constructors, lists, stateless instances (validators, formatters).
- Never use `setState`.
- Prefer inlining widget code directly in `build`. When extraction is needed, apply this rule:
  - **Simple, display-only widget** (no state, no logic, no callbacks) → a private function returning a widget is acceptable.
  - **Widget with logic, callbacks, or reused across files** → extract as a **public** widget class in its own file and folder.

  ```dart
  // ✅ OK — simple display, no logic
  Widget _buildLabel(String text) => Text(text, style: ...);

  // ✅ OK — complex or reused → public widget class
  class UserAvatarWidget extends ConsumerWidget { ... }

  // ❌ Avoid — function for something that has state or callbacks
  Widget _buildForm() => ReactiveForm(...);
  ```
- Avoid `initState` if attributes can be initialized directly. `late final` initializers are lazy — `widget` is accessible at declaration:

  ```dart
  // ✅ OK
  late final TextEditingController _nameController =
      TextEditingController(text: widget.user.name);

  // ❌ Avoid
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
  }
  ```

- In `Column` and `Row`, use `SizedBox` for spacing instead of `Padding`. Reserve `Padding` for isolated widgets outside a layout axis. When all children need uniform spacing, prefer the `spacing` attribute of `Column` or `Row` over inserting `SizedBox` between each child:

  ```dart
  // ✅ OK
  Column(
    children: [
      Text('Title'),
      SizedBox(height: 16),
      Text('Subtitle'),
    ],
  )

  // ❌ Avoid
  Column(
    children: [
      Text('Title'),
      Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text('Subtitle'),
      ),
    ],
  )
  ```

- `State` and `ConsumerState` classes are named `_State`. They are always private:

  ```dart
  // ✅ OK
  class _State extends ConsumerState<ExampleWidget> { ... }

  // ❌ Avoid
  class ExampleWidgetState extends ConsumerState<ExampleWidget> { ... }
  ```

## Libraries

### Riverpod

Riverpod handles both **state management** and **dependency injection**. Every piece of shared state and every dependency is exposed via a provider.

#### Widgets

- Always use `ConsumerStatefulWidget` / `ConsumerState` instead of `StatefulWidget` / `State`. Never use `StatefulWidget` in this project.
- Always use `ConsumerWidget` instead of `StatelessWidget`. Never use `StatelessWidget` in this project.

#### State management

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

#### Dependency injection

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

#### Notifiers

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

#### Conventions

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

### go_router

#### pageBuilder and transitions

Always use `pageBuilder` — never `builder`. On **web**, use `NoTransitionPage` to suppress the default slide animation. On **mobile**, use `MaterialPage` (Android) or `CupertinoPage` (iOS) to preserve native transitions.

```dart
// Web
pageBuilder: (context, state) => const NoTransitionPage(child: ExamplePage())

// Mobile
pageBuilder: (context, state) => const MaterialPage(child: ExamplePage())
```

#### Route paths

Declare every route path as a top-level `const String` in the router file, before the provider. This makes paths referenceable across the app without importing the router widget tree.

```dart
const String loginPath = '/login';
const String usersPath = '/users';
const String userDetailPath = '/users/:id';
```

#### Nested routes

Sub-routes use a **relative** path (no leading `/`). The full path is composed by GoRouter automatically.

```dart
GoRoute(
  path: usersPath,       // '/users'
  routes: [
    GoRoute(path: 'create'),   // resolves to '/users/create'
    GoRoute(path: ':id'),      // resolves to '/users/:id'
  ],
)
```

#### Path parameters

Read path parameters via `state.pathParameters`:

```dart
pageBuilder: (context, state) => NoTransitionPage(
  child: UserDetailPage(userId: state.pathParameters['id']!),
)
```

#### Error page

Always provide an `errorBuilder` pointing to a dedicated error page widget. Never handle unknown routes inline.

### reactive_forms

- Use `reactive_forms`. Never use `TextEditingController`, `ValueNotifier`, or `GlobalKey<FormState>`.
- The `FormGroup` and its controls are `late final` attributes on the widget's `State`, not the notifier. Call `_form.dispose()` in `dispose()`.
- Use `AppValidators` (`core/validators/app_validators.dart`) for all validations. Declare validators on the `FormControl`, not the widget. Each validator is a `const` instance of a private class extending `Validator<dynamic>` — never use plain functions (`ValidatorFunction`).
- Always declare each `FormControl<T>` as a separate typed `late final` attribute, then reference those controls when building the `FormGroup`. This avoids casts when reading values — `_emailControl.value` is already `String?`, no cast needed:

  ```dart
  // ✅ OK
  late final _emailControl = FormControl<String>(
    validators: [AppValidators.required, AppValidators.email],
  );
  late final _passwordControl = FormControl<String>(
    validators: [AppValidators.required, AppValidators.password],
  );
  late final _isRememberMeControl = FormControl<bool>(value: false);
  late final FormGroup _form = FormGroup({
    'email': _emailControl,
    'password': _passwordControl,
    'isRememberMe': _isRememberMeControl,
  });

  // ❌ Avoid — forces casts when reading values
  late final FormGroup _form = FormGroup({
    'email': FormControl<String>(validators: [...]),
    'password': FormControl<String>(validators: [...]),
  });
  // (_form.control('email') as FormControl<String>).value
  ```

- Validate with `_form.valid` before submitting. If invalid, call `_form.markAllAsTouched()` and return:

  ```dart
  if (!_form.valid) {
    _form.markAllAsTouched();
    return;
  }
  ```

- Text fields use `ReactiveTextField<String>`, dropdowns use `ReactiveDropdownField<T>`. For non-standard fields (date pickers, multi-value checkboxes), pass the `FormControl<T>` directly to the child widget and use `ListenableBuilder` to react to changes.

### Localization — flutter_localizations / intl

Localization is handled via `flutter_localizations` and `intl`. All user-facing strings must go through the localization system — never hardcode strings in widgets or notifiers.

#### ARB files

Translation files are `.arb` files located in `shared/application/l10n/`, one per supported locale:

```
shared/application/l10n/
├── app_en.arb
├── app_fr.arb
└── generated/          # never edit manually
```

Each key has a companion `@key` entry carrying a `description`. The description is mandatory — it documents the intent of the string for translators.

```json
{
  "loginButton": "Sign in",
  "@loginButton": {
    "description": "Login button label"
  }
}
```

After every `.arb` modification, run `flutter gen-l10n` to regenerate the localization classes. Never edit files in `generated/` manually.

#### Naming keys

Keys follow a `<feature><Context>` convention in camelCase:

- `loginEmailLabel` — email field label on the login page
- `usersPageTitle` — title of the users page
- `userDetailSaveButton` — save button on the user detail page

Generic, reusable strings use a short unprefixed name: `close`, `loadingDefaultText`, `errorDefaultText`.

## Project

# Project-specific rules

Rules tied to our own implementation choices: how we wire libraries together, which shared widgets to use, and patterns specific to this codebase.

### Colors

Never use color literals (`Color(0xFF...)`) inline in widget code. Always reference a constant from `AppColors`. If the required color does not exist in `AppColors`, add it there first.

---

### Router

The router is declared as a Riverpod `Provider<GoRouter>` in the same file as the route paths. This gives notifiers and use cases access to the router via `ref.read(routerProvider)`.

---

### Localization — accessing translations

**In widgets**, use `AppLocalizations.of(context)!`:

```dart
Text(AppLocalizations.of(context)!.loginButton)
```

**In notifiers and providers** — only applicable if the project uses Riverpod. Declare an `appLocalizationsProvider` (a `StateProvider<AppLocalizations>`) and a `ref.l10n` extension on `Ref` in `shared/application/l10n/app_localizations_provider.dart`. Create this file if it does not exist. Then access translations via `ref.l10n` anywhere a `Ref` is available:

```dart
final message = ref.l10n.loginButton;
```

---

### Locale management

The active locale is managed by `LocaleNotifier` (`localeNotifierProvider`). It initialises from the persisted preference (via `SharedPreferences`), falling back to the system locale, then to English if the system locale is not supported.

To change the locale at runtime, call `ref.read(localeNotifierProvider.notifier).setLocale(locale)`. The change is persisted automatically.

Supported locale codes are defined as a constant list inside `LocaleNotifier`. Add a new code there whenever a new `.arb` file is added.

---

### Shared widgets

All shared widgets live in `shared/application/widgets/`. Always reuse them before creating a new widget. When a new shared widget is added to the codebase, document it here.

#### General

**`AppLoadingButton`** — button with built-in loading state. Disabled and shows `loadingChild` when `isLoading` is `true`; shows `child` and triggers `onTap` otherwise. Accepts an optional `style`.

**`AppLoadingText`** — animated loading indicator displaying text with a letter-by-letter fade-in loop. Defaults to the localised `loadingDefaultText` string if no `text` is provided.

**`AppText`** — animated message widget driven by a `type` parameter (`AppTextType`).

- `AppTextType.error` (default): red text, one-shot shake animation. Defaults to `errorDefaultText`. To replay the animation on a new error, pass a new `Key` (e.g. `ValueKey(errorCounter)`).
- `AppTextType.info`: blue text, smooth looping fade animation between 40 % and 100 % opacity. Defaults to `infoDefaultText`.

**`AppPageHeader`** — standard page title row with an optional back `IconButton`. Accepts `title` and an optional `onBack` callback.

**`AppSnackbar`** — static utility for snackbars. Never instantiated directly.

- `AppSnackbar.showError(context, message)` — red background.
- `AppSnackbar.showSuccess(context, message)` — green background.
  Snackbars do not auto-dismiss; a close button is always shown.

**`AppTag`** — small coloured pill label for statuses, permissions, or categories. Accepts `label` and `color`; the background is derived automatically at reduced opacity.

---

#### Form fields

**`ReactiveAppNameFormField`** — reactive text field for proper names (first name, last name). Blocks digit input in real time. Requires `AppValidators.required` and `AppValidators.noDigits` on the associated `FormControl`. Accepts `formControlName`, `labelText`, `requiredErrorText`, `containsDigitsErrorText`.

**`ReactiveAppDecimalFormField`** — reactive text field for positive decimal numbers. Restricts input to digits and a single decimal separator (`.` or `,`). Requires `AppValidators.decimal` and `AppValidators.notNegative` on the associated `FormControl`. Accepts `formControlName`, `labelText`, `invalidErrorText`, `negativeErrorText`.
