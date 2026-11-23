# Performance

Targets are measured on a 1080p scene with 25 widgets on an Intel Iris Xe / GTX 1050 class machine.

## Goals

- Editor stays at 60 fps on the target scene.
- Cold start under 2.5 seconds.
- Opening a project under 1 second.
- 1080p60 export at or above 1× real time.

## How to measure

```powershell
cd apps/visusic
flutter run --profile -d windows
```

Open DevTools (`flutter pub global run devtools`) and use the Timeline to record frames. Capture a before/after frame report and note the date, commit, and machine configuration in this file.

## Current design notes

- The scene uses one `CustomPainter` (`ScenePainter`); widget count does not create per-widget raster layers.
- Audio features are precomputed and cached in `analysis.vsan`; playback reads the cache instead of re-analyzing.
- Export reuses `ScenePainter` and the cached analysis, so a frame is the same in preview and in the file.
- Image assets are decoded once and reused; shaders are loaded once at startup.

No benchmark has been recorded yet.
