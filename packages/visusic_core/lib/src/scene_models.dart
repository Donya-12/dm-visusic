// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:collection';

import 'package:visusic_core/src/lyrics.dart';

/// A read-only JSON object used by project serializers.
typedef JsonObject = Map<String, Object?>;

/// A readable error raised when a project document is invalid or unsupported.
class ProjectFormatException implements Exception {
  /// Creates a format error.
  const ProjectFormatException(this.message);

  /// Explanation suitable for a local error dialog.
  final String message;

  @override
  String toString() => 'ProjectFormatException: $message';
}

/// A layer rectangle in logical scene coordinates.
final class SceneRect {
  /// Creates a rectangle.
  const SceneRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
  }) : assert(width > 0),
       assert(height > 0);

  /// Horizontal position of the unrotated rectangle.
  final double x;

  /// Vertical position of the unrotated rectangle.
  final double y;

  /// Unrotated width.
  final double width;

  /// Unrotated height.
  final double height;

  /// Clockwise rotation in degrees around the center.
  final double rotation;

  /// Horizontal center.
  double get centerX => x + width / 2;

  /// Vertical center.
  double get centerY => y + height / 2;

  /// Right edge.
  double get right => x + width;

  /// Bottom edge.
  double get bottom => y + height;

  /// Returns a moved copy.
  SceneRect translate(double dx, double dy) => copyWith(x: x + dx, y: y + dy);

  /// Copies selected values.
  SceneRect copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return SceneRect(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
    );
  }

  /// Serializes this rectangle.
  JsonObject toJson() => <String, Object?>{
    'x': x,
    'y': y,
    'w': width,
    'h': height,
    'rotation': rotation,
  };

  /// Parses a rectangle from project JSON.
  factory SceneRect.fromJson(JsonObject json) {
    final width = _readDouble(json, 'w');
    final height = _readDouble(json, 'h');
    if (width <= 0 || height <= 0) {
      throw const ProjectFormatException('Layer dimensions must be positive.');
    }
    return SceneRect(
      x: _readDouble(json, 'x'),
      y: _readDouble(json, 'y'),
      width: width,
      height: height,
      rotation: _readDouble(json, 'rotation', fallback: 0),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SceneRect &&
        x == other.x &&
        y == other.y &&
        width == other.width &&
        height == other.height &&
        rotation == other.rotation;
  }

  @override
  int get hashCode => Object.hash(x, y, width, height, rotation);
}

/// One cubic-bezier keyframe for a numeric layer parameter.
final class SceneKeyframe {
  /// Creates a keyframe.
  const SceneKeyframe({
    required this.timeMs,
    required this.value,
    this.curve = const <double>[0.25, 0.1, 0.25, 1],
  });

  /// Position on the scene timeline.
  final double timeMs;

  /// Numeric parameter value at this keyframe.
  final double value;

  /// Cubic-bezier control points x1, y1, x2, y2.
  final List<double> curve;

  /// Serializes this keyframe.
  JsonObject toJson() => <String, Object?>{
    'timeMs': timeMs,
    'value': value,
    'curve': curve,
  };

  /// Parses a keyframe.
  factory SceneKeyframe.fromJson(JsonObject json) {
    final rawCurve = json['curve'];
    final curve = rawCurve is List
        ? rawCurve.map((value) => _asDouble(value)).toList(growable: false)
        : const <double>[0.25, 0.1, 0.25, 1];
    if (curve.length != 4) {
      throw const ProjectFormatException('A keyframe curve needs four values.');
    }
    return SceneKeyframe(
      timeMs: _readDouble(json, 'timeMs'),
      value: _readDouble(json, 'value'),
      curve: List<double>.unmodifiable(curve),
    );
  }
}

/// Describes an entrance or exit animation.
final class LayerAnimation {
  /// Creates an animation description.
  const LayerAnimation({this.style = 'none', this.durationMs = 350});

  /// Preset identifier: none, fade, slide, scale, blurIn, or maskWipe.
  final String style;

  /// Duration in milliseconds.
  final int durationMs;

