# QR Tool

A privacy-minded QR utility built with Flutter, Clean Architecture, and Riverpod.

## Architecture

```
lib/
  app/         # Application bootstrap, DI, routing, theming
  core/        # Cross-cutting error, result and utility helpers
  domain/      # Pure Dart entities, value objects, repositories, use cases
  data/        # Hive-backed persistence, device integrations, repository impls
  features/    # Presentation layer per feature (scan, generate, history, settings)
```

## Features

* Live QR scanning with history capture.
* Offline QR generation with PNG export and history storage.
* History management with favorites, delete, and PDF export.
* Settings panel with analytics toggle and bulk history clearing.

## Getting started

```
flutter pub get
flutter run
```

The project targets Flutter 3.x and Dart 3. Ensure device permissions are granted for camera access when scanning.
