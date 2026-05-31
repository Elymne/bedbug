# Project-specific rules

Rules tied to our own implementation choices: how we wire libraries together, which shared widgets to use, and patterns specific to this codebase.

## Colors

Never use color literals (`Color(0xFF...)`) inline in widget code. Always reference a constant from `AppColors`. If the required color does not exist in `AppColors`, add it there first.

---

## Router

The router is declared as a Riverpod `Provider<GoRouter>` in the same file as the route paths. This gives notifiers and use cases access to the router via `ref.read(routerProvider)`.

---

## Localization — accessing translations

**In widgets**, use `AppLocalizations.of(context)!`:

```dart
Text(AppLocalizations.of(context)!.loginButton)
```

**In notifiers and providers** — only applicable if the project uses Riverpod. Declare an `appLocalizationsProvider` (a `StateProvider<AppLocalizations>`) and a `ref.l10n` extension on `Ref` in `shared/application/l10n/app_localizations_provider.dart`. Create this file if it does not exist. Then access translations via `ref.l10n` anywhere a `Ref` is available:

```dart
final message = ref.l10n.loginButton;
```

---

## Locale management

The active locale is managed by `LocaleNotifier` (`localeNotifierProvider`). It initialises from the persisted preference (via `SharedPreferences`), falling back to the system locale, then to English if the system locale is not supported.

To change the locale at runtime, call `ref.read(localeNotifierProvider.notifier).setLocale(locale)`. The change is persisted automatically.

Supported locale codes are defined as a constant list inside `LocaleNotifier`. Add a new code there whenever a new `.arb` file is added.

---

## Shared widgets

All shared widgets live in `shared/application/widgets/`. Always reuse them before creating a new widget. When a new shared widget is added to the codebase, document it here.

### General

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

### Form fields

**`ReactiveAppNameFormField`** — reactive text field for proper names (first name, last name). Blocks digit input in real time. Requires `AppValidators.required` and `AppValidators.noDigits` on the associated `FormControl`. Accepts `formControlName`, `labelText`, `requiredErrorText`, `containsDigitsErrorText`.

**`ReactiveAppDecimalFormField`** — reactive text field for positive decimal numbers. Restricts input to digits and a single decimal separator (`.` or `,`). Requires `AppValidators.decimal` and `AppValidators.notNegative` on the associated `FormControl`. Accepts `formControlName`, `labelText`, `invalidErrorText`, `negativeErrorText`.