  /// Serializes this animation.
  JsonObject toJson() => <String, Object?>{
    'style': style,
    'durationMs': durationMs,
  };

  /// Parses an animation description.
  factory LayerAnimation.fromJson(JsonObject? json) {
    if (json == null) {
      return const LayerAnimation();
    }
    return LayerAnimation(
      style: _readString(json, 'style', fallback: 'none'),
      durationMs: _readInt(json, 'durationMs', fallback: 350),
    );
  }
}

/// Layer visibility on the scene timeline.
final class LayerTiming {
  /// Creates timing data.
  const LayerTiming({
    this.inMs = 0,
    this.outMs,
    this.enter = const LayerAnimation(),
    this.exit = const LayerAnimation(),
  });

  /// First visible millisecond.
  final double inMs;

  /// Last visible millisecond, or null for the end of the project.
  final double? outMs;

  /// Entrance animation.
  final LayerAnimation enter;

  /// Exit animation.
  final LayerAnimation exit;

  /// Copies timing values.
  LayerTiming copyWith({
    double? inMs,
    Object? outMs = _notProvided,
    LayerAnimation? enter,
    LayerAnimation? exit,
  }) {
    return LayerTiming(
      inMs: inMs ?? this.inMs,
      outMs: identical(outMs, _notProvided) ? this.outMs : outMs as double?,
      enter: enter ?? this.enter,
      exit: exit ?? this.exit,
    );
  }

  /// Serializes timing data.
  JsonObject toJson() => <String, Object?>{
    'inMs': inMs,
    'outMs': outMs,
    'enter': enter.toJson(),
    'exit': exit.toJson(),
  };

  /// Parses timing data.
  factory LayerTiming.fromJson(JsonObject? json) {
    if (json == null) {
      return const LayerTiming();
    }
    return LayerTiming(
      inMs: _readDouble(json, 'inMs', fallback: 0),
      outMs: json['outMs'] == null ? null : _asDouble(json['outMs']),
      enter: LayerAnimation.fromJson(_readMap(json['enter'])),
      exit: LayerAnimation.fromJson(_readMap(json['exit'])),
    );
  }
}

/// A single editable widget instance on the scene.
final class SceneLayer {
  /// Creates a layer.
  SceneLayer({
    required this.id,
    required this.widgetId,
    required this.name,
    required this.rect,
    Map<String, Object?>? params,
    Map<String, List<SceneKeyframe>>? keyframes,
    this.timing = const LayerTiming(),
    this.locked = false,
    this.hidden = false,
    this.muted = false,
    this.solo = false,
    this.anchor = 'center',
    this.groupId,
    this.colorTag = 'default',
  }) : params = UnmodifiableMapView<String, Object?>(
         Map<String, Object?>.from(params ?? const <String, Object?>{}),
       ),
       keyframes = UnmodifiableMapView<String, List<SceneKeyframe>>(
         (keyframes ?? const <String, List<SceneKeyframe>>{}).map(
           (key, value) =>
               MapEntry(key, List<SceneKeyframe>.unmodifiable(value)),
         ),
       );

  /// Stable identifier inside the project.
  final String id;

  /// Widget manifest identifier.
  final String widgetId;

  /// Human-editable layer name.
  final String name;

  /// Position and size in logical scene coordinates.
  final SceneRect rect;

  /// Current parameter values keyed by manifest parameter ID.
  final Map<String, Object?> params;

  /// Numeric parameter keyframes.
  final Map<String, List<SceneKeyframe>> keyframes;

  /// Timeline visibility and transitions.
  final LayerTiming timing;

  /// Whether editor manipulation is locked.
  final bool locked;

  /// Whether the layer is hidden.
  final bool hidden;

  /// Whether the layer is temporarily muted by the layer panel.
  final bool muted;

  /// Whether the layer is included in solo mode.
  final bool solo;

  /// Layout anchor used when adapting to another aspect ratio.
  final String anchor;

  /// Optional layer-group identifier.
  final String? groupId;

  /// Color label used by the layers panel.
  final String colorTag;

