sweet — here’s a **production-grade plan doc** for a **Flutter QR Scanner & Generator app** built with **Clean Architecture + MVVM** using **Riverpod**, with a complete file structure, conventions, and implementation blueprints.

---

# Product overview

**Goal:** A privacy-first, offline-capable QR tool that scans, generates, and organizes codes with a polished UX and reliable performance on Android & iOS (Web/Desktop optional).

**Primary user jobs**

* Scan QR/barcodes quickly (camera or gallery).
* Generate QR codes from URL, text, Wi-Fi, contact (vCard), email, phone, SMS.
* Save, favorite, tag, share, and export codes (PNG, PDF).
* Optional batch scanning, custom styles, and cloud export.

**Non-goals (v1.0):** Real-time collaborative sync, multi-user accounts.

---

# Architecture

## Stack

* **Language:** Dart 3, Flutter 3.x+
* **Architecture:** Clean Architecture (layers) + **MVVM** (Presentation) + **Riverpod** for DI/state
* **Navigation:** `go_router`
* **Local storage:** `hive` (+ adapters) for history; `shared_preferences` for simple flags
* **Scanner:** `mobile_scanner` (MLKit-backed)
* **Generator:** `qr_flutter`, `barcode` (other symbologies)
* **Images/Export:** `image`, `share_plus`, `printing` (PDF)
* **Permissions:** `permission_handler`
* **Telemetry (opt-in):** `firebase_analytics`, `sentry_flutter` (crash/error)

## Layered design

```
/lib
  /app                 # app wiring (router, theme, DI)
  /core                # cross-cutting: errors, result, logger, utils
  /features
    /scan              # scanning feature module
    /generate          # generating feature module
    /history           # history management module
    /settings          # settings & privacy module
  /data                # concrete repositories, DTOs, sources (local, device)
  /domain              # entities, value objects, repo contracts, use cases
```

**Boundaries**

* `presentation` (VMs/Controllers & UI) → **depends on** `domain` use cases only.
* `domain` → **pure Dart**: no Flutter imports.
* `data` → implements `domain` repositories; talks to **Hive**, **camera/MLKit**, file system, etc.
* `core` → small, framework-free helpers (`Either/Result`, `AppError`, logging, env).

---

# File structure (full)

```
lib/
  main.dart
  app/
    app.dart
    bootstrap.dart
    router.dart
    theme/
      app_theme.dart
      theme_extensions.dart
    di/
      providers.dart            # Riverpod providers & wiring
    env/
      env.dart                  # typed env access
  core/
    error/app_error.dart
    error/failure_codes.dart
    functional/result.dart      # sealed Result<T>
    utils/guards.dart
    utils/uri_utils.dart
    utils/validators.dart
    logging/logger.dart
  domain/
    entities/
      qr_item.dart
      qr_type.dart
    value_objects/
      uuid.dart
      non_empty_string.dart
      url_vo.dart
    repositories/
      scan_repository.dart
      generator_repository.dart
      history_repository.dart
      export_repository.dart
    usecases/
      scan_code_uc.dart
      decode_image_uc.dart
      generate_qr_uc.dart
      save_item_uc.dart
      fetch_history_uc.dart
      toggle_favorite_uc.dart
      delete_item_uc.dart
      export_png_uc.dart
      export_pdf_uc.dart
  data/
    models/
      qr_item_model.dart        # HiveType + from/to entity
    sources/
      local/
        hive_storage.dart
        hive_boxes.dart
        hive_adapters.dart
      device/
        camera_scanner.dart     # mobile_scanner wrapper
        image_decoder.dart
        file_exporter.dart
        pdf_maker.dart
    repositories/
      scan_repository_impl.dart
      generator_repository_impl.dart
      history_repository_impl.dart
      export_repository_impl.dart
  features/
    scan/
      presentation/
        scan_screen.dart
        scan_vm.dart
        scan_state.dart
        widgets/scan_overlay.dart
      application/
        scan_mapper.dart        # raw -> entity mapping helpers
    generate/
      presentation/
        generate_screen.dart
        generate_vm.dart
        generate_state.dart
        widgets/qr_preview.dart
    history/
      presentation/
        history_screen.dart
        history_vm.dart
        history_state.dart
        widgets/history_list.dart
    settings/
      presentation/
        settings_screen.dart
        settings_vm.dart
        settings_state.dart
  l10n/                         # arb files for localization
  gen/                          # generated code (build_runner if needed)
```

---

# Domain model

```dart
enum QrType { text, url, wifi, contact, email, phone, sms }

class QrItem {
  final String id;                // uuid v4
  final QrType type;
  final String raw;               // canonical payload/URI
  final Map<String, String>? meta;// e.g., ssid, name, tel
  final DateTime createdAt;
  final bool favorite;
  final List<String> tags;
  const QrItem({
    required this.id,
    required this.type,
    required this.raw,
    this.meta,
    required this.createdAt,
    this.favorite = false,
    this.tags = const [],
  });
}
```

