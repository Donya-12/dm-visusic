# VisuSic

**Your music, your stage.**

VisuSic is an open-source, offline-first desktop editor for music visualizations and lyric videos. It combines a scene editor, reusable widget packs, audio-reactive graphics, and deterministic video export in one portable application.

> **Project status:** M0 foundation, M1 scene editor, and M2 widget engine are implemented and tested. Audio analysis (M3), lyrics (M4), export (M5), and template packs (M6) are not yet implemented.

## Download for Windows

Portable releases will be published on the [GitHub Releases page](https://github.com/Donya-12/dm-visusic/releases/latest). A release is a ZIP archive: unpack it and run `VisuSic.exe`. No installer or account is required.

## Product principles

- Windows portable builds, with an architecture ready for a future Android target.
- A scene made of editable widgets rather than a fixed list of effects.
- Common and custom aspect ratios, including landscape, portrait, and square.
- Offline-first operation without accounts, telemetry, or cloud storage.
- Deterministic rendering: preview and export use the same timeline.
- Open widget and scene formats without executable third-party scripts.

See [docs/SPEC.md](docs/SPEC.md) for the complete product specification.

## Build from source

### Prerequisites

- Windows 10 or later, x64.
- Git.
- Flutter **3.50.0** on the stable channel.
- Visual Studio 2022 Build Tools with **Desktop development with C++**.

Run `flutter doctor` and resolve any Windows toolchain warnings before building.

### Setup and verification

```powershell
git clone https://github.com/Donya-12/dm-visusic.git
cd dm-visusic
flutter pub get
powershell -ExecutionPolicy Bypass -File tool/check.ps1
powershell -ExecutionPolicy Bypass -File tool/build_windows.ps1
powershell -ExecutionPolicy Bypass -File tool/smoke_windows.ps1
```

The build script creates:

```text
artifacts/visusic-windows-x64-portable.zip
artifacts/visusic-windows-x64-portable.zip.sha256
```

For development, run the application directly:

```powershell
cd apps/visusic
flutter run -d windows
```

The scripts also recognize a project-local SDK at `.tooling/flutter`; this directory is ignored by Git.

## Repository map

```text
apps/visusic                    Flutter Windows application
packages/visusic_core           Project models and commands (pure Dart)
packages/visusic_audio          Audio analysis (pure Dart)
packages/visusic_render         Flutter scene renderer without host OS APIs
packages/visusic_widgets_builtin Built-in widget definitions and renderers
packages/visusic_platform       Host-platform service abstractions (pure Dart)
docs                           Specification, architecture, and ADRs
schemas                        JSON Schema for widget and project files
tool                           Local verification and packaging scripts
```

The repository uses Dart pub workspaces; no additional monorepo tool is required.

## Make your own widget

The widget manifest and pack formats are specified in [section 6 of the specification](docs/SPEC.md#6-система-шаблонов--главная-фича). The step-by-step authoring guide and `.vspack` importer are planned for M6. Third-party packs will use declarative composite widgets or sandboxed shaders, never arbitrary Dart or JavaScript.

## Roadmap

- **M0:** repository, application foundation, design system, CI, portable build. ✅
- **M1:** scene editor, transforms, layers, inspector, undo, project files. ✅
- **M2:** widget engine and library. ✅
- **M3:** audio decoding, analysis, playback, and reactive features.
- **M4:** lyrics and karaoke.
- **M5:** deterministic video export.
- **M6:** community template packs and shaders.
- **M7:** polish, accessibility, presentation mode, Android preparation.

## Contributing and license

See [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). VisuSic is available under the [MIT License](LICENSE). Third-party notices are listed in [THIRD-PARTY.md](THIRD-PARTY.md) and in the application's license page.

Users are responsible for having the necessary rights to the music, artwork, and lyrics they use. VisuSic does not bundle or redistribute third-party songs or lyrics.

---

## Коротко по-русски

VisuSic — будущий бесплатный редактор музыкальной визуализации и лирик-видео для Windows с открытым исходным кодом. Проект работает без аккаунта и облака, а готовая версия будет распространяться portable ZIP-архивом.

Сейчас разрабатывается основа приложения. Полный редактор сцены запланирован на M1. Техническое задание находится в [docs/SPEC.md](docs/SPEC.md).