  /// Copies selected values.
  SceneLayer copyWith({
    String? widgetId,
    String? name,
    SceneRect? rect,
    Map<String, Object?>? params,
    Map<String, List<SceneKeyframe>>? keyframes,
    LayerTiming? timing,
    bool? locked,
    bool? hidden,
    bool? muted,
    bool? solo,
    String? anchor,
    Object? groupId = _notProvided,
    String? colorTag,
  }) {
    return SceneLayer(
      id: id,
      widgetId: widgetId ?? this.widgetId,
      name: name ?? this.name,
      rect: rect ?? this.rect,
      params: params ?? this.params,
      keyframes: keyframes ?? this.keyframes,
      timing: timing ?? this.timing,
      locked: locked ?? this.locked,
      hidden: hidden ?? this.hidden,
      muted: muted ?? this.muted,
      solo: solo ?? this.solo,
      anchor: anchor ?? this.anchor,
      groupId: identical(groupId, _notProvided)
          ? this.groupId
          : groupId as String?,
      colorTag: colorTag ?? this.colorTag,
    );
  }

  /// Serializes the layer.
  JsonObject toJson() => <String, Object?>{
    'id': id,
    'widget': widgetId,
    'name': name,
    'rect': rect.toJson(),
    'params': params,
    'keyframes': keyframes.map(
      (key, value) => MapEntry(
        key,
        value.map((keyframe) => keyframe.toJson()).toList(growable: false),
      ),
    ),
    'timing': timing.toJson(),
    'locked': locked,
    'hidden': hidden,
    'muted': muted,
    'solo': solo,
    'anchor': anchor,
    'groupId': groupId,
    'colorTag': colorTag,
  };

  /// Parses a layer.
  factory SceneLayer.fromJson(JsonObject json) {
    final rawParams = _readMap(json['params']) ?? const <String, Object?>{};
    final rawKeyframes = _readMap(json['keyframes']);
    final parsedKeyframes = <String, List<SceneKeyframe>>{};
    if (rawKeyframes != null) {
      for (final entry in rawKeyframes.entries) {
        final frames = entry.value;
        if (frames is! List) {
          throw ProjectFormatException(
            'Keyframe list for ${entry.key} must be an array.',
          );
        }
        parsedKeyframes[entry.key] = frames
            .map((frame) => SceneKeyframe.fromJson(_requireMap(frame)))
            .toList(growable: false);
      }
    }
    return SceneLayer(
      id: _readString(json, 'id'),
      widgetId: _readString(json, 'widget'),
      name: _readString(json, 'name', fallback: _readString(json, 'widget')),
      rect: SceneRect.fromJson(_requireMap(json['rect'])),
      params: rawParams,
      keyframes: parsedKeyframes,
      timing: LayerTiming.fromJson(_readMap(json['timing'])),
      locked: _readBool(json, 'locked', fallback: false),
      hidden: _readBool(json, 'hidden', fallback: false),
      muted: _readBool(json, 'muted', fallback: false),
      solo: _readBool(json, 'solo', fallback: false),
      anchor: _readString(json, 'anchor', fallback: 'center'),
      groupId: json['groupId'] as String?,
      colorTag: _readString(json, 'colorTag', fallback: 'default'),
    );
  }
}

/// Metadata for one binary project asset.
final class ProjectAsset {
  /// Creates asset metadata.
  const ProjectAsset({
    required this.id,
    required this.path,
    required this.mimeType,
  });

  /// Stable asset identifier referenced by widget parameters.
  final String id;

  /// ZIP-relative path under assets/.
  final String path;

  /// Image MIME type.
  final String mimeType;

  /// Serializes the asset metadata.
  JsonObject toJson() => <String, Object?>{
    'id': id,
    'path': path,
    'mimeType': mimeType,
  };

  /// Parses asset metadata.
  factory ProjectAsset.fromJson(JsonObject json) => ProjectAsset(
    id: _readString(json, 'id'),
    path: _readString(json, 'path'),
    mimeType: _readString(json, 'mimeType', fallback: 'image/png'),
  );
}