**Result & Error**

```dart
sealed class AppError {
  const AppError();
}
class PermissionDenied extends AppError {}
class CameraUnavailable extends AppError {}
class DecodeFailed extends AppError {}
class StorageFailure extends AppError {}
class ValidationError extends AppError { final String message; ValidationError(this.message); }

sealed class Result<T> { const Result(); }
class Ok<T> extends Result<T> { final T value; const Ok(this.value); }
class Err<T> extends Result<T> { final AppError error; const Err(this.error); }
```

---

# Repository contracts (domain)

```dart
abstract interface class ScanRepository {
  Future<Result<QrItem>> scanLive();              // camera stream (debounced in impl)
  Future<Result<QrItem>> decodeFromImage(String path);
}

abstract interface class GeneratorRepository {
  Future<Result<Uint8List>> generatePng({
    required String data,
    QrType type = QrType.text,
    int size = 1024,
    Map<String, dynamic>? style, // logo, roundness, margin
  });
}

abstract interface class HistoryRepository {
  Future<Result<List<QrItem>>> fetch({String? query, List<String>? tags});
  Future<Result<void>> save(QrItem item);
  Future<Result<void>> toggleFavorite(String id);
  Future<Result<void>> delete(String id);
  Stream<List<QrItem>> watch(); // realtime updates for UI
}

abstract interface class ExportRepository {
  Future<Result<String>> savePngToDownloads(Uint8List bytes, {String? fileName});
  Future<Result<String>> exportPdf(List<QrItem> items, {String? fileName});
}
```

---

# Use cases (domain)

* `ScanCodeUc(ScanRepository)`
* `DecodeImageUc(ScanRepository)`
* `GenerateQrUc(GeneratorRepository)` → returns PNG bytes
* `SaveItemUc(HistoryRepository)`
* `FetchHistoryUc(HistoryRepository)`
* `ToggleFavoriteUc(HistoryRepository)`
* `DeleteItemUc(HistoryRepository)`
* `ExportPngUc(ExportRepository)`
* `ExportPdfUc(ExportRepository)`

Each UC is a thin synchronous/asynchronous function that returns `Result<T>` and never throws across the boundary.

---

# Data layer (impls)

## Models & persistence (Hive)

* `qr_item_model.dart`: `@HiveType(typeId: 1)` with fields mirroring `QrItem`.
* `toEntity()/fromEntity()` mappers isolate framework code from domain.
* `hive_boxes.dart`: constants & lazy box openers.
* **Migrations:** bump `typeId` only when schema changes; add default values gracefully.

## Device services

* `camera_scanner.dart`: wraps `mobile_scanner` and exposes a debounced single-shot `scanOnce()` plus stream cancelation.
* `image_decoder.dart`: uses `mobile_scanner`/`zxing` via package to decode PNG/JPG.
* `file_exporter.dart`: writes to app dir or public downloads; strips EXIF.
* `pdf_maker.dart`: composes QR images on A4 grid using `printing`/`pdf` package.

---

# Presentation (MVVM with Riverpod)

## State classes (immutable)

```dart
sealed class ScanState {
  const ScanState();
}
class ScanIdle extends ScanState { const ScanIdle(); }
class ScanLive extends ScanState { final bool torchOn; const ScanLive({this.torchOn=false}); }
class ScanSuccess extends ScanState { final QrItem item; const ScanSuccess(this.item); }
class ScanError extends ScanState { final AppError error; const ScanError(this.error); }
```

## ViewModels (Notifier)

```dart
final scanVmProvider = StateNotifierProvider.autoDispose<ScanVm, ScanState>((ref) {
  final scan = ref.watch(scanRepoProvider);
  final saveUc = ref.watch(saveItemUcProvider);
  return ScanVm(scan, saveUc);
});

class ScanVm extends StateNotifier<ScanState> {
  final ScanRepository _scan;
  final SaveItemUc _save;
  ScanVm(this._scan, this._save): super(const ScanIdle());

  Future<void> start() async {
    state = const ScanLive();
    final res = await _scan.scanLive();
    switch (res) {
      case Ok(value: final item):
        await _save(item);
        state = ScanSuccess(item);
      case Err(error: final e):
        state = ScanError(e);
    }
  }

  void reset() => state = const ScanIdle();
}
```

## UI & navigation

* **`go_router`** with typed routes:

  * `/scan`, `/generate`, `/history`, `/settings`, `/details/:id`
* Deep links for `app://scan` and `app://generate?data=...`

---

# Conventions & quality

