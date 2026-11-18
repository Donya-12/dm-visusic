// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;

import 'package:visusic_core/src/expressions.dart';
import 'package:visusic_core/src/feature_snapshot.dart';
import 'package:visusic_core/src/scene_models.dart';
import 'package:visusic_core/src/widget_manifest.dart';

/// Resolves smoothed audio bindings and manifest expressions for scene layers.
///
/// Each call to [resolve] advances every active binding by exactly one frame,
/// using the frame rate from [SceneCanvas.fps]. It deliberately does not use
/// wall-clock time or differences between snapshot timestamps, so preview and
/// export produce the same values for the same sequential frame stream.
final class BindingResolver {
  /// Creates a stateful frame-based resolver.
  BindingResolver();

  final Map<(String, String), double> _bindingValues =
      <(String, String), double>{};
  final Map<String, NumericExpression> _expressionCache =
      <String, NumericExpression>{};

  /// Resolves all layers in [project] against their registered manifests.
  ///
  /// Binding state is keyed by both layer ID and binding ID. Attack smoothing
  /// is used when the target rises and release smoothing when it falls. Both
  /// are exponential time-constant smoothers with a fixed `1000 / fps` step.
  /// The `linear`, `ease`, and `expo` curves shape that step; zero attack or
  /// release durations select the new target immediately.
  ///
  /// Expressions receive numeric layer parameters as `params.*`, smoothed
  /// bindings as `bind.*`, snapshot time as `time.now` and `time.progress`,
  /// feature aliases as `audio.*`, and [lyric] values as `lyric.*`. Boolean
  /// parameters are exposed as zero or one. Missing lyric values are zero.
  ///
  /// Returns expression values keyed first by layer ID and then by expression
  /// property. Call [reset] after a seek or when loading another project.
  Map<String, Map<String, double>> resolve(
    SceneProject project,
    ManifestRegistry manifests,
    FeatureSnapshot features, {
    Map<String, double> lyric = const <String, double>{},
  }) {
    final fps = project.canvas.fps;
    if (fps <= 0) {
      throw ArgumentError.value(fps, 'project.canvas.fps', 'Must be positive');
    }
    final frameDurationMs = 1000.0 / fps;
    final time = <String, double>{
      'now': features.time,
      'progress': features.progress,
    };
    final audio = _audioValues(features);
    final result = <String, Map<String, double>>{};
    final activeBindings = <(String, String)>{};

    for (final layer in project.layers) {
      final manifest = manifests.require(layer.widgetId);
      final params = _parameterValues(manifest, layer);
      final bind = <String, double>{};
      for (final binding in manifest.bindings) {
        final key = (layer.id, binding.id);
        if (!activeBindings.add(key)) {
          throw ExpressionException(
            'Duplicate binding "${binding.id}" for layer "${layer.id}"',
          );
        }
        bind[binding.id] = _resolveBinding(
          key: key,
          binding: binding,
          target: features.valueAt(binding.feature),
          frameDurationMs: frameDurationMs,
        );
      }

      final values = <String, double>{};
      for (final entry in manifest.expressions.entries) {
        final expression = _expressionCache.putIfAbsent(
          entry.value,
          () => NumericExpression.parse(entry.value),
        );
        values[entry.key] = expression.evaluate(
          params: params,
          bind: bind,
          time: time,
          audio: audio,
          lyric: lyric,
        );
      }
      result[layer.id] = Map.unmodifiable(values);
    }

    _bindingValues.removeWhere((key, value) => !activeBindings.contains(key));
    return Map.unmodifiable(result);
  }

  /// Clears all smoothing state while retaining parsed expression caches.
  ///
  /// Call this method on seeks and project reloads. The next frame starts every
  /// binding from zero, exactly like the first frame of a new resolver.
  void reset() => _bindingValues.clear();

  double _resolveBinding({
    required (String, String) key,
    required WidgetBindingSpec binding,
    required double target,
    required double frameDurationMs,
  }) {
    if (binding.attackMs < 0 || binding.releaseMs < 0) {
      throw ExpressionException(
        'Binding "${binding.id}" for layer "${key.$1}" requires non-negative attack and release durations',
      );
    }
    if (!target.isFinite) {
      throw ExpressionException(
        'Binding "${binding.id}" for layer "${key.$1}" received a non-finite feature value',
        source: binding.feature,
      );
    }
    final previous = _bindingValues[key] ?? 0;
    final durationMs = target >= previous
        ? binding.attackMs
        : binding.releaseMs;
    final linearStep = durationMs == 0
        ? 1.0
        : 1 - math.exp(-frameDurationMs / durationMs);
    final curvedStep = switch (binding.curve) {
      'linear' => linearStep,
      'ease' => linearStep * linearStep * (3 - 2 * linearStep),
      'expo' =>
        linearStep == 1 ? 1.0 : 1 - math.pow(2, -10 * linearStep).toDouble(),
      _ => throw ExpressionException(
        'Binding "${binding.id}" for layer "${key.$1}" has unknown curve "${binding.curve}"; expected linear, ease, or expo',
      ),
    };
    final value = durationMs == 0
        ? target
        : previous + (target - previous) * curvedStep;
    if (!value.isFinite) {
      throw ExpressionException(
        'Binding "${binding.id}" for layer "${key.$1}" produced a non-finite result',
        source: binding.feature,
      );
    }
    _bindingValues[key] = value;
    return value;
  }

  Map<String, double> _parameterValues(
    WidgetManifest manifest,
    SceneLayer layer,
  ) {
    final values = <String, Object?>{
      ...manifest.defaultParams(),
      ...layer.params,
    };
    return <String, double>{
      for (final entry in values.entries)
        if (entry.value case final num value)
          entry.key: value.toDouble()
        else if (entry.value case final bool value)
          entry.key: value ? 1 : 0,
    };
  }

  Map<String, double> _audioValues(FeatureSnapshot features) {
    final values = <String, double>{
      'rms': features.rms,
      'peak': features.peak,
      'attack': features.isBeat ? 1 : 0,
      'energy': features.energyShort,
      'energyShort': features.energyShort,
      'energyLong': features.energyLong,
      'isBeat': features.isBeat ? 1 : 0,
      'beat': features.isBeat ? 1 : 0,
      'beatPhase': features.beatPhase,
      'bpm': features.bpm,
      'beatIndex': features.beatIndex.toDouble(),
      'level.rms': features.rms,
      'level.peak': features.peak,
      'level.attack': features.isBeat ? 1 : 0,
      'energy.short': features.energyShort,
      'energy.long': features.energyLong,
      'beat.isBeat': features.isBeat ? 1 : 0,
      'beat.phase': features.beatPhase,
      'beat.bpm': features.bpm,
      'beat.index': features.beatIndex.toDouble(),
    };
    for (final band in features.bands.entries) {
      values['band.${band.key}'] = band.value;
      values['bands.${band.key}'] = band.value;
      values.putIfAbsent(band.key, () => band.value);
    }
    return values;
  }
}
