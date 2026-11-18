# Third-party notices

VisuSic itself is licensed under the MIT License. It includes or depends on the following third-party components.

## Runtime components

| Component | License | Notes |
| --- | --- | --- |
| Flutter SDK and Flutter localizations | BSD 3-Clause | Framework components. |
| `material_ui` and `cupertino_ui` | BSD 3-Clause | Material 3 widgets, theme components, and system localizations. |
| `intl` Dart package | BSD 3-Clause | Localization message support. |
| Inter | SIL Open Font License 1.1 | Bundled variable font; copyright and license are in `apps/visusic/assets/fonts/OFL.txt`. |

The application license page displays license texts collected from resolved Dart and Flutter packages. The Inter license is registered explicitly from the bundled asset.

## Build and development components

The development workspace also uses `test` and `flutter_lints` (BSD 3-Clause). GitHub Actions uses third-party build automation actions under their respective licenses. These components are not part of the portable application runtime.

## Future components

FFmpeg is not bundled at M0. When audio or video support is introduced, the selected FFmpeg build, its exact license configuration, source offer, and required LGPL notices must be reviewed and documented before distribution.
