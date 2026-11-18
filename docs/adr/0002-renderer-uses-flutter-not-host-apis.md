# ADR 0002: Renderer uses Flutter but not host APIs

- Status: Accepted
- Date: 2026-11-18

## Context

The initial specification described `visusic_render` as pure Dart while also requiring `CustomPainter`, `ui.Image`, and `FragmentProgram`. Those APIs are provided by the Flutter SDK, not by a standalone Dart SDK.

## Decision

Make `visusic_render` a Flutter package while prohibiting `dart:io`, Win32, process execution, and platform-specific binaries inside it. Keep project models, audio analysis, and platform service abstractions as pure Dart packages.

## Consequences

Canvas and shader code can live in the renderer without artificial wrappers. The same renderer remains suitable for Windows and Android because Flutter supplies the rendering APIs on both platforms. Host-specific behavior stays behind `visusic_platform` interfaces and application-level implementations.
