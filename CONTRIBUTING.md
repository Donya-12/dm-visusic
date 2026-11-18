# Contributing to VisuSic

Thank you for helping build VisuSic.

## Ground rules

- Keep changes focused and follow the milestone scope in `docs/SPEC.md`.
- Write code and project documentation in English.
- Do not add accounts, telemetry, cloud dependencies, or arbitrary third-party code execution.
- Keep `visusic_core`, `visusic_audio`, and `visusic_platform` independent of Flutter and host operating system APIs.
- Keep host APIs out of `visusic_render`; it may use Flutter but not `dart:io`, Win32, or bundled platform binaries.
- Add an SPDX license header to every Dart source file.
- Add tests for behavior that can regress and an ADR for non-obvious architectural decisions.
- Check dependency support for Windows and future Android use, its maintenance status, and its license before proposing it. Pin package versions exactly.

## Development workflow

1. Install Flutter 3.50.0 and the Windows C++ toolchain described in `README.md`.
2. Create a focused branch from `main`.
3. Run the checks before opening a pull request:

   ```powershell
   flutter pub get
   powershell -ExecutionPolicy Bypass -File tool/check.ps1
   powershell -ExecutionPolicy Bypass -File tool/build_windows.ps1
   ```

4. Use a Conventional Commit message, for example `feat(editor): add snapping guides`.
5. Explain the user-visible result and list the checks you ran in the pull request.

Do not commit FFmpeg binaries, audio tracks, lyrics, signing material, access tokens, or other secrets.

## Reporting issues

Include the VisuSic version, Windows version, exact steps, expected behavior, actual behavior, and relevant local diagnostics. Remove personal file paths and other private information before posting.
