# Making your own widget

Widgets are described by a versioned JSON manifest. No Dart code, no build step — drop a widget folder or a `.vspack` pack into the app and it appears in the library.

## Minimum manifest

```json
{
  "schemaVersion": 1,
  "id": "my.pulse",
  "version": "1.0.0",
  "name": { "en": "Pulse", "ru": "Пульс" },
  "author": "You",
  "category": "audio",
  "requires": { "audio": true, "lyrics": false },
  "anchor": { "default": "center", "width": 480, "height": 160 },
  "params": [
    { "id": "size", "type": "float", "min": 10, "max": 200, "default": 64, "unit": "px", "label": { "en": "Size" }, "primary": true }
  ],
  "bindings": [
    { "id": "kick", "feature": "beat.isBeat", "release": 180, "curve": "expo" }
  ],
  "expressions": { "scale": "1 + bind.kick * 0.1" },
  "render": { "type": "composite", "id": "pulse" }
}
```

- `params` generate inspector controls automatically. `primary: true` marks up to three quick controls.
- `bindings` name audio features (`band.bass`, `beat.isBeat`, `energy.short`, ...). `attack`/`release` are milliseconds; `curve` is `linear`, `ease`, or `expo`.
- `expressions` are safe math (`+ - * / min max clamp lerp sin cos mix`) over `params.*`, `bind.*`, `time.*`, `audio.*`, and `lyric.*`. No `eval`, no plugins.

## Render types

| Type | Who | What |
| --- | --- | --- |
| `native` | built-in | A Dart renderer registered by ID. Full canvas access. |
| `shader` | third-party | A GLSL fragment with uniform bindings, sandboxed and cross-platform. |
| `composite` | third-party | A declarative stack of primitives (text, shapes, images, gradients) — safe and portable. |

Third-party packs never run arbitrary Dart or JavaScript.

## Folder layout

```text
widgets/my-pulse/
├─ widget.json
├─ preview.webp        # 512×288, shown in the library
└─ assets/             # optional images and OFL fonts
```

## Packing as `.vspack`

A `.vspack` is a ZIP containing:

```text
pack.json              # name, version, author, widgets, scenes
widgets/**/widget.json
scenes/**              # scene presets (project documents)
assets/**
```

Create one with **Templates → Export as .vspack** in the editor, or use the `WidgetPack`/`PackCodec` API from `visusic_core`.

## Good-template rules

- At most 12 parameters; three marked `primary`.
- Works at 16:9, 9:16, and 1:1.
- No required external assets when possible; fonts only OFL.
- Graceful empty state when audio or lyrics are missing.
- A preview, or the library shows a gray placeholder.
