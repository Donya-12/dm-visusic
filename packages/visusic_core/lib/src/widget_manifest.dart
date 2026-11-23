// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:collection';
import 'dart:convert';

/// A readable manifest validation error.
final class ManifestException implements Exception {
  /// Creates a manifest error.
  const ManifestException(this.message);

  /// Human-readable validation problem.
  final String message;

  @override
  String toString() => 'ManifestException: $message';
}

/// Parameter control types supported by manifest schema version 1.
enum ParameterType {
  /// Decimal number.
  float,

  /// Whole number.
  integer,

  /// Boolean switch.
  boolean,

  /// Dropdown option.
  enumeration,

  /// Hex color.
  color,

  /// Two to six hex colors.
  gradient,

  /// Font family selector.
  font,

  /// Single-line text.
  text,

  /// Multi-line text.
  multiline,

  /// Project image asset.
  image,

  /// Large visual option cards.
  choiceCards,

  /// Two-dimensional vector.
  vector2,

  /// Numeric range.
  range,

  /// Custom curve editor.
  curveEditor,

  /// Visual grouping row.
  group,
}

/// Localized label map with a deterministic English fallback.
final class LocalizedText {
  /// Creates localized text.
  LocalizedText(Map<String, String> values) : values = Map.unmodifiable(values);

  /// Translations keyed by locale code.
  final Map<String, String> values;

  /// English text.
  String get english =>
      values['en'] ?? (values.isEmpty ? '' : values.values.first);

  /// Resolves a locale and falls back to English.
  String resolve(String languageCode) => values[languageCode] ?? english;

  /// Serializes the localized text.
  Map<String, String> toJson() => values;

  /// Parses a JSON object or a plain English string.
  factory LocalizedText.fromJson(Object? json) {
    if (json is String && json.isNotEmpty) {
      return LocalizedText(<String, String>{'en': json});
    }
    if (json is Map) {
      final values = <String, String>{};
      for (final entry in json.entries) {
        if (entry.value is String) {
          values[entry.key.toString()] = entry.value as String;
        }
      }
      if (values.isNotEmpty) {
        return LocalizedText(values);
      }
    }
    throw const ManifestException('Expected localized text with an en value.');
  }
}

/// One automatically generated inspector control.
final class ParameterSpec {
  /// Creates a validated parameter specification.
  const ParameterSpec({
    required this.id,
    required this.type,
    required this.label,
    required this.defaultValue,
    this.minimum,
    this.maximum,
    this.unit,
    this.options = const <String>[],
    this.primary = false,
    this.group,
  });

  /// Stable parameter identifier.
  final String id;

  /// Inspector control type.
  final ParameterType type;

  /// Localized control label.
  final LocalizedText label;

  /// Default layer value.
  final Object? defaultValue;

  /// Numeric minimum.
  final double? minimum;

  /// Numeric maximum.
  final double? maximum;

  /// Optional display unit.
  final String? unit;

  /// Enum/choice identifiers.
  final List<String> options;

  /// Whether this appears in the quick canvas inspector.
  final bool primary;

  /// Optional inspector group title.
  final String? group;

