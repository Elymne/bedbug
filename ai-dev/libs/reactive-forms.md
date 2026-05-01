## Forms

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
