// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:visusic_core/src/binding_resolver.dart';
import 'package:visusic_core/src/expressions.dart';
import 'package:visusic_core/visusic_core.dart';

void main() {
  group('manifest expression context', () {
    test('uses params, bindings, time, audio aliases, and lyric fallbacks', () {
      const binding = WidgetBindingSpec(
        id: 'kick',
        feature: 'beat.isBeat',
        attackMs: 0,
        releaseMs: 0,
      );
      final manifest = _manifest(
        bindings: const <WidgetBindingSpec>[binding],
        expressions: const <String, String>{
          'scale': '1 + bind.kick * params.pulse',
          'enabled': 'params.enabled',
          'time': 'time.now + time.progress',
          'audio':
              'audio.energy + audio.rms + audio.peak + audio.bass + '
              'audio.level.peak',
          'audioAliases':
              'audio.energy.short + audio.beat.bpm + '
              'audio.beat.index + audio.band.bass',
          'lyrics': 'lyric.lineProgress + lyric.wordProgress + lyric.missing',
          'mixed': 'mix(2, 6, 0.25)',
        },
      );
      final resolver = BindingResolver();
      final values = resolver.resolve(
        _project(<SceneLayer>[
          _layer(
            'layer-one',
            params: <String, Object?>{'pulse': 0.5, 'enabled': true},
          ),
        ]),
        ManifestRegistry(<WidgetManifest>[manifest]),
        _features(
          time: 2,
          rms: 0.2,
          peak: 0.4,
          energyShort: 0.5,
          beatPhase: 0,
          beatIndex: 7,
          bands: <String, double>{'bass': 0.3},
        ),
        lyric: <String, double>{'lineProgress': 0.4, 'wordProgress': 0.2},
      );

      expect(values, hasLength(1));
      expect(values['layer-one']!['scale'], 1.5);
      expect(values['layer-one']!['enabled'], 1);
      expect(values['layer-one']!['time'], closeTo(2.2, 1e-12));
      expect(values['layer-one']!['audio'], closeTo(1.8, 1e-12));
      expect(values['layer-one']!['audioAliases'], closeTo(127.8, 1e-12));
      expect(values['layer-one']!['lyrics'], closeTo(0.6, 1e-12));
      expect(values['layer-one']!['mixed'], 3);
    });

    test('keeps state isolated by layer and binding ID', () {
      final manifest = _manifest(
        bindings: const <WidgetBindingSpec>[
          WidgetBindingSpec(
            id: 'one',
            feature: 'energy.short',
            attackMs: 100,
            releaseMs: 100,
          ),
          WidgetBindingSpec(
            id: 'two',
            feature: 'energy.short',
            attackMs: 300,
            releaseMs: 300,
          ),
        ],
        expressions: const <String, String>{
          'one': 'bind.one',
          'two': 'bind.two',
        },
      );
      final resolver = BindingResolver();
      final project = _project(<SceneLayer>[_layer('first'), _layer('second')]);
      final registry = ManifestRegistry(<WidgetManifest>[manifest]);
      final first = resolver.resolve(
        project,
        registry,
        _features(energyShort: 1),
      );
      final second = resolver.resolve(
        project,
        registry,
        _features(energyShort: 1),
      );

      expect(first['first'], first['second']);
      expect(first['second'], isNot(second['second']));
      expect(first['first']!['one'], isNot(first['first']!['two']));
      expect(first['first']!['two'], isNot(second['first']!['two']));
    });
  });

  group('frame-based binding smoothing', () {
    test('uses attack for rising targets and release for falling targets', () {
      final resolver = BindingResolver();
      final manifest = _manifest(
        bindings: const <WidgetBindingSpec>[
          WidgetBindingSpec(
            id: 'energy',
            feature: 'energy.short',
            attackMs: 200,
            releaseMs: 300,
          ),
        ],
        expressions: const <String, String>{'value': 'bind.energy'},
      );
      final registry = ManifestRegistry(<WidgetManifest>[manifest]);
      final project = _project(<SceneLayer>[_layer('one')]);
      const frameMs = 1000 / 60;

      final first = resolver.resolve(
        project,
        registry,
        _features(energyShort: 1),
      );
      final attack = 1 - math.exp(-frameMs / 200);
      expect(first['one']!['value'], closeTo(attack, 1e-12));

      final second = resolver.resolve(
        project,
        registry,
        _features(time: 1 / 60, energyShort: 0),
      );
      final release = 1 - math.exp(-frameMs / 300);
      final afterRelease = attack + (0 - attack) * release;
      expect(second['one']!['value'], closeTo(afterRelease, 1e-12));

      final third = resolver.resolve(
        project,
        registry,
        _features(time: 2 / 60, energyShort: 1),
      );
      final expected = afterRelease + (1 - afterRelease) * attack;
      expect(third['one']!['value'], closeTo(expected, 1e-12));
    });

    test('zero smoothing intervals immediately select the target', () {
      final manifest = _manifest(
        bindings: const <WidgetBindingSpec>[
          WidgetBindingSpec(
            id: 'energy',
            feature: 'energy.short',
            attackMs: 0,
            releaseMs: 0,
          ),
        ],
        expressions: const <String, String>{'value': 'bind.energy'},
      );
      final registry = ManifestRegistry(<WidgetManifest>[manifest]);
      final project = _project(<SceneLayer>[_layer('one')]);
      final resolver = BindingResolver();
      expect(
        resolver.resolve(project, registry, _features(energyShort: 1)),
        <String, Map<String, double>>{
          'one': <String, double>{'value': 1},
        },
      );
      expect(
        resolver.resolve(project, registry, _features(energyShort: 0.3)),
        <String, Map<String, double>>{
          'one': <String, double>{'value': 0.3},
        },
      );
    });

    test('linear, ease, and expo shape the same smoothing step', () {
      final manifest = _manifest(
        bindings: const <WidgetBindingSpec>[
          WidgetBindingSpec(
            id: 'linear',
            feature: 'energy.short',
            attackMs: 1000,
            curve: 'linear',
          ),
          WidgetBindingSpec(
            id: 'ease',
            feature: 'energy.short',
            attackMs: 1000,
            curve: 'ease',
          ),
          WidgetBindingSpec(
            id: 'expo',
            feature: 'energy.short',
            attackMs: 1000,
            curve: 'expo',
          ),
        ],
        expressions: const <String, String>{
          'linear': 'bind.linear',
          'ease': 'bind.ease',
          'expo': 'bind.expo',
        },
      );
      final values = BindingResolver().resolve(
        _project(<SceneLayer>[_layer('one')]),
        ManifestRegistry(<WidgetManifest>[manifest]),
        _features(energyShort: 1),
      )['one']!;
      final step = 1 - math.exp(-(1000 / 60) / 1000);

      expect(values['linear'], closeTo(step, 1e-12));
      expect(values['ease'], closeTo(step * step * (3 - 2 * step), 1e-12));
      expect(values['expo'], closeTo(1 - math.pow(2, -10 * step), 1e-12));
      expect(values['ease']!, lessThan(values['linear']!));
      expect(values['linear']!, lessThan(values['expo']!));
    });

    test('invalid binding configuration fails readably', () {
      final invalidCurve = _manifest(
        bindings: const <WidgetBindingSpec>[
          WidgetBindingSpec(
            id: 'bad',
            feature: 'energy.short',
            curve: 'bounce',
          ),
        ],
        expressions: const <String, String>{'value': 'bind.bad'},
      );
      expect(
        () => BindingResolver().resolve(
          _project(<SceneLayer>[_layer('one')]),
          ManifestRegistry(<WidgetManifest>[invalidCurve]),
          _features(energyShort: 1),
        ),
        throwsA(
          isA<ExpressionException>().having(
            (error) => error.message,
            'message',
            contains('unknown curve "bounce"'),
          ),
        ),
      );

      final negative = _manifest(
        bindings: const <WidgetBindingSpec>[
          WidgetBindingSpec(id: 'bad', feature: 'energy.short', attackMs: -1),
        ],
        expressions: const <String, String>{'value': 'bind.bad'},
      );
      expect(
        () => BindingResolver().resolve(
          _project(<SceneLayer>[_layer('one')]),
          ManifestRegistry(<WidgetManifest>[negative]),
          _features(energyShort: 1),
        ),
        throwsA(isA<ExpressionException>()),
      );
    });
  });

  group('determinism and reset', () {
    test('reset reproduces the initial frame after seek or project reload', () {
      final manifest = _manifest(
        bindings: const <WidgetBindingSpec>[
          WidgetBindingSpec(
            id: 'energy',
            feature: 'energy.short',
            attackMs: 200,
            releaseMs: 200,
          ),
        ],
        expressions: const <String, String>{'value': 'bind.energy'},
      );
      final registry = ManifestRegistry(<WidgetManifest>[manifest]);
      final project = _project(<SceneLayer>[_layer('one')]);
      final resolver = BindingResolver();
      final initial = resolver.resolve(
        project,
        registry,
        _features(energyShort: 1),
      );
      final advanced = resolver.resolve(
        project,
        registry,
        _features(time: 1 / 60, energyShort: 1),
      );
      expect(advanced, isNot(initial));

      resolver.reset();
      final afterSeekReset = resolver.resolve(
        project,
        registry,
        _features(energyShort: 1),
      );
      expect(afterSeekReset, initial);

      resolver.resolve(project, registry, _features(energyShort: 1));
      resolver.reset();
      final reloadedProject = _project(<SceneLayer>[_layer('one')]);
      final afterProjectReset = resolver.resolve(
        reloadedProject,
        registry,
        _features(energyShort: 1),
      );
      expect(afterProjectReset, initial);
    });

    test('identical sequential frame streams produce identical results', () {
      final manifest = _manifest(
        bindings: const <WidgetBindingSpec>[
          WidgetBindingSpec(
            id: 'energy',
            feature: 'energy.short',
            attackMs: 150,
            releaseMs: 250,
            curve: 'ease',
          ),
        ],
        expressions: const <String, String>{
          'value': 'bind.energy * time.progress',
        },
      );
      final registry = ManifestRegistry(<WidgetManifest>[manifest]);
      final project = _project(<SceneLayer>[_layer('one')]);
      final firstResolver = BindingResolver();
      final secondResolver = BindingResolver();
      final targets = <double>[0, 0.2, 0.9, 1, 0.4, 0, 0.7, 0.7];

      for (var index = 0; index < targets.length; index++) {
        final feature = _features(
          time: index / 60,
          energyShort: targets[index],
        );
        final first = firstResolver.resolve(project, registry, feature);
        final second = secondResolver.resolve(project, registry, feature);
        expect(second, first, reason: 'frame $index');
      }

      final extraFrame = firstResolver.resolve(
        project,
        registry,
        _features(time: targets.length / 60, energyShort: 1),
      );
      secondResolver.reset();
      for (var index = 0; index < targets.length; index++) {
        secondResolver.resolve(
          project,
          registry,
          _features(time: index / 60, energyShort: targets[index]),
        );
      }
      expect(
        secondResolver.resolve(
          project,
          registry,
          _features(time: targets.length / 60, energyShort: 1),
        ),
        extraFrame,
      );
    });
  });
}