/// Logical scene dimensions, playback defaults, and background.
final class SceneCanvas {
  /// Creates canvas settings.
  const SceneCanvas({
    required this.width,
    required this.height,
    required this.aspect,
    this.fps = 60,
    this.duration = 30,
    this.background = '#101014',
  });

  /// Logical width.
  final int width;

  /// Logical height.
  final int height;

  /// Preset or custom aspect label.
  final String aspect;

  /// Default playback and export frame rate.
  final int fps;

  /// Scene duration in seconds.
  final double duration;

  /// Background color in #RRGGBB or #AARRGGBB form.
  final String background;

  /// Width divided by height.
  double get ratio => width / height;

  /// Copies canvas settings.
  SceneCanvas copyWith({
    int? width,
    int? height,
    String? aspect,
    int? fps,
    double? duration,
    String? background,
  }) => SceneCanvas(
    width: width ?? this.width,
    height: height ?? this.height,
    aspect: aspect ?? this.aspect,
    fps: fps ?? this.fps,
    duration: duration ?? this.duration,
    background: background ?? this.background,
  );

  /// Serializes canvas settings.
  JsonObject toJson() => <String, Object?>{
    'width': width,
    'height': height,
    'aspect': aspect,
    'fps': fps,
    'duration': duration,
    'background': background,
  };

  /// Parses canvas settings.
  factory SceneCanvas.fromJson(JsonObject json) {
    final canvas = SceneCanvas(
      width: _readInt(json, 'width'),
      height: _readInt(json, 'height'),
      aspect: _readString(json, 'aspect', fallback: 'custom'),
      fps: _readInt(json, 'fps', fallback: 60),
      duration: _readDouble(json, 'duration', fallback: 30),
      background: _readString(json, 'background', fallback: '#101014'),
    );
    if (canvas.width <= 0 || canvas.height <= 0 || canvas.duration <= 0) {
      throw const ProjectFormatException('Canvas values must be positive.');
    }
    return canvas;
  }
}

/// Complete serializable scene document.
final class SceneProject {
  /// Creates a project.
  SceneProject({
    required this.name,
    required this.canvas,
    List<SceneLayer>? layers,
    List<ProjectAsset>? assets,
    this.audioPath,
    this.audioAnalysis,
    this.lyrics,
  }) : layers = List<SceneLayer>.unmodifiable(layers ?? const <SceneLayer>[]),
       assets = List<ProjectAsset>.unmodifiable(
         assets ?? const <ProjectAsset>[],
       );

  /// User-visible project name.
  final String name;

  /// Logical canvas.
  final SceneCanvas canvas;

  /// Layers from back to front.
  final List<SceneLayer> layers;

  /// Binary asset metadata.
  final List<ProjectAsset> assets;

  /// Host path of the source audio track, when loaded.
  final String? audioPath;

  /// ZIP-relative analysis cache name, when persisted.
  final String? audioAnalysis;

  /// Synchronized lyrics, when loaded.
  final LyricsTrack? lyrics;

  /// Returns a layer by ID or null.
  SceneLayer? layerById(String id) {
    for (final layer in layers) {
      if (layer.id == id) {
        return layer;
      }
    }
    return null;
  }

  /// Copies selected project values.
  SceneProject copyWith({
    String? name,
    SceneCanvas? canvas,
    List<SceneLayer>? layers,
    List<ProjectAsset>? assets,
    Object? audioPath = _notProvided,
    Object? audioAnalysis = _notProvided,
    Object? lyrics = _notProvided,
  }) => SceneProject(
    name: name ?? this.name,
    canvas: canvas ?? this.canvas,
    layers: layers ?? this.layers,
    assets: assets ?? this.assets,
    audioPath: identical(audioPath, _notProvided)
        ? this.audioPath
        : audioPath as String?,
    audioAnalysis: identical(audioAnalysis, _notProvided)
        ? this.audioAnalysis
        : audioAnalysis as String?,
    lyrics: identical(lyrics, _notProvided)
        ? this.lyrics
        : lyrics as LyricsTrack?,
  );

