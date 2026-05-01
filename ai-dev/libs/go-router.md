## Routing

### pageBuilder and transitions

Always use `pageBuilder` — never `builder`. On **web**, use `NoTransitionPage` to suppress the default slide animation. On **mobile**, use `MaterialPage` (Android) or `CupertinoPage` (iOS) to preserve native transitions.

```dart
// Web
pageBuilder: (context, state) => const NoTransitionPage(child: ExamplePage())

// Mobile
pageBuilder: (context, state) => const MaterialPage(child: ExamplePage())
```

### Route paths

Declare every route path as a top-level `const String` in the router file, before the provider. This makes paths referenceable across the app without importing the router widget tree.

```dart
const String loginPath = '/login';
const String usersPath = '/users';
const String userDetailPath = '/users/:id';
```

### Nested routes

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

### Path parameters

Read path parameters via `state.pathParameters`:

```dart
pageBuilder: (context, state) => NoTransitionPage(
  child: UserDetailPage(userId: state.pathParameters['id']!),
)
```

### Error page

Always provide an `errorBuilder` pointing to a dedicated error page widget. Never handle unknown routes inline.
