// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic_core/visusic_core.dart';

/// Demo transport, playhead slider, and layer timing lanes.
final class TimelinePanel extends StatelessWidget {
  /// Creates the timeline.
  const TimelinePanel({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final durationMs = controller.project.canvas.duration * 1000;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 54,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: <Widget>[
                  IconButton.filledTonal(
                    key: const Key('transport-play'),
                    tooltip: controller.playing ? l10n.pause : l10n.play,
                    onPressed: controller.togglePlayback,
                    icon: Icon(
                      controller.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_time(controller.features.time)} / ${_time(controller.features.duration)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      key: const Key('playhead-slider'),
                      value: controller.timeMs.clamp(0, durationMs),
                      max: durationMs,
                      onChanged: controller.seek,
                    ),
                  ),
                  Icon(
                    controller.hasAudio
                        ? Icons.music_note_rounded
                        : Icons.science_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    controller.hasAudio
                        ? '${controller.bpm.round()} BPM · ${controller.key}'
                        : l10n.demoSignal,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          if (controller.hasAudio)
            SizedBox(
              height: 36,
              child: CustomPaint(
                size: Size.infinite,
                painter: _WaveformPainter(controller.waveformPeaks),
              ),
            ),
          Expanded(
            child: controller.project.layers.isEmpty
                ? Center(
                    child: Text(
                      l10n.timelineEmpty,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    children: <Widget>[
                      for (final layer in controller.project.layers)
                        _TimingLane(
                          key: ValueKey<String>('timing-${layer.id}'),
                          layer: layer,
                          durationMs: durationMs,
                          selected: controller.selectedIds.contains(layer.id),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

final class _TimingLane extends StatelessWidget {
  const _TimingLane({
    required this.layer,
    required this.durationMs,
    required this.selected,
    super.key,
  });
  final SceneLayer layer;
  final double durationMs;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final outMs = layer.timing.outMs ?? durationMs;
    return SizedBox(
      height: 24,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = 110.0;
          final laneWidth = (constraints.maxWidth - labelWidth)
              .clamp(10, double.infinity)
              .toDouble();
          final left = layer.timing.inMs / durationMs * laneWidth;
          final width = ((outMs - layer.timing.inMs) / durationMs * laneWidth)
              .clamp(2, laneWidth)
              .toDouble();
          return Row(
            children: <Widget>[
              SizedBox(
                width: labelWidth,
                child: Text(
                  layer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: left,
                      top: 5,
                      width: width,
                      height: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: selected ? 0.9 : 0.45),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            for (final frames in layer.keyframes.values)
                              for (final _ in frames)
                                const Icon(Icons.diamond, size: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _time(double seconds) {
  final whole = seconds < 0 ? 0 : seconds.floor();
  return '${whole ~/ 60}:${(whole % 60).toString().padLeft(2, '0')}';
}

final class _WaveformPainter extends CustomPainter {
  _WaveformPainter(this.peaks);
  final Float32List peaks;

  @override
  void paint(Canvas canvas, Size size) {
    if (peaks.length < 2) {
      return;
    }
    final pairs = peaks.length ~/ 2;
    final center = size.height / 2;
    final paint = Paint()
      ..color = const Color(0xFFB69CFF)
      ..strokeWidth = 1;
    for (var index = 0; index < pairs; index++) {
      final x = index / pairs * size.width;
      final min = peaks[index * 2];
      final max = peaks[index * 2 + 1];
      canvas.drawLine(
        Offset(x, center - max * center),
        Offset(x, center - min * center),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.peaks != peaks;
}