  /// Serializes the project manifest.
  JsonObject toJson() => <String, Object?>{
    'schemaVersion': 1,
    'name': name,
    'canvas': canvas.toJson(),
    'audio': <String, Object?>{'path': audioPath, 'analysis': audioAnalysis},
    'theme': <String, Object?>{
      'mode': 'dark',
      'scheme': 'seed',
      'seed': '#7C4DFF',
    },
    'lyrics': lyrics == null
        ? <String, Object?>{'source': null, 'offsetMs': 0, 'lines': <Object?>[]}
        : <String, Object?>{'source': 'lrc', ...lyrics!.toJson()},
    'assets': assets.map((asset) => asset.toJson()).toList(growable: false),
    'layers': layers.map((layer) => layer.toJson()).toList(growable: false),
    'postFx': <Object?>[],
  };

  /// Parses and migrates a project manifest.
  factory SceneProject.fromJson(JsonObject json) {
    final version = json['schemaVersion'] ?? 1;
    if (version != 1) {
      throw ProjectFormatException(
        'Unsupported project schema version: $version.',
      );
    }
    final rawLayers = json['layers'];
    final rawAssets = json['assets'];
    final rawAudio = json['audio'];
    return SceneProject(
      name: _readString(json, 'name', fallback: 'Untitled Scene'),
      canvas: SceneCanvas.fromJson(_requireMap(json['canvas'])),
      layers: rawLayers is List
          ? rawLayers
                .map((layer) => SceneLayer.fromJson(_requireMap(layer)))
                .toList(growable: false)
          : throw const ProjectFormatException(
              'Project layers must be an array.',
            ),
      assets: rawAssets == null
          ? const <ProjectAsset>[]
          : rawAssets is List
          ? rawAssets
                .map((asset) => ProjectAsset.fromJson(_requireMap(asset)))
                .toList(growable: false)
          : throw const ProjectFormatException(
              'Project assets must be an array.',
            ),
      audioPath: rawAudio is Map ? rawAudio['path'] as String? : null,
      audioAnalysis: rawAudio is Map ? rawAudio['analysis'] as String? : null,
      lyrics: _readLyrics(json['lyrics']),
    );
  }
}

const Object _notProvided = Object();

LyricsTrack? _readLyrics(Object? value) {
  if (value is! Map || value['lines'] is! List) {
    return null;
  }
  return LyricsTrack.fromJson(
    value.map((key, item) => MapEntry(key.toString(), item)),
  );
}

JsonObject _requireMap(Object? value) {
  if (value is! Map) {
    throw const ProjectFormatException('Expected a JSON object.');
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

JsonObject? _readMap(Object? value) =>
    value == null ? null : _requireMap(value);

String _readString(JsonObject json, String key, {String? fallback}) {
  final value = json[key];
  if (value == null && fallback != null) {
    return fallback;
  }
  if (value is! String || value.isEmpty) {
    throw ProjectFormatException('Expected a non-empty string for $key.');
  }
  return value;
}

bool _readBool(JsonObject json, String key, {required bool fallback}) {
  final value = json[key];
  if (value == null) {
    return fallback;
  }
  if (value is! bool) {
    throw ProjectFormatException('Expected a boolean for $key.');
  }
  return value;
}

int _readInt(JsonObject json, String key, {int? fallback}) {
  final value = json[key];
  if (value == null && fallback != null) {
    return fallback;
  }
  if (value is! num || value != value.roundToDouble()) {
    throw ProjectFormatException('Expected an integer for $key.');
  }
  return value.toInt();
}

double _readDouble(JsonObject json, String key, {double? fallback}) {
  final value = json[key];
  if (value == null && fallback != null) {
    return fallback;
  }
  if (value == null) {
    throw ProjectFormatException('Expected a number for $key.');
  }
  return _asDouble(value);
}

double _asDouble(Object? value) {
  if (value is! num || !value.isFinite) {
    throw ProjectFormatException('Expected a finite number, got $value.');
  }
  return value.toDouble();
}