  /// Serializes this parameter.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'type': _typeName(type),
    'label': label.toJson(),
    'default': defaultValue,
    if (minimum != null) 'min': minimum,
    if (maximum != null) 'max': maximum,
    if (unit != null) 'unit': unit,
    if (options.isNotEmpty) 'options': options,
    if (primary) 'primary': true,
    if (group != null) 'group': group,
  };

  /// Parses and validates a parameter entry.
  factory ParameterSpec.fromJson(Map<String, Object?> json) {
    final id = _string(json['id'], 'Parameter id');
    final rawType = _string(json['type'], 'Parameter type');
    final type = switch (rawType) {
      'float' => ParameterType.float,
      'int' => ParameterType.integer,
      'bool' => ParameterType.boolean,
      'enum' => ParameterType.enumeration,
      'color' => ParameterType.color,
      'gradient' => ParameterType.gradient,
      'font' => ParameterType.font,
      'text' => ParameterType.text,
      'multiline' => ParameterType.multiline,
      'image' => ParameterType.image,
      'choiceCards' => ParameterType.choiceCards,
      'vector2' => ParameterType.vector2,
      'range' => ParameterType.range,
      'curveEditor' => ParameterType.curveEditor,
      'group' => ParameterType.group,
      _ => throw ManifestException('Unknown parameter type $rawType for $id.'),
    };
    final minimum = _number(json['min']);
    final maximum = _number(json['max']);
    if (minimum != null && maximum != null && minimum > maximum) {
      throw ManifestException('Parameter $id has min greater than max.');
    }
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions.map((value) => value.toString()).toList(growable: false)
        : const <String>[];
    final parameter = ParameterSpec(
      id: id,
      type: type,
      label: LocalizedText.fromJson(
        json['label'] ?? <String, Object?>{'en': id},
      ),
      defaultValue: json['default'],
      minimum: minimum,
      maximum: maximum,
      unit: json['unit'] as String?,
      options: List.unmodifiable(options),
      primary: json['primary'] == true,
      group: json['group'] as String?,
    );
    parameter.validate(parameter.defaultValue);
    return parameter;
  }

  /// Validates a layer value and applies numeric limits.
  void validate(Object? value) {
    switch (type) {
      case ParameterType.float:
        if (value is! num) {
          throw ManifestException('Parameter $id expects a number.');
        }
        _checkRange(value.toDouble());
      case ParameterType.integer:
        if (value is! num || value != value.roundToDouble()) {
          throw ManifestException('Parameter $id expects an integer.');
        }
        _checkRange(value.toDouble());
      case ParameterType.boolean:
        if (value is! bool) {
          throw ManifestException('Parameter $id expects a boolean.');
        }
      case ParameterType.enumeration:
      case ParameterType.choiceCards:
        if (value is! String || !options.contains(value)) {
          throw ManifestException('Parameter $id has an invalid option.');
        }
      case ParameterType.color:
        if (value is! String || !_isColor(value)) {
          throw ManifestException('Parameter $id expects a hex color.');
        }
      case ParameterType.gradient:
        if (value is! List ||
            value.length < 2 ||
            value.length > 6 ||
            value.any((color) => color is! String || !_isColor(color))) {
          throw ManifestException('Parameter $id expects 2–6 hex colors.');
        }
      case ParameterType.font:
      case ParameterType.text:
      case ParameterType.multiline:
      case ParameterType.image:
      case ParameterType.group:
        if (value != null && value is! String) {
          throw ManifestException('Parameter $id expects text.');
        }
      case ParameterType.vector2:
      case ParameterType.range:
      case ParameterType.curveEditor:
        break;
    }
  }

  void _checkRange(double value) {
    if ((minimum != null && value < minimum!) ||
        (maximum != null && value > maximum!)) {
      throw ManifestException('Parameter $id is outside its allowed range.');
    }
  }
}

/// A named audio-feature binding with frame-based smoothing.
final class WidgetBindingSpec {
  /// Creates a binding specification.
  const WidgetBindingSpec({
    required this.id,
    required this.feature,
    this.attackMs = 20,
    this.releaseMs = 180,
    this.curve = 'linear',
  });

  /// Identifier available as `bind.<id>` in expressions.
  final String id;

  /// Named feature path.
  final String feature;

  /// Attack smoothing in milliseconds.
  final int attackMs;

  /// Release smoothing in milliseconds.
  final int releaseMs;

  /// linear, ease, or expo response curve.
  final String curve;

  /// Parses a binding entry.
  factory WidgetBindingSpec.fromJson(Map<String, Object?> json) =>
      WidgetBindingSpec(
        id: _string(json['id'], 'Binding id'),
        feature: _string(json['feature'], 'Binding feature'),
        attackMs: _integer(json['attack'], fallback: 20),
        releaseMs: _integer(json['release'], fallback: 180),
        curve: json['curve'] as String? ?? 'linear',
      );

  /// Serializes this binding.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'feature': feature,
    'attack': attackMs,
    'release': releaseMs,
    'curve': curve,
  };
}

/// Renderer declaration from a widget.json manifest.
final class WidgetRenderSpec {
  /// Creates a renderer declaration.
  const WidgetRenderSpec({
    required this.type,
    required this.id,
    this.source,
    this.nodes = const <Object?>[],
  });

  /// native, shader, or composite.
  final String type;

  /// Registered native renderer ID or external renderer identifier.
  final String id;

  /// Optional inline shader source.
  final String? source;

  /// Declarative composite nodes.
  final List<Object?> nodes;