## Dart/Flutter style

* `flutter_lints` (strict), no unused code, single-source constants.
* Avoid business logic in widgets. Widgets are dumb; VMs handle actions.
* Keep methods small; prefer `extension` helpers for mapping/formatting.

## Dependency Injection (Riverpod)

* All repos/UCs are **providers** in `app/di/providers.dart`.
* Swap implementations easily (e.g., use mock repos for tests).

```dart
final hiveBoxProvider = Provider<LazyBox<QrItemModel>>((ref) => ...);

final historyRepoProvider = Provider<HistoryRepository>((ref) =>
  HistoryRepositoryImpl(ref.watch(hiveBoxProvider), ref.watch(loggerProvider)));
```

## Error handling

* Return `Result<T>` from the data & domain; map known exceptions to `AppError`.
* Show **non-blocking** snackbars for minor issues; full-screen error only for hard blocks (camera permission denied).
* Central `logger` pipe (console in debug, Sentry in release).

## Permissions UX (iOS & Android)

* Explain **why** before requesting.
* Fallback to “Upload image to decode” if camera denied.
* Android: add `android.permission.CAMERA`; iOS: `NSCameraUsageDescription`.

## Security & privacy

* No auto-open of URLs; show **domain preview** & HTTPS indicator.
* Strip EXIF from exports; default offline. Telemetry strictly opt-in.
* Validate URL schemes; warn on `http://`, IPs, or known malicious patterns.
* Don’t store PII beyond what user saves (e.g., vCard fields). Provide “Clear all data”.

## Performance targets

* First decode < 500ms on mid-range Android.
* Memory < 200MB peak during batch scan.
* 60fps camera preview with overlay.
* Code gen PNG ≥ 1024px with crisp edges.

## Accessibility & i18n

* `l10n` with ARB; English default. Copy is short & descriptive.
* Large tap targets (≥ 48dp), semantic labels for buttons, dynamic type tested.

---

# Feature specs (MVP)

## Scan

* Live camera scan (pause on first result; “Scan again” action).
* Torch toggle, pinch-to-zoom (when supported).
* Gallery import & decode.
* Actions by type: open URL, copy, share, call/SMS, save Wi-Fi (where possible).

## Generate

* Input tabs: Text/URL, Wi-Fi, Contact, Email, Phone, SMS.
* Instant preview, DPI slider (512–2048px).
* Save PNG, share intent, copy to clipboard.
* (v1+) Styling: logo overlay, rounded modules, color; guard contrast for scannability.

## History

* List with search, tags, favorites, swipe delete (with undo).
* Details screen: full QR, raw payload, quick actions.
* Export: single PNG, or multi-select → PDF sheet.

## Settings

* Theme (system/light/dark), language, link safety prefs.
* Data: Clear history, import/export JSON (v1+).
* Telemetry opt-in (crash/analytics).

---

# Data & parsing

### QR payload builders

* **Wi-Fi**: `WIFI:T:WPA;S:<ssid>;P:<password>;H:false;;`
* **vCard** 3.0: `BEGIN:VCARD\nVERSION:3.0\nN:Doe;John;;;\nTEL;TYPE=CELL:...`

### Parsing utilities

* Domain **parsers** to map raw → `QrType` + `meta`.
* `uri_utils.dart`: sanitize, normalize URLs; tld & scheme checks.

---

# Pubspec (suggested)

```yaml
environment:
  sdk: ">=3.4.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  mobile_scanner: ^6.0.0
  qr_flutter: ^4.1.0
  barcode: ^2.2.8
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  permission_handler: ^11.3.0
  path_provider: ^2.1.3
  share_plus: ^10.0.0
  url_launcher: ^6.3.0
  intl: ^0.19.0
  package_info_plus: ^8.0.0
  sentry_flutter: ^8.7.0
  firebase_analytics: ^11.3.0
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.3
  build_runner: ^2.4.9
  hive_generator: ^2.0.1
  golden_toolkit: ^0.15.0
  flutter_lints: ^4.0.0
```

> Versions are examples; pin/upgrade as needed during setup.

---

# App wiring

## `main.dart` & bootstrap

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(QrItemModelAdapter());
  await Bootstrap.configure(); // logger, sentry, env, boxes
  runApp(ProviderScope(child: const App()));
}
```

## Router

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
    GoRoute(path: '/generate', builder: (_, __) => const GenerateScreen()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
  initialLocation: '/scan',
);
```

## Theme

* Single source of truth in `app_theme.dart` with color scheme & typography.
* Add a **ThemeExtension** for brand spacings/radii.

---

# Testing strategy

**Unit**

* Parsers (URL, Wi-Fi, vCard), UCs (happy/edge cases), repository mapping.
* Result/error mapping; validators.

**Widget**

