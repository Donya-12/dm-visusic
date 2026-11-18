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

The application provides a complete Material 3 shell with English and Russian localization, a welcome view, an about view, license display, and the scene editor behind the "New scene" action.

## M1 scene editor and M2 widget engine

The editor is driven by `EditorController`, which owns the project bundle, command history, selection, demo feature frame, decoded images, and evaluated expressions. The scene renderer (`ScenePainter`) is shared by the canvas, library thumbnails, and future export, guaranteeing one drawing implementation.

Widgets are described by JSON manifests validated by `ManifestRegistry`. Parameters generate inspector controls automatically. A safe numeric expression language and a frame-based `BindingResolver` supply `params.*`, `bind.*`, `time.*`, `audio.*`, and `lyric.*` values to renderers. Built-in manifests ship in `visusic_widgets_builtin`, and third-party packs will use the same schema.

## Verification

`tool/check.ps1` resolves the workspace, generates localizations, analyzes every member, and runs all tests. `tool/build_windows.ps1` creates the Windows release and packages a portable archive with license notices.
