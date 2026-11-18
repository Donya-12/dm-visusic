# ADR 0001: Use Dart pub workspaces

- Status: Accepted
- Date: 2026-11-18

## Context

The project has one Flutter application and five local packages. It needs consistent dependency resolution and simple contributor setup without adding a separate monorepo product.

## Decision

Use the Dart 3.14 pub workspace at the repository root. Every package is listed in the root `pubspec.yaml` and uses `resolution: workspace`. Scripts iterate over workspace members for analysis and tests.

## Consequences

One lockfile and one package configuration cover the repository. No additional monorepo executable is needed. The minimum Dart SDK is tied to a recent Flutter release, which is acceptable because Flutter 3.50.0 is the documented prerequisite.
