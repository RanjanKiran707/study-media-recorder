# 📱 Study Media Recorder

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-194%20Passing-brightgreen?style=for-the-badge&logo=checkmarx&logoColor=white)](test/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20Layered-blue?style=for-the-badge)](project_specs/flutter_arch_general.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

An offline-first Android application designed for focused study revision. Record bite-sized audio and video explanations (up to ~2 minutes), organize them into custom nested folders and subfolders, and play back any folder continuously as an auto-advancing playlist.

> **🚀 [Try the Live Web Demo](https://study-media-recorder.web.app)**  
> **📦 [Download Android Release APK (v1.0.0)](https://github.com/RanjanKiran707/study-media-recorder/releases/tag/v1.0.0)**

---

<p align="center">
  <img src="docs/app_icon_preview.png" width="128" alt="Study Media Recorder Icon">
</p>

## ✨ Key Features

- **Quick Media Recording:** Record high-quality audio or video explanations with native camera and microphone APIs.
- **Hierarchical Library:** Organize explanations into folders and subfolders with customizable nesting.
- **Continuous Playlist Playback:** Play all recordings inside a folder seamlessly in sequence for hands-free revision.
- **Offline-First & Zero Friction:** Built with 100% on-device local storage. No logins, tracking, or cloud latency.

---

## 🏛️ Engineering & Architecture

This application was engineered with a production-grade, test-driven mindset following strict architectural discipline:

### 1. Layered Architecture (`core` ➔ `data` ➔ `domain` ➔ `features`)
- **Strict Dependency Rule:** Outer layers depend on inner layers; `data` and `domain` have zero knowledge of UI widgets.
- **Functional Error Handling:** Standardized `Result<T>` monad pattern (`Result.success` and `Result.failure`) to eliminate unhandled runtime exceptions.
- **Clean State Management:** UI reacts to stream-based repository changes with explicit `ViewState` models.

### 2. Custom Architectural Lint Testing
In [`test/architecture/no_material_test.dart`](test/architecture/no_material_test.dart), automated tests parse Dart source files in `lib/` using regular expressions to enforce:
- **Zero Material Dependency:** Ensures no file imports `package:flutter/material.dart` and no Material components (`Scaffold`, `AppBar`, `ElevatedButton`, etc.) are referenced.
- **Design System Isolation:** The UI uses only `package:flutter/widgets.dart` and Cupertino icons, guaranteeing a consistent custom aesthetic.

### 3. Comprehensive Test Coverage (194 Automated Tests)
The test suite validates the system across every layer:
- **3 Architecture Tests:** Verify strict design system boundaries.
- **10 Core Tests:** Validate `Result<T>`, stream combinators, and time formatters.
- **30 Data Layer Tests:** Test local file repositories, folder hierarchies, and reactive streams.
- **68 Domain Business Tests:** Full use case coverage for player, recorder, and playlist sequencing.
- **83 Feature & ViewModel Tests:** Validate widget interactions, state transitions, and UI flows.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.x or later)
- Android SDK or connected device / emulator

### Setup & Run
```bash
# Clone the repository
git clone https://github.com/RanjanKiran707/study-media-recorder.git
cd study-media-recorder

# Install dependencies
flutter pub get

# Run on Android
flutter run

# Run the full test suite (194 tests)
flutter test
```

---

## 📚 Technical Documentation

- [Product Specifications](project_specs/product_spec.md)
- [Architecture Guide & Rules](project_specs/flutter_arch_general.md)
- [Development Process & Conventions](project_specs/flutter_development_process.md)
- [Dependency Analysis](docs/dependencies.md)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
