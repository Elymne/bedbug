# Flutter

## Widgets

- Use `const` everywhere possible — widget constructors, lists, stateless instances (validators, formatters).
- Never use `setState`.
- Never create functions returning widgets or private widgets to split the view. Inline everything in `build`. If a block is too complex or reused across files, extract it as a **public** widget in its own file and folder.
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
