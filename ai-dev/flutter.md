# Flutter

## Widgets

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

## Widgets

- `State` and `ConsumerState` classes are named `_State`. They are always private:

  ```dart
  // ✅ OK
  class _State extends ConsumerState<ExampleWidget> { ... }

  // ❌ Avoid
  class ExampleWidgetState extends ConsumerState<ExampleWidget> { ... }
  ```