  /// Parses a render entry.
  factory WidgetRenderSpec.fromJson(Map<String, Object?> json) {
    final type = _string(json['type'], 'Render type');
    if (!const <String>['native', 'shader', 'composite'].contains(type)) {
      throw ManifestException('Unknown render type $type.');
    }
    return WidgetRenderSpec(
      type: type,
      id: _string(json['id'] ?? type, 'Render id'),
      source: json['source'] as String?,
      nodes: json['nodes'] is List
          ? List.unmodifiable(json['nodes'] as List)
          : const <Object?>[],
    );
  }

  /// Serializes this renderer declaration.
  Map<String, Object?> toJson() => <String, Object?>{
    'type': type,
    'id': id,
    if (source != null) 'source': source,
    if (nodes.isNotEmpty) 'nodes': nodes,
  };
}

/// Complete parsed widget.json document.
final class WidgetManifest {
  /// Creates a widget manifest.
  WidgetManifest({
    required this.id,
    required this.version,
    required this.name,
    required this.author,
    required this.category,
    required this.parameters,
    required this.bindings,
    required this.expressions,
    required this.render,
    required this.needsAudio,
    required this.needsLyrics,
    required this.defaultWidth,
    required this.defaultHeight,
    this.tags = const <String>[],
    this.anchor = 'center',
    this.resizable = true,
    this.aspectLock = false,
  });

  /// Stable reverse-DNS-like identifier.
  final String id;

  /// Manifest semantic version.
  final String version;

  /// Localized widget name.
  final LocalizedText name;

  /// Author attribution.
  final String author;

  /// Library category.
  final String category;

  /// Search tags.
  final List<String> tags;

  /// Ordered inspector parameters.
  final List<ParameterSpec> parameters;

  /// Named feature bindings.
  final List<WidgetBindingSpec> bindings;

  /// Numeric expressions keyed by render property.
  final Map<String, String> expressions;

  /// Renderer declaration.
  final WidgetRenderSpec render;

  /// Whether this widget needs real audio features.
  final bool needsAudio;

  /// Whether this widget requires synchronized lyrics.
  final bool needsLyrics;

  /// Suggested logical layer width.
  final double defaultWidth;

  /// Suggested logical layer height.
  final double defaultHeight;

  /// Default layout anchor.
  final String anchor;

  /// Whether the layer can be resized.
  final bool resizable;

  /// Whether resize preserves the initial ratio by default.
  final bool aspectLock;

  /// Fresh default parameter values for a new layer.
  Map<String, Object?> defaultParams() => <String, Object?>{
    for (final parameter in parameters)
      if (parameter.type != ParameterType.group)
        parameter.id: parameter.defaultValue,
  };

  /// Parameters shown in the floating quick inspector.
  List<ParameterSpec> primaryParameters() {
    final selected = parameters
        .where((parameter) => parameter.primary)
        .toList();
    if (selected.isNotEmpty) {
      return selected.take(3).toList(growable: false);
    }
    return parameters
        .where((parameter) => parameter.type != ParameterType.group)
        .take(3)
        .toList(growable: false);
  }

