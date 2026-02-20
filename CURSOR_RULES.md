### FriendsRide – Development Rules (Cursor)

These rules are enforced automatically before and after every implementation step to prevent regressions and maintain a zero‑warning codebase.

## 1) Auto‑analysis and zero‑warnings policy
- **Always run** `flutter analyze` after each logical implementation step and fix **all errors and warnings to zero**, without interruption.
- On this machine, Flutter is available at: `C:\Users\flori\AppData\Local\dev\bin\flutter.bat`.
  - Command: `C:\Users\flori\AppData\Local\dev\bin\flutter.bat analyze`
- Prefer `flutter clean` over any Gradle clean. Only use Gradle cache cleanup via PowerShell when strictly necessary.

## 2) Preflight checklist (run BEFORE any implementation)
- **Service verification**
  - Use only existing services in `lib/services/`. Do not create new ones unless absolutely necessary.
  - Verify method/class existence and signatures before calling.
  - Quick check (Windows PowerShell): `Get-Content "lib/services/[service_name].dart" | Select-String -Pattern "class|void|Future"`
- **Import and naming conflicts**
  - Watch for collisions like `Route` from Flutter vs project types; use `hide` or `as` aliases.
  - Use `as ui` for `dart:ui` when needed (e.g., `ui.Size`).
  - Avoid duplicate imports; prefer relative imports for project files.
- **Enums and constants**
  - Verify the enum values exist (single source of truth). Do not duplicate enums across files.
- **Null-safety and async context**
  - Guard UI updates with `mounted` and use `if (!context.mounted) return;` after awaits before using `context`.
- **Mapbox specifics**
  - `SymbolLayer.textField` expects a String token (e.g., `'{point_count_abbreviated}'`).
  - `MapAnimationOptions` uses named parameters; avoid duplicate/extra positional args.
  - Use `toARGB32()` and color channel accessors (`.r/.g/.b`) instead of deprecated `Color.red/green/blue`.
  - For `cameraForCoordinateBounds`, verify argument types and edge insets.
- **UI deprecations and styling**
  - Replace `withOpacity` with `withValues(alpha: ...)` or `withAlpha(...)` consistently.
- **Provider/DI**
  - Ensure required providers are registered (e.g., `ChangeNotifierProvider<PassengerVoiceControllerAdapter>`) before reading.
- **Performance hygiene**
  - Prefer debouncing/throttling for camera/route/POI updates; offload heavy work to isolates when possible.

## 3) Catalog of common errors/warnings and fix methods

- **unused_element / unused_field / unused_local_variable**: Remove, or integrate into logic if needed.
- **prefer_final_fields**: Mark private fields as `final` when not reassigned.
- **argument_type_not_assignable**: Fix types; e.g., cast `num → double`, ensure Mapbox types match (`List<List<num>> → List<List<double>>`).
- **expected_token / unterminated_string_literal**: Fix bracket/parenthesis/quote mismatches; remove duplicate argument blocks.
- **invalid_assignment**: Avoid assigning incompatible types (e.g., rely on inference or use `ui.Size`).
- **ProviderNotFoundException**: Register the provider in `main.dart` before `read/watch`.
- **invalid_null_aware_operator**: Remove `?.` where target is non-null (e.g., `cam.bearing.abs()`).
- **extra_positional_arguments(_could_be_named)**: Use named params; remove duplicated `MapAnimationOptions` blocks.
- **missing_required_argument**: Supply all required named args.
- **undefined_method / undefined_class / undefined_identifier / undefined_function / undefined_name**: Add imports or implement/replace with existing project methods; use extensions (e.g., `PoiCategoryExtension`).
- **deprecated_member_use**: Replace legacy APIs (`withOpacity` → `withValues/withAlpha`, `Color.red/green/blue` → channel accessors, etc.).
- **duplicate_import**: Remove the redundant import.
- **non_type_as_type_argument / creation_with_non_type**: Ensure the correct type symbol is imported and used (e.g., `FrameTiming`).
- **no_leading_underscores_for_local_identifiers**: Rename locals to follow lint rules.
- **use_build_context_synchronously**: After `await`, guard with `if (!context.mounted) return;` before using `context`.

## 4) Enforcement
- Before any change: run the full preflight checklist above.
- After any change: run `flutter analyze` and fix all issues to zero before moving on.
- Prefer modifying existing infrastructure (services, providers, flows) over introducing new classes; preserve voice functions and driver/passenger flows.

## 5) Windows and tooling notes
- Flutter/Dart binaries (on this machine): `C:\Users\flori\AppData\Local\dev\bin`.
- For Flutter projects, use `flutter clean` (not `gradle clean`).
- Gradle cache cleanup (only if necessary):
  - PowerShell: `Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches"`



