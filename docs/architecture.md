# Architecture

VisuSic is a single-repository Dart pub workspace. Product code is split by responsibility rather than by operating system.

## Dependency direction

```text
apps/visusic
  ├── visusic_widgets_builtin ── visusic_render ── visusic_core
  ├── visusic_audio
  └── visusic_platform

Host-specific implementations belong in apps/visusic/lib/platform.
```

A dependency never points back toward the application. Core project logic does not import Flutter, `dart:io`, Win32, or platform binaries.

## Package responsibilities

- `visusic_core`: versioned project documents, commands, undo, parameters, and expressions.
- `visusic_audio`: deterministic offline analysis and audio-feature contracts.
- `visusic_render`: Flutter canvas, layout, painters, and shaders. Flutter is a UI/rendering dependency, not a host-platform dependency.
- `visusic_widgets_builtin`: built-in manifests and native renderers.
- `visusic_platform`: interfaces for decoding, encoding, files, and networking.
- `apps/visusic`: Material 3 UI, feature composition, routing, localization, and Windows implementations.

## M0 application shell

The application currently provides a complete foundation shell: custom Material 3 light/dark themes, English and Russian localization, a welcome view, an about view, and license display. Editor interactions are intentionally introduced as working vertical slices in M1 rather than exposed as inactive controls in M0.

## Verification

`tool/check.ps1` resolves the workspace, generates localizations, analyzes every member, and runs all tests. `tool/build_windows.ps1` creates the Windows release and packages a portable archive with license notices.