  /// Parses and validates widget.json.
  factory WidgetManifest.fromJsonString(String source) {
    try {
      final json = jsonDecode(source);
      if (json is! Map) {
        throw const ManifestException('Widget manifest must be a JSON object.');
      }
      return WidgetManifest.fromJson(
        json.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on ManifestException {
      rethrow;
    } on Object catch (error) {
      throw ManifestException('Cannot parse widget.json: $error');
    }
  }

  /// Parses a decoded manifest object.
  factory WidgetManifest.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != 1) {
      throw ManifestException(
        'Unsupported widget schema ${json['schemaVersion']}.',
      );
    }
    final rawParams = json['params'];
    final rawBindings = json['bindings'];
    final rawExpressions = json['expressions'];
    final anchor = json['anchor'];
    final requires = json['requires'];
    final render = json['render'];
    if (rawParams is! List || render is! Map) {
      throw const ManifestException('Manifest params and render are required.');
    }
    final parameters = rawParams
        .map((value) => ParameterSpec.fromJson(_object(value)))
        .toList(growable: false);
    final ids = parameters.map((parameter) => parameter.id).toSet();
    if (ids.length != parameters.length) {
      throw const ManifestException('Parameter IDs must be unique.');
    }
    final bindings = rawBindings is List
        ? rawBindings
              .map((value) => WidgetBindingSpec.fromJson(_object(value)))
              .toList(growable: false)
        : const <WidgetBindingSpec>[];
    final anchorMap = anchor is Map ? anchor : const <String, Object?>{};
    final requiresMap = requires is Map ? requires : const <String, Object?>{};
    return WidgetManifest(
      id: _string(json['id'], 'Widget id'),
      version: _string(json['version'], 'Widget version'),
      name: LocalizedText.fromJson(json['name']),
      author: json['author'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'other',
      tags: json['tags'] is List
          ? List.unmodifiable(
              (json['tags'] as List).map((tag) => tag.toString()),
            )
          : const <String>[],
      parameters: List.unmodifiable(parameters),
      bindings: List.unmodifiable(bindings),
      expressions: rawExpressions is Map
          ? Map.unmodifiable(
              rawExpressions.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            )
          : const <String, String>{},
      render: WidgetRenderSpec.fromJson(_object(render)),
      needsAudio: requiresMap['audio'] == true,
      needsLyrics: requiresMap['lyrics'] == true,
      defaultWidth: _number(anchorMap['width']) ?? 480,
      defaultHeight: _number(anchorMap['height']) ?? 180,
      anchor: anchorMap['default'] as String? ?? 'center',
      resizable: anchorMap['resizable'] != false,
      aspectLock: anchorMap['aspectLock'] == true,
    );
  }

  /// Serializes the manifest back to widget.json form.
  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'id': id,
    'version': version,
    'name': name.toJson(),
    'author': author,
    'category': category,
    if (tags.isNotEmpty) 'tags': tags,
    'requires': <String, Object?>{'audio': needsAudio, 'lyrics': needsLyrics},
    'anchor': <String, Object?>{
      'default': anchor,
      'resizable': resizable,
      'aspectLock': aspectLock,
      'width': defaultWidth,
      'height': defaultHeight,
    },
    'params': parameters
        .map((parameter) => parameter.toJson())
        .toList(growable: false),
    'bindings': bindings
        .map((binding) => binding.toJson())
        .toList(growable: false),
    'expressions': expressions,
    'render': render.toJson(),
  };
}

/// Validated manifest collection with unique identifiers.
final class ManifestRegistry {
  /// Creates a registry.
  ManifestRegistry(Iterable<WidgetManifest> manifests)
    : manifests = List.unmodifiable(manifests),
      byId = UnmodifiableMapView<String, WidgetManifest>(
        <String, WidgetManifest>{
          for (final manifest in manifests) manifest.id: manifest,
        },
      ) {
    if (byId.length != this.manifests.length) {
      throw const ManifestException('Widget IDs must be unique.');
    }
  }

  /// Ordered library entries.
  final List<WidgetManifest> manifests;

  /// Fast identifier lookup.
  final Map<String, WidgetManifest> byId;

  /// Parses an array or a {widgets: [...]} library document.
  factory ManifestRegistry.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    final list = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['widgets']
        : null;
    if (list is! List) {
      throw const ManifestException('Widget library must contain a list.');
    }
    return ManifestRegistry(
      list.map((entry) => WidgetManifest.fromJson(_object(entry))),
    );
  }

  /// Looks up a manifest by identifier.
  WidgetManifest? operator [](String id) => byId[id];

  /// Returns a manifest or throws a readable error for an unknown ID.
  WidgetManifest require(String id) {
    final manifest = byId[id];
    if (manifest == null) {
      throw ManifestException('Unknown widget $id.');
    }
    return manifest;
  }
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map) {
    throw const ManifestException('Expected a JSON object.');
  }
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _string(Object? value, String label) {
  if (value is! String || value.isEmpty) {
    throw ManifestException('$label must be a non-empty string.');
  }
  return value;
}

double? _number(Object? value) => value is num ? value.toDouble() : null;

int _integer(Object? value, {required int fallback}) =>
    value is num ? value.toInt() : fallback;

bool _isColor(String value) =>
    RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(value);

String _typeName(ParameterType type) => switch (type) {
  ParameterType.float => 'float',
  ParameterType.integer => 'int',
  ParameterType.boolean => 'bool',
  ParameterType.enumeration => 'enum',
  ParameterType.color => 'color',
  ParameterType.gradient => 'gradient',
  ParameterType.font => 'font',
  ParameterType.text => 'text',
  ParameterType.multiline => 'multiline',
  ParameterType.image => 'image',
  ParameterType.choiceCards => 'choiceCards',
  ParameterType.vector2 => 'vector2',
  ParameterType.range => 'range',
  ParameterType.curveEditor => 'curveEditor',
  ParameterType.group => 'group',
};