WidgetManifest _manifest({
  List<WidgetBindingSpec> bindings = const <WidgetBindingSpec>[],
  Map<String, String> expressions = const <String, String>{},
}) {
  return WidgetManifest(
    id: 'test.widget',
    version: '1.0.0',
    name: LocalizedText(<String, String>{'en': 'Test'}),
    author: 'Tests',
    category: 'test',
    parameters: <ParameterSpec>[
      ParameterSpec(
        id: 'pulse',
        type: ParameterType.float,
        label: LocalizedText(<String, String>{'en': 'Pulse'}),
        defaultValue: 0.25,
      ),
      ParameterSpec(
        id: 'enabled',
        type: ParameterType.boolean,
        label: LocalizedText(<String, String>{'en': 'Enabled'}),
        defaultValue: false,
      ),
    ],
    bindings: bindings,
    expressions: expressions,
    render: const WidgetRenderSpec(type: 'native', id: 'test'),
    needsAudio: true,
    needsLyrics: false,
    defaultWidth: 100,
    defaultHeight: 100,
  );
}

SceneProject _project(List<SceneLayer> layers, {int fps = 60}) {
  return SceneProject(
    name: 'Test',
    canvas: SceneCanvas(
      width: 1920,
      height: 1080,
      aspect: '16:9',
      fps: fps,
      duration: 10,
    ),
    layers: layers,
  );
}

SceneLayer _layer(String id, {Map<String, Object?>? params}) {
  return SceneLayer(
    id: id,
    widgetId: 'test.widget',
    name: id,
    rect: const SceneRect(x: 0, y: 0, width: 100, height: 100),
    params: params,
  );
}

FeatureSnapshot _features({
  double time = 0,
  double rms = 0,
  double peak = 0,
  double energyShort = 0,
  double beatPhase = 0.25,
  int beatIndex = 0,
  Map<String, double>? bands,
}) {
  return FeatureSnapshot(
    time: time,
    duration: 10,
    rms: rms,
    peak: peak,
    energyShort: energyShort,
    energyLong: 0.1,
    bpm: 120,
    beatPhase: beatPhase,
    beatIndex: beatIndex,
    spectrum: Float64List(64),
    waveform: Float64List(128),
    bands: bands,
  );
}
