// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:visusic_audio/visusic_audio.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_platform/visusic_platform.dart';
import 'package:visusic_render/visusic_render.dart';

/// Renders and streams deterministic scene frames for video export.
final class SceneExportService {
  /// Creates an export service for the current document.
  SceneExportService({
    required this.project,
    required this.registry,
    this.cache,
    this.lyrics,
    this.images = const <String, ui.Image>{},
  });

  /// Project to render.
  final SceneProject project;

  /// Widget registry used for expression evaluation.
  final ManifestRegistry registry;

  /// Precomputed audio analysis, when available.
  final AnalysisCache? cache;

  /// Synchronized lyrics, when available.
  final LyricsTrack? lyrics;

  /// Decoded image assets.
  final Map<String, ui.Image> images;

  /// Exports the whole scene into [outputPath] using [encoder].
  Future<void> export({
    required ExportSettings settings,
    required VideoEncoder encoder,
    required String outputPath,
    void Function(double progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final duration = cache?.duration ?? project.canvas.duration;
    await encoder.encode(
      settings: settings,
      frames: _frames(settings, isCancelled),
      outputPath: outputPath,
      audioPath: project.audioPath,
      durationSeconds: duration,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }

  Stream<VideoFrame> _frames(
    ExportSettings settings,
    bool Function()? isCancelled,
  ) async* {
    final duration = cache?.duration ?? project.canvas.duration;
    final totalFrames = (duration * settings.fps).ceil();
    final resolver = BindingResolver();
    for (var index = 0; index < totalFrames; index++) {
      if (isCancelled?.call() ?? false) {
        return;
      }
      final seconds = index / settings.fps;
      final features = _featuresAt(seconds);
      final expressions = resolver.resolve(
        project,
        registry,
        features,
        lyric: _lyricValues(features),
      );
      final rgba = await renderFrameRgba(
        project: project,
        features: features,
        images: images,
        expressionValues: expressions,
        width: settings.width,
        height: settings.height,
      );
      yield VideoFrame(
        width: settings.width,
        height: settings.height,
        rgba: rgba,
      );
    }
  }

  FeatureSnapshot _featuresAt(double seconds) {
    final base = cache != null
        ? cache!.frameAt(seconds)
        : FeatureSnapshot.demo(seconds, project.canvas.duration);
    return _applyLyrics(base, seconds * 1000);
  }

  FeatureSnapshot _applyLyrics(FeatureSnapshot base, double timeMs) {
    final track = lyrics;
    if (track == null || track.lines.isEmpty) {
      return base;
    }
    final index = track.lineIndexAt(timeMs);
    final line = track.lineAt(timeMs);
    final next = index + 1 < track.lines.length
        ? track.lines[index + 1].text
        : null;
    return base.copyWithLyrics(
      lyricLineIndex: index,
      lyricWordIndex: track.wordIndexAt(timeMs),
      lyricLineProgress: track.lineProgressAt(timeMs),
      lyricWordProgress: track.wordProgressAt(timeMs),
      lyricLine: line?.text,
      lyricNextLine: next,
      lyricTranslation: line?.translation,
    );
  }

  Map<String, double> _lyricValues(FeatureSnapshot features) =>
      <String, double>{
        'lineProgress': features.lyricLineProgress,
        'wordProgress': features.lyricWordProgress,
        'lineIndex': features.lyricLineIndex.toDouble(),
        'wordIndex': features.lyricWordIndex.toDouble(),
      };
}

/// Renders one scene frame to raw RGBA bytes.
Future<Uint8List> renderFrameRgba({
  required SceneProject project,
  required FeatureSnapshot features,
  required Map<String, ui.Image> images,
  required Map<String, Map<String, double>> expressionValues,
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  ScenePainter(
    project: project,
    features: features,
    images: images,
    expressionValues: expressionValues,
  ).paint(canvas, ui.Size(width.toDouble(), height.toDouble()));
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return Uint8List.fromList(data!.buffer.asUint8List());
}
