// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:visusic_core/visusic_core.dart';

/// Deterministic CustomPainter for the scene, library thumbnails, and export.
final class ScenePainter extends CustomPainter {
  /// Creates a scene painter.
  ScenePainter({
    required this.project,
    required this.features,
    this.images = const <String, ui.Image>{},
    this.expressionValues = const <String, Map<String, double>>{},
    this.shaderPrograms = const <String, ui.FragmentProgram>{},
  });

  /// Scene document to draw.
  final SceneProject project;

  /// Time-dependent feature values.
  final FeatureSnapshot features;

  /// Decoded project images keyed by asset ID.
  final Map<String, ui.Image> images;

  /// Evaluated manifest expressions keyed by layer ID.
  final Map<String, Map<String, double>> expressionValues;

  /// Preloaded GLSL fragment programs keyed by widget ID.
  final Map<String, ui.FragmentProgram> shaderPrograms;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / project.canvas.width;
    final scaleY = size.height / project.canvas.height;
    final logicalSize = Size(
      project.canvas.width.toDouble(),
      project.canvas.height.toDouble(),
    );
    canvas.save();
    canvas.scale(scaleX, scaleY);
    final shake = _effect('shake') * 20;
    if (shake > 0) {
      final phase = features.beatPhase * math.pi * 2;
      canvas.translate(
        math.sin(phase * 3) * shake,
        math.cos(phase * 5) * shake,
      );
    }
    canvas.drawRect(
      Offset.zero & logicalSize,
      Paint()..color = parseSceneColor(project.canvas.background),
    );
    final hasSolo = project.layers.any((layer) => layer.solo);
    final hasText = project.layers.any(
      (layer) =>
          !layer.hidden &&
          (layer.widgetId == 'builtin.text' ||
              layer.widgetId == 'builtin.title' ||
              layer.widgetId == 'builtin.karaoke' ||
              layer.widgetId == 'builtin.rollingLyrics'),
    );
    for (final layer in project.layers) {
      if (layer.hidden || layer.muted || (hasSolo && !layer.solo)) {
        continue;
      }
      final timeMs = features.time * 1000;
      if (timeMs < layer.timing.inMs ||
          (layer.timing.outMs != null && timeMs > layer.timing.outMs!)) {
        continue;
      }
      if (layer.widgetId == 'builtin.scrim' && !hasText) {
        continue;
      }
      _paintLayer(canvas, layer, timeMs);
    }
    _paintPostFx(canvas, logicalSize);
    canvas.restore();
  }

  void _paintPostFx(Canvas canvas, Size size) {
    final vignette = _effect('vignette');
    if (vignette > 0) {
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          size.center(Offset.zero),
          size.longestSide * 0.75,
          <Color>[
            const Color(0x00000000),
            _black.withValues(alpha: vignette * 0.85),
          ],
        );
      canvas.drawRect(Offset.zero & size, paint);
    }
    final grain = _effect('grain');
    if (grain > 0) {
      final paint = Paint()
        ..color = _white.withValues(alpha: grain * 0.12);
      for (var index = 0; index < 900; index++) {
        final x = _noise(index) * size.width;
        final y = _noise(index * 3 + 7) * size.height;
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
    final bloom = _effect('bloom');
    if (bloom > 0) {
      final energy = features.energyShort.clamp(0, 1).toDouble();
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          size.center(Offset.zero),
          size.shortestSide * 0.5,
          <Color>[
            _white.withValues(alpha: (0.08 + energy * 0.25) * bloom),
            const Color(0x00000000),
          ],
        );
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  double _effect(String id) {
    for (final effect in project.postFx) {
      if (effect.id == id) {
        return effect.intensity;
      }
    }
    return 0;
  }

  void _paintLayer(Canvas canvas, SceneLayer layer, double timeMs) {
    final rect = layer.rect;
    final params = <String, Object?>{
      for (final key in layer.params.keys)
        key: KeyframeAnimation.valueAt(layer, key, timeMs),
    };
    final transition = _Transition.resolve(layer.timing, timeMs);
    final expressions = expressionValues[layer.id] ?? const <String, double>{};
    final expressionScale = expressions['scale'] ?? 1;
    final localSize = Size(rect.width, rect.height);
    final entranceScale = transition.scale * expressionScale;

    canvas.save();
    canvas.translate(rect.centerX, rect.centerY);
    canvas.rotate(rect.rotation * math.pi / 180);
    canvas.translate(-rect.width / 2, -rect.height / 2);
    if (transition.slide != 0) {
      canvas.translate(transition.slide, 0);
    }
    if (entranceScale != 1) {
      canvas.translate(rect.width / 2, rect.height / 2);
      canvas.scale(entranceScale);
      canvas.translate(-rect.width / 2, -rect.height / 2);
    }
    if (transition.clipProgress < 1) {
      canvas.clipRect(
        Offset.zero & Size(rect.width * transition.clipProgress, rect.height),
      );
    }
    final needsLayer = transition.opacity < 1 || transition.blur > 0;
    if (needsLayer) {
      final layerPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: transition.opacity)
        ..imageFilter = transition.blur > 0
            ? ui.ImageFilter.blur(
                sigmaX: transition.blur,
                sigmaY: transition.blur,
              )
            : null;
      canvas.saveLayer(
        Offset(-rect.width, -rect.height) &
            Size(rect.width * 3, rect.height * 3),
        layerPaint,
      );
    }
    _paintNative(canvas, localSize, layer, params, expressions, timeMs);
    if (needsLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintNative(
    Canvas canvas,
    Size size,
    SceneLayer layer,
    Map<String, Object?> params,
    Map<String, double> expressions,
    double timeMs,
  ) {
    switch (layer.widgetId) {
      case 'builtin.rectangle':
        _paintRectangle(canvas, size, params);
      case 'builtin.text':
        _paintText(canvas, size, params, timeMs, isTitle: false);
      case 'builtin.title':
        _paintText(canvas, size, params, timeMs, isTitle: true);
      case 'builtin.image':
        _paintImage(canvas, size, params, timeMs);
      case 'builtin.barSpectrum':
        _paintSpectrum(canvas, size, params, expressions);
      case 'builtin.meshGradient':
        _paintMeshGradient(canvas, size, params);
      case 'builtin.particles':
        _paintParticles(canvas, size, params, expressions);
      case 'builtin.albumArt':
        _paintAlbumArt(canvas, size, params, timeMs);
      case 'builtin.progress':
        _paintProgress(canvas, size, params);
      case 'builtin.scrim':
        _paintScrim(canvas, size, params);
      case 'builtin.karaoke':
        _paintKaraoke(canvas, size, params);
      case 'builtin.rollingLyrics':
        _paintRollingLyrics(canvas, size, params);
      default:
        final program = shaderPrograms[layer.widgetId];
        if (program != null) {
          _paintShader(canvas, size, params, program);
        } else {
          _paintUnknown(canvas, size, layer.widgetId);
        }
    }
  }

  void _paintShader(
    Canvas canvas,
    Size size,
    Map<String, Object?> params,
    ui.FragmentProgram program,
  ) {
    final shader = program.fragmentShader();
    shader.setFloat(0, features.time.toDouble());
    shader.setFloat(1, _double(params, 'intensity', 0.6));
    shader.setFloat(2, _double(params, 'speed', 2));
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  void _paintRectangle(Canvas canvas, Size size, Map<String, Object?> params) {
    final opacity = _double(params, 'opacity', 1);
    final radius = _double(
      params,
      'cornerRadius',
      0,
    ).clamp(0, size.shortestSide / 2).toDouble();
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final colors = _colors(params['fill'], const <Color>[Color(0xFF7C4DFF)]);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors
            .map((color) => color.withValues(alpha: color.a * opacity))
            .toList(),
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect, paint);
    final borderWidth = _double(params, 'borderWidth', 0);
    if (borderWidth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..color = parseSceneColor(_string(params, 'borderColor', '#FFFFFF'))
              .withValues(alpha: opacity),
      );
    }
  }

  void _paintText(
    Canvas canvas,
    Size size,
    Map<String, Object?> params,
    double timeMs, {
    required bool isTitle,
  }) {
    final source = _string(params, 'text', 'Your text');
    final revealMode = _string(
      params,
      'reveal',
      isTitle ? 'perLetter' : 'none',
    );
    final progress = (timeMs / 1200).clamp(0, 1).toDouble();
    final runes = source.runes.toList(growable: false);
    final visibleCount = revealMode == 'typewriter'
        ? (runes.length * progress).ceil().clamp(0, runes.length)
        : runes.length;
    final visibleText = String.fromCharCodes(runes.take(visibleCount));
    final fontSize = _double(params, 'size', isTitle ? 112 : 72);
    final weight = switch (_string(params, 'weight', 'medium')) {
      'bold' => FontWeight.w700,
      'regular' => FontWeight.w400,
      _ => FontWeight.w500,
    };
    final align = switch (_string(params, 'align', 'center')) {
      'left' => TextAlign.left,
      'right' => TextAlign.right,
      _ => TextAlign.center,
    };
    final baseOpacity = revealMode == 'fade' ? progress : 1.0;
    TextStyle style = TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: _double(params, 'letterSpacing', 0),
      height: 1.15,
    );
    List<InlineSpan> spans;
    if (revealMode == 'perLetter' && progress < 1) {
      spans = <InlineSpan>[
        for (var index = 0; index < runes.length; index++)
          TextSpan(
            text: String.fromCharCode(runes[index]),
            style: style.copyWith(
              color: _white.withValues(
                alpha: ((progress * (runes.length + 4) - index) / 4)
                    .clamp(0, 1)
                    .toDouble(),
              ),
            ),
          ),
      ];
    } else {
      spans = <InlineSpan>[TextSpan(text: visibleText, style: style)];
    }
    final painter = TextPainter(
      text: TextSpan(children: spans),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    final rect = Offset.zero & size;
    final gradientSource = isTitle ? params['fill'] : null;
    if (gradientSource != null) {
      painter.text = TextSpan(
        children: spans,
        style: TextStyle(
          foreground: Paint()
            ..shader = LinearGradient(
              colors: _colors(gradientSource, const <Color>[_white]),
            ).createShader(rect),
        ),
      );
      painter.layout(maxWidth: size.width);
    } else {
      style = style.copyWith(
        color: parseSceneColor(_string(params, 'color', '#FFFFFF'))
            .withValues(alpha: baseOpacity),
      );
      painter.text = TextSpan(children: spans, style: style);
      painter.layout(maxWidth: size.width);
    }
    if (revealMode == 'slide' && progress < 1) {
      canvas.save();
      canvas.translate(0, size.height * (1 - progress) * 0.35);
    }
    painter.paint(canvas, Offset(0, (size.height - painter.height) / 2));
    if (revealMode == 'slide' && progress < 1) {
      canvas.restore();
    }
  }

  void _paintImage(
    Canvas canvas,
    Size size,
    Map<String, Object?> params,
    double timeMs,
  ) {
    final corner = _double(params, 'cornerRadius', 0);
    final clip = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(corner.clamp(0, size.shortestSide / 2).toDouble()),
    );
    final opacity = _double(params, 'opacity', 1);
    canvas.save();
    canvas.clipRRect(clip);
    final image = images[_string(params, 'asset', '')];
    if (image == null) {
      _paintImagePlaceholder(canvas, size, opacity);
    } else {
      final source = Size(image.width.toDouble(), image.height.toDouble());
      final fit = _string(params, 'fit', 'cover');
      final scale = fit == 'contain'
          ? _min(size.width / source.width, size.height / source.height)
          : _max(size.width / source.width, size.height / source.height);
      final destinationSize = source * scale;
      final origin = Offset(
        (size.width - destinationSize.width) / 2,
        (size.height - destinationSize.height) / 2,
      );
      canvas.drawImageRect(
        image,
        Offset.zero & source,
        origin & destinationSize,
        Paint()..color = _white.withValues(alpha: opacity),
      );
    }
    canvas.restore();
  }

  void _paintImagePlaceholder(Canvas canvas, Size size, double opacity) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF383348).withValues(alpha: opacity),
            const Color(0xFF17171E).withValues(alpha: opacity),
          ],
        ).createShader(Offset.zero & size),
    );
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.75)
      ..lineTo(size.width * 0.4, size.height * 0.45)
      ..lineTo(size.width * 0.55, size.height * 0.62)
      ..lineTo(size.width * 0.68, size.height * 0.5)
      ..lineTo(size.width * 0.84, size.height * 0.75)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF797189));
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.3),
      size.shortestSide * 0.07,
      Paint()..color = const Color(0xFFB69CFF),
    );
  }

  void _paintSpectrum(
    Canvas canvas,
    Size size,
    Map<String, Object?> params,
    Map<String, double> expressions,
  ) {
    final count = _int(params, 'barCount', 48).clamp(8, 96);
    final gap = _double(params, 'gap', 4);
    final mirror = _bool(params, 'mirror', false);
    final minHeight = _double(params, 'minHeight', 4);
    final radius = _double(params, 'cornerRadius', 4);
    final showPeaks = _bool(params, 'peaks', true);
    final boost = expressions['glowBoost'] ?? 0;
    final barWidth = _max(1, (size.width - gap * (count - 1)) / count);
    final shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: _colors(params['colors'], const <Color>[Color(0xFF7C4DFF)]),
    ).createShader(Offset.zero & size);
    final paint = Paint()
      ..shader = shader
      ..maskFilter = boost > 0
          ? MaskFilter.blur(BlurStyle.normal, boost)
          : null;
    for (var index = 0; index < count; index++) {
      final featureIndex =
          (index * (features.spectrum.length - 1) / (count - 1)).round();
      final value = features.spectrum[featureIndex];
      final totalHeight = _max(minHeight, value * size.height);
      final height = mirror ? totalHeight / 2 : totalHeight;
      final x = index * (barWidth + gap);
      final top = mirror ? size.height / 2 - height : size.height - height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, height),
        Radius.circular(_min(radius, barWidth / 2)),
      );
      canvas.drawRRect(rect, paint);
      if (mirror) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height / 2, barWidth, height),
            Radius.circular(_min(radius, barWidth / 2)),
          ),
          paint,
        );
      }
      if (showPeaks) {
        final peakY = _max(0, top - gap - 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, peakY, barWidth, _min(4, size.height / 40)),
            Radius.circular(_min(radius, barWidth / 2)),
          ),
          Paint()..color = _white.withValues(alpha: 0.75),
        );
      }
    }
  }

  void _paintMeshGradient(
    Canvas canvas,
    Size size,
    Map<String, Object?> params,
  ) {
    final colors = _colors(params['colors'], const <Color>[
      Color(0xFF101014),
      Color(0xFF7C4DFF),
      Color(0xFF3DDC97),
    ]);
    final speed = _double(params, 'speed', 0.25);
    final time = features.time * speed;
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.first);
    for (var index = 1; index < colors.length; index++) {
      final phase = time * (0.35 + index * 0.11) + index * 2.1;
      final center = Offset(
        size.width * (0.5 + math.sin(phase) * 0.36),
        size.height * (0.5 + math.cos(phase * 0.83) * 0.38),
      );
      final paint = Paint()
        ..color = colors[index].withValues(alpha: 0.72)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          size.shortestSide * 0.16,
        )
        ..blendMode = BlendMode.screen;
      canvas.drawCircle(center, size.shortestSide * 0.34, paint);
    }
  }

  void _paintParticles(
    Canvas canvas,
    Size size,
    Map<String, Object?> params,
    Map<String, double> expressions,
  ) {
    final count = _int(params, 'count', 140).clamp(10, 300);
    final speed = _double(params, 'speed', 0.4);
    final boost = expressions['speedBoost'] ?? 1;
    final time = features.time * speed * boost;
    final baseSize = _double(params, 'size', 4);
    final opacity = _double(params, 'opacity', 0.65);
    final mode = _string(params, 'mode', 'dust');
    final paint = Paint()
      ..color = parseSceneColor(_string(params, 'color', '#FFFFFF'))
          .withValues(alpha: opacity);
    for (var index = 0; index < count; index++) {
      final seedX = _noise(index + 1);
      final seedY = _noise(index * 7 + 13);
      final x =
          ((seedX + math.sin(time * 0.2 + index) * 0.025) % 1) * size.width;
      final y = ((seedY + time * (0.025 + seedX * 0.07)) % 1) * size.height;
      final particleSize = baseSize * (0.55 + seedY * 0.9);
      if (mode == 'rain') {
        canvas.drawLine(
          Offset(x, y),
          Offset(x - particleSize, y + particleSize * 5),
          paint..strokeWidth = _max(1, particleSize / 3),
        );
      } else if (mode == 'petals') {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(time + index);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: particleSize * 2,
            height: particleSize,
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(
          Offset(x, y),
          mode == 'sparks' ? particleSize * 0.45 : particleSize,
          paint,
        );
      }
    }
  }

  void _paintAlbumArt(
    Canvas canvas,
    Size size,
    Map<String, Object?> params,
    double timeMs,
  ) {
    final shape = _string(params, 'shape', 'vinyl');
    final kenBurns = _double(params, 'kenBurns', 0.08);
    final zoom = 1 + kenBurns * (0.5 + 0.5 * math.sin(timeMs * 0.00035));
    final shadow = _double(params, 'shadow', 0.35);
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (shadow > 0) {
      canvas.drawCircle(
        center.translate(0, size.height * 0.035),
        radius * 0.94,
        Paint()
          ..color = _black.withValues(alpha: shadow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.12),
      );
    }
    canvas.save();
    if (shape == 'circle' || shape == 'vinyl') {
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
    } else {
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius * 0.12),
        ),
      );
    }
    canvas.translate(center.dx, center.dy);
    canvas.scale(zoom);
    canvas.translate(-center.dx, -center.dy);
    final asset = images[_string(params, 'asset', '')];
    if (asset != null) {
      canvas.drawImageRect(
        asset,
        Rect.fromLTWH(0, 0, asset.width.toDouble(), asset.height.toDouble()),
        Offset.zero & size,
        Paint(),
      );
    } else {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const <Color>[Color(0xFF7C4DFF), Color(0xFFFF7A90)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawCircle(
        center,
        radius * 0.48,
        Paint()..color = _white.withValues(alpha: 0.12),
      );
      canvas.drawCircle(center, radius * 0.16, Paint()..color = _white);
    }
    canvas.restore();
    if (shape == 'vinyl') {
      final vinyl = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _max(2, radius * 0.025)
        ..color = _white.withValues(alpha: 0.16);
      for (var ring = 1; ring <= 6; ring++) {
        canvas.drawCircle(center, radius * (0.55 + ring * 0.055), vinyl);
      }
      canvas.drawCircle(
        center,
        radius * 0.2,
        Paint()..color = const Color(0xFF15151B),
      );
      canvas.drawCircle(center, radius * 0.055, Paint()..color = _white);
    }
  }

  void _paintProgress(Canvas canvas, Size size, Map<String, Object?> params) {
    final showTime = _bool(params, 'showTime', true);
    final thickness = _double(
      params,
      'thickness',
      8,
    ).clamp(2, size.height).toDouble();
    final y = showTime ? size.height * 0.28 : size.height / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y - thickness / 2, size.width, thickness),
      Radius.circular(thickness / 2),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = parseSceneColor(
          _string(params, 'backgroundColor', '#40FFFFFF'),
        ),
    );
    final progress = features.progress;
    if (progress > 0) {
      canvas.save();
      canvas.clipRRect(rect);
      canvas.drawRect(
        Rect.fromLTWH(0, y - thickness / 2, size.width * progress, thickness),
        Paint()..color = parseSceneColor(_string(params, 'color', '#B69CFF')),
      );
      canvas.restore();
    }
    if (showTime) {
      final painter = TextPainter(
        text: TextSpan(
          text: '${_time(features.time)} / ${_time(features.duration)}',
          style: TextStyle(
            color: parseSceneColor(_string(params, 'color', '#B69CFF')),
            fontFamily: 'Inter',
            fontSize: _max(11, size.height * 0.25),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      painter.paint(canvas, Offset(0, y + thickness));
    }
  }

  void _paintScrim(Canvas canvas, Size size, Map<String, Object?> params) {
    final color = parseSceneColor(_string(params, 'color', '#000000'));
    final opacity = _double(params, 'opacity', 0.5);
    final placement = _string(params, 'placement', 'bottom');
    final radius = _double(params, 'cornerRadius', 24);
    if (placement == 'top' || placement == 'bottom') {
      final gradient = LinearGradient(
        begin: placement == 'bottom'
            ? Alignment.topCenter
            : Alignment.bottomCenter,
        end: placement == 'bottom'
            ? Alignment.bottomCenter
            : Alignment.topCenter,
        colors: <Color>[
          color.withValues(alpha: 0),
          color.withValues(alpha: opacity),
        ],
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()..shader = gradient.createShader(Offset.zero & size),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  void _paintKaraoke(Canvas canvas, Size size, Map<String, Object?> params) {
    final line = features.lyricLine ?? '';
    final next = features.lyricNextLine;
    if (line.isEmpty) {
      return;
    }
    final fontSize = _double(params, 'size', 64);
    final colors = _colors(params['colors'], const <Color>[Color(0xFFFFFFFF)]);
    final mode = _string(params, 'mode', 'wipe');
    final align = _string(params, 'align', 'center');
    final inactive = _double(params, 'inactiveOpacity', 0.4);
    final wordIndex = features.lyricWordIndex.clamp(0, 1 << 30).toInt();
    final wordProgress = features.lyricWordProgress;
    final lineProgress = features.lyricLineProgress;
    final words = line.split(' ').where((word) => word.isNotEmpty).toList();
    final activeWordIndex = words.isEmpty ? 0 : wordIndex.clamp(0, words.length - 1).toInt();
    final base = TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    final gradient = LinearGradient(colors: colors);
    final inactivePaint = Paint()
      ..color = _white.withValues(alpha: inactive);
    final full = _layout(line, base, size.width);
    final contentHeight = full.height + (next != null ? fontSize * 0.75 : 0);
    var y = (size.height - contentHeight) / 2;
    final alignX = switch (align) {
      'left' => 0.0,
      'right' => size.width - full.width,
      _ => (size.width - full.width) / 2,
    };
    _drawLine(canvas, line, base, inactivePaint, alignX, y, size.width);
    switch (mode) {
      case 'wipe':
        final clipWidth = full.width * lineProgress;
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(alignX, y - 6, clipWidth, full.height + 12));
        _drawGradient(canvas, line, base, gradient, alignX, y, size.width);
        canvas.restore();
      case 'perLetter' || 'glow' || 'bounce':
        final active = words.isEmpty ? line : words[activeWordIndex];
        final prefix = words.isEmpty
            ? ''
            : words.take(activeWordIndex).join(' ');
        final prefixWidth = prefix.isEmpty
            ? 0.0
            : _layout('$prefix ', base, size.width).width;
        final activeWidth = _layout(active, base, size.width).width;
        final offset = Offset(alignX + prefixWidth, y);
        if (mode == 'bounce') {
          final bounce = math.sin(features.beatPhase * math.pi) * fontSize * 0.12;
          canvas.save();
          canvas.translate(offset.dx, offset.dy + bounce);
        } else if (mode == 'glow') {
          final glow = Paint()
            ..shader = gradient.createShader(
              Rect.fromLTWH(0, y, activeWidth, full.height),
            )
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, fontSize * 0.12);
          canvas.save();
          canvas.translate(offset.dx, offset.dy);
          _drawLine(canvas, active, base, glow, 0, 0, activeWidth);
          canvas.restore();
          canvas.save();
          canvas.translate(offset.dx, offset.dy);
        } else {
          canvas.save();
          canvas.translate(offset.dx, offset.dy);
        }
        final highlight = mode == 'perLetter'
            ? String.fromCharCodes(
                active.runes.take(
                  (active.runes.length * wordProgress)
                      .ceil()
                      .clamp(0, active.runes.length),
                ),
              )
            : active;
        if (highlight.isNotEmpty) {
          final shader = gradient.createShader(
            Rect.fromLTWH(0, 0, activeWidth, full.height),
          );
          _drawLine(canvas, highlight, base, Paint()..shader = shader, 0, 0, activeWidth);
        }
        canvas.restore();
    }
    if (next != null) {
      final nextY = y + full.height + fontSize * 0.2;
      final nextPaint = Paint()
        ..color = _white.withValues(alpha: inactive * 0.7);
      _drawLine(canvas, next, base.copyWith(fontSize: fontSize * 0.72), nextPaint, alignX, nextY, size.width);
    }
  }

  void _paintRollingLyrics(Canvas canvas, Size size, Map<String, Object?> params) {
    final fontSize = _double(params, 'size', 36);
    final color = parseSceneColor(_string(params, 'color', '#FFFFFF'));
    final activeColor = parseSceneColor(_string(params, 'activeColor', '#B69CFF'));
    final visible = _int(params, 'lines', 5).clamp(3, 7).toInt();
    final center = visible ~/ 2;
    final lineHeight = fontSize * 1.5;
    final top = (size.height - lineHeight * visible) / 2;
    for (var offset = -center; offset <= center; offset++) {
      final index = features.lyricLineIndex + offset;
      if (index < 0) {
        continue;
      }
      // Rolling lyrics need surrounding lines; approximate with the active line.
      final isActive = offset == 0;
      if (!isActive && (features.lyricLine == null)) {
        continue;
      }
      final style = TextStyle(
        fontFamily: 'Inter',
        fontSize: isActive ? fontSize : fontSize * 0.82,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
        color: isActive ? activeColor : color.withValues(alpha: 0.55),
      );
      final text = isActive ? (features.lyricLine ?? '') : (features.lyricNextLine ?? '');
      final painter = _layout(text, style, size.width);
      painter.paint(
        canvas,
        Offset((size.width - painter.width) / 2, top + (offset + center) * lineHeight),
      );
    }
  }

  TextPainter _layout(String text, TextStyle style, double maxWidth) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
  }

  void _drawLine(
    Canvas canvas,
    String text,
    TextStyle style,
    Paint paint,
    double x,
    double y,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          color: paint.shader == null ? paint.color : null,
          foreground: paint.shader != null ? paint : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, y));
  }

  void _drawGradient(
    Canvas canvas,
    String text,
    TextStyle style,
    LinearGradient gradient,
    double x,
    double y,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          foreground: Paint()..shader = gradient.createShader(Rect.fromLTWH(x, y, maxWidth, style.fontSize ?? 64)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, y));
  }

  void _paintUnknown(Canvas canvas, Size size, String id) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      Paint()..color = const Color(0xFF7A3145),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: 'Unknown widget\n$id',
        style: const TextStyle(color: _white, fontSize: 24),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    painter.paint(
      canvas,
      Offset(16, _max(16, (size.height - painter.height) / 2)),
    );
  }

  @override
  bool shouldRepaint(ScenePainter oldDelegate) {
    return oldDelegate.project != project ||
        oldDelegate.features.time != features.time ||
        oldDelegate.features.duration != features.duration ||
        oldDelegate.images != images ||
        oldDelegate.shaderPrograms != shaderPrograms ||
        oldDelegate.expressionValues != expressionValues;
  }
}

final class _Transition {
  const _Transition({
    this.opacity = 1,
    this.scale = 1,
    this.slide = 0,
    this.blur = 0,
    this.clipProgress = 1,
  });

  final double opacity;
  final double scale;
  final double slide;
  final double blur;
  final double clipProgress;

  static _Transition resolve(LayerTiming timing, double timeMs) {
    _Transition fromAnimation(
      LayerAnimation animation,
      double progress,
      bool exiting,
    ) {
      if (animation.durationMs <= 0 ||
          animation.style == 'none' ||
          progress >= 1) {
        return const _Transition();
      }
      final amount = (exiting ? 1 - progress : progress).clamp(0, 1).toDouble();
      return switch (animation.style) {
        'fade' => _Transition(opacity: amount),
        'slide' => _Transition(opacity: amount, slide: (1 - amount) * 90),
        'scale' => _Transition(opacity: amount, scale: 0.75 + amount * 0.25),
        'blurIn' => _Transition(opacity: amount, blur: (1 - amount) * 12),
        'maskWipe' => _Transition(clipProgress: amount),
        _ => const _Transition(),
      };
    }

    final enterElapsed = timeMs - timing.inMs;
    if (timing.enter.style != 'none' &&
        enterElapsed < timing.enter.durationMs) {
      return fromAnimation(
        timing.enter,
        (enterElapsed / timing.enter.durationMs).clamp(0, 1),
        false,
      );
    }
    final outMs = timing.outMs;
    if (outMs != null && timing.exit.style != 'none') {
      final remaining = outMs - timeMs;
      if (remaining < timing.exit.durationMs) {
        return fromAnimation(
          timing.exit,
          (remaining / timing.exit.durationMs).clamp(0, 1),
          true,
        );
      }
    }
    return const _Transition();
  }
}

const Color _white = Color(0xFFFFFFFF);
const Color _black = Color(0xFF000000);

double _min(num a, num b) => math.min(a, b).toDouble();
double _max(num a, num b) => math.max(a, b).toDouble();

/// Parses #RRGGBB or #AARRGGBB without leaking Flutter into project models.
Color parseSceneColor(String value) {
  final hex = value.startsWith('#') ? value.substring(1) : value;
  if (hex.length != 6 && hex.length != 8) {
    return const Color(0xFFFF00FF);
  }
  final numeric = int.tryParse(hex, radix: 16);
  if (numeric == null) {
    return const Color(0xFFFF00FF);
  }
  return Color(hex.length == 6 ? 0xFF000000 | numeric : numeric);
}

double _double(Map<String, Object?> params, String id, double fallback) {
  final value = params[id];
  return value is num ? value.toDouble() : fallback;
}

int _int(Map<String, Object?> params, String id, int fallback) {
  final value = params[id];
  return value is num ? value.toInt() : fallback;
}

bool _bool(Map<String, Object?> params, String id, bool fallback) {
  final value = params[id];
  return value is bool ? value : fallback;
}

String _string(Map<String, Object?> params, String id, String fallback) {
  final value = params[id];
  return value is String ? value : fallback;
}

List<Color> _colors(Object? value, List<Color> fallback) {
  if (value is! List || value.isEmpty) {
    return fallback;
  }
  final colors = value
      .whereType<String>()
      .map(parseSceneColor)
      .toList(growable: false);
  return colors.isEmpty ? fallback : colors;
}

String _time(double seconds) {
  final safe = seconds < 0 ? 0 : seconds.floor();
  final minutes = safe ~/ 60;
  final remainder = safe % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

double _noise(int value) {
  final x = math.sin(value * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
}
