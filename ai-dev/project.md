# Project-specific rules

Rules tied to our own implementation choices: how we wire libraries together, which shared widgets to use, and patterns specific to this codebase.

---

## Router

The router is declared as a Riverpod `Provider<GoRouter>` in the same file as the route paths. This gives notifiers and use cases access to the router via `ref.read(routerProvider)`.

### Authentication guard

Auth logic is centralised in the `redirect` callback — never inside individual pages. Auth state is read synchronously with `ref.read`. Returning `null` allows navigation; returning a path string redirects.

### Auth state refresh

Auth state changes are connected to the router via a private `_RouterRefreshNotifier extends ChangeNotifier`, passed to `refreshListenable`. It listens to `currentUserNotifierProvider` with `ref.listen` and calls `notifyListeners()` on every change, triggering a redirect re-evaluation.

```dart
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(currentUserNotifierProvider, (_, _) => notifyListeners());
  }
}
```

### ProtectedRoute

Use the `ProtectedRoute` widget to restrict access to a page based on user permissions. Wrap the page child inside `pageBuilder` — do not handle permission checks inside the page itself.

```dart
pageBuilder: (context, state) => const NoTransitionPage(
  child: ProtectedRoute(
    permissions: [UserPermission.manageUsers],
    child: UsersPage(),
  ),
)
```

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

### Layout

**`AppLayout`** — base layout for all main pages. Composes `AppSidebar` + `AppTopBar` + a constrained content area. Use this on every authenticated page.
- `child`: the page content.
- `isScrollable` (default `true`): wraps content in `SingleChildScrollView`. Set to `false` for full-height or centred content.
- `title`: page title shown in the top bar.
- `onBack`: if provided, shows a back button in the top bar.

**`AppSidebar`** — collapsible left navigation sidebar. Menu items are driven by `appMenuItemsProvider`, which filters `AppMenuItem` entries based on the current user's permissions. To add a nav entry, add an `AppMenuItem` to that provider.

**`AppTopBar`** — top bar with optional back button, page title, language switcher, account button, and logout button.
- `title`: displayed on the left.
- `onBack`: if provided, shows a back arrow.

---

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

### Data table

**`AppDataTable<T>`** — generic sortable table. Renders a header row and one row per item. Sort state is managed by the parent.
- `columns`: list of `AppTableColumn<T>`.
- `items`: entities on the current page.
- `onSort(String field)`: called when a sortable header is tapped.
- `currentOrderBy`: active sort, used to render the direction indicator.
- `expandedRowBuilder` (optional): builds a full-width widget below each data row.

**`AppTableColumn<T>`** — column definition for `AppDataTable`.
- `label`: header text.
- `cellBuilder(T item)`: builds the cell widget.
- `sortField` (optional): field name passed to `OrderBy` on sort. `null` means not sortable.
- `flex` (default `1`): relative width weight.

**`AppSearchInput`** — reactive search field with a clear button. Takes a `FormControl<String>` declared as `late final` on the parent `State` and disposed in `dispose`. Accepts an optional `hintText`.

**`AppCursorPager<T>`** — cursor-based pagination control for Firestore. The parent maintains a `List<String?>` cursor history stack (`null` = first page). Accepts `page`, `hasPrevious`, `onNext(CursorPagination)`, and `onPrevious`. Hidden when `page.total == 0`.

**`AppOffsetPager`** — offset-based pagination control with numbered pages, ellipsis, and prev/next buttons. Not compatible with Firestore — use `AppCursorPager` instead. Accepts `total`, `currentPagination`, and `onPageChanged(OffsetPagination)`. Hidden when there is only one page.

---

### Form fields

**`ReactiveAppNameFormField`** — reactive text field for proper names (first name, last name). Blocks digit input in real time. Requires `AppValidators.required` and `AppValidators.noDigits` on the associated `FormControl`. Accepts `formControlName`, `labelText`, `requiredErrorText`, `containsDigitsErrorText`.

**`ReactiveAppDecimalFormField`** — reactive text field for positive decimal numbers. Restricts input to digits and a single decimal separator (`.` or `,`). Requires `AppValidators.decimal` and `AppValidators.notNegative` on the associated `FormControl`. Accepts `formControlName`, `labelText`, `invalidErrorText`, `negativeErrorText`.