* Scan overlay (torch, mask), generate preview interactions, history list (search, favorites, undo).

**Golden**

* Key screens in light/dark; small/large text sizes.

**Integration**

* Hive persistence lifecycle; camera denied flow; gallery import & decode.

**Performance**

* Frame build time under 16ms; memory snapshots pre/post batch scan.

---

# CI/CD

**CI (GitHub Actions)**

* Jobs: `flutter analyze`, `flutter test --coverage`, golden tests (cache fonts), build debug APK/IPA (no signing).
* Artifacts: coverage report, app bundles.

**CD**

* Optional Fastlane for Play Internal Testing & TestFlight.
* Increment build numbers automatically; attach changelog from Conventional Commits.

---

# Build variants & config

* Flavors: `dev`, `staging`, `prod` with separate app ids & icons.
* Typed `Env` class with `const` constructors for feature flags (e.g., enable analytics).
* Secret management: no secrets in repo; use CI vars; runtime toggles only.

---

# Analytics & crash handling (opt-in)

* Prompt once in onboarding; off by default.
* Events: scan_success, scan_error, generate_success, export_png/pdf, history_actions.
* Crash: `sentry_flutter` with PII disabled; attach app version, platform.

---

# Accessibility checklist (must pass)

* Semantics on actionable icons.
* Contrast AA for text & icons on camera preview overlay.
* Focus traversal & talkback/voiceover tested.

---

# Release readiness (store)

* **App privacy** section: “Data stored on device”, no tracking.
* Clear screenshots (light & dark), short video of scanning/generating.
* Localized store copy (EN first).

---

# Risks & mitigations

* **Device camera quirks:** Feature-detect torch/zoom; provide gallery fallback.
* **Decode duplicates:** Debounce results; pause preview after first success.
* **Export quality:** Render QR at high DPI; test minimum module size.
* **iOS review:** Include permission purpose strings; no background camera use.

---

# Delivery roadmap (4 weeks)

**Week 1 – Foundations**

* Project, routing, theming, DI skeleton.
* Domain entities/repos/UCs; Hive bootstrap & adapters.
* Placeholder screens.

**Week 2 – Scanner & Generator**

* `mobile_scanner` integration + overlay.
* Generate PNG + preview; save/share.
* Basic history save/fetch/watch.

**Week 3 – Types & UX**

* Wi-Fi, vCard, email/phone/SMS forms + validation.
* History: search, tags, favorites, delete/undo.
* Link safety banner, open-with actions.

**Week 4 – Hardening**

* Gallery decode, empty states, onboarding.
* Tests (unit/widget/golden), polish, a11y & perf passes.
* Store assets & release candidates.

---

# Example snippets

## Generate VM

```dart
final generateVmProvider =
  StateNotifierProvider.autoDispose<GenerateVm, GenerateState>((ref) {
    return GenerateVm(
      ref.watch(generateQrUcProvider),
      ref.watch(exportPngUcProvider),
    );
  });

class GenerateVm extends StateNotifier<GenerateState> {
  final GenerateQrUc _generate;
  final ExportPngUc _export;
  GenerateVm(this._generate, this._export) : super(const GenerateState());

  Future<void> updateData(String data) async {
    state = state.copyWith(data: data);
    if (data.isEmpty) return;
    final res = await _generate(data: data, type: inferType(data));
    switch (res) {
      case Ok(value: final bytes): state = state.copyWith(png: bytes);
      case Err(error: final e): state = state.copyWith(error: e);
    }
  }

  Future<void> savePng() async {
    final png = state.png;
    if (png == null) return;
    await _export(png, fileName: "qr_${DateTime.now().millisecondsSinceEpoch}");
  }
}
```

## Scan Screen Outline

```dart
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(scanVmProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              facing: CameraFacing.back,
              detectionSpeed: DetectionSpeed.normal,
            ),
            onDetect: (_) => ref.read(scanVmProvider.notifier).start(),
          ),
          const ScanOverlay(),
          if (vm is ScanError) _ErrorBanner(vm.error),
        ],
      ),
    );
  }
}
```

---

# Definition of Done (v1.0)

* ✅ All MVP user stories met; acceptance tests pass.
* ✅ No crashes in internal testing; Sentry shows zero unhandled errors.
* ✅ 95%+ critical path coverage (parsers, repos, UCs).
* ✅ A11y checks pass; devices: low-end Android, modern iPhone.
* ✅ Store metadata ready; CI artifacts reproducible.

---

# Backlog (post-v1)

* Batch scanning (continuous mode with distinct result list)
* Custom styles & logo overlay with contrast guard
* Collections/folders; smart tags
* JSON import/export of history
* Desktop/Web camera support (feature-gated)
* Link reputation check (on-device heuristics only)
* 