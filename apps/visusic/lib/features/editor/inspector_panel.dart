// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (c) 2026 Donya

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:visusic/app/localization/generated/app_localizations.dart';
import 'package:visusic/features/editor/editor_controller.dart';
import 'package:visusic_core/visusic_core.dart';
import 'package:visusic_render/visusic_render.dart';

/// Full schema-driven layer inspector with design, motion, and reactions.
final class InspectorPanel extends StatelessWidget {
  /// Creates the inspector.
  const InspectorPanel({required this.controller, super.key});

  /// Current editor state.
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final layer = controller.selectedLayer;
    final l10n = AppLocalizations.of(context);
    if (layer == null) {
      return _EmptyInspector(message: l10n.selectLayer);
    }
    final manifest = controller.registry.byId[layer.widgetId];
    if (manifest == null) {
      return _EmptyInspector(message: '${l10n.unknownWidget}: ${layer.widgetId}');
    }
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          TabBar(
            labelStyle: const TextStyle(fontSize: 12),
            tabs: <Tab>[
              Tab(text: l10n.design),
              Tab(text: l10n.motion),
              Tab(text: l10n.reactions),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _DesignTab(controller: controller, layer: layer, manifest: manifest),
                _MotionTab(controller: controller, layer: layer),
                _ReactionsTab(manifest: manifest, layer: layer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _EmptyInspector extends StatelessWidget {
  const _EmptyInspector({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.tune_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

final class _DesignTab extends StatelessWidget {
  const _DesignTab({
    required this.controller,
    required this.layer,
    required this.manifest,
  });
  final EditorController controller;
  final SceneLayer layer;
  final WidgetManifest manifest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        TextFormField(
          key: ValueKey<String>('name-${layer.id}'),
          initialValue: layer.name,
          decoration: InputDecoration(labelText: l10n.layerName),
          onFieldSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              controller.commitLayerChange(layer, layer.copyWith(name: value.trim()));
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: layer.widgetId,
          decoration: InputDecoration(labelText: l10n.replaceWidget),
          items: controller.registry.manifests
              .map(
                (candidate) => DropdownMenuItem<String>(
                  value: candidate.id,
                  child: Text(
                    candidate.name.resolve(Localizations.localeOf(context).languageCode),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (id) {
            if (id != null && id != layer.widgetId) {
              controller.replaceWidget(layer, controller.registry.require(id));
            }
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 4,
          children: <Widget>[
            IconButton(
              tooltip: layer.locked ? l10n.unlock : l10n.lock,
              onPressed: () => controller.commitLayerChange(
                layer,
                layer.copyWith(locked: !layer.locked),
              ),
              icon: Icon(layer.locked ? Icons.lock_rounded : Icons.lock_open_rounded),
            ),
            IconButton(
              tooltip: layer.hidden ? l10n.show : l10n.hide,
              onPressed: () => controller.commitLayerChange(
                layer,
                layer.copyWith(hidden: !layer.hidden),
              ),
              icon: Icon(layer.hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            ),
            IconButton(
              tooltip: l10n.duplicate,
              onPressed: () {
                controller
                  ..select(layer.id)
                  ..duplicateSelected();
              },
              icon: const Icon(Icons.content_copy_outlined),
            ),
            IconButton(
              tooltip: l10n.delete,
              onPressed: () {
                controller
                  ..select(layer.id)
                  ..deleteSelected();
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        const Divider(height: 24),
        for (final parameter in manifest.parameters) ...<Widget>[
          ParameterEditor(
            key: ValueKey<String>('${layer.id}-${parameter.id}'),
            controller: controller,
            layer: layer,
            parameter: parameter,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

final class _MotionTab extends StatelessWidget {
  const _MotionTab({required this.controller, required this.layer});
  final EditorController controller;
  final SceneLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final duration = controller.project.canvas.duration * 1000;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(l10n.layerTiming, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        _TimeField(
          label: l10n.inPoint,
          value: layer.timing.inMs,
          maximum: duration,
          onChanged: (value) => controller.commitLayerChange(
            layer,
            layer.copyWith(timing: layer.timing.copyWith(inMs: value)),
          ),
        ),
        const SizedBox(height: 12),
        _TimeField(
          label: l10n.outPoint,
          value: layer.timing.outMs ?? duration,
          maximum: duration,
          onChanged: (value) => controller.commitLayerChange(
            layer,
            layer.copyWith(timing: layer.timing.copyWith(outMs: value)),
          ),
        ),
        const Divider(height: 28),
        _AnimationEditor(
          label: l10n.enter,
          animation: layer.timing.enter,
          onChanged: (animation) => controller.commitLayerChange(
            layer,
            layer.copyWith(timing: layer.timing.copyWith(enter: animation)),
          ),
        ),
        const SizedBox(height: 16),
        _AnimationEditor(
          label: l10n.exit,
          animation: layer.timing.exit,
          onChanged: (animation) => controller.commitLayerChange(
            layer,
            layer.copyWith(timing: layer.timing.copyWith(exit: animation)),
          ),
        ),
        const Divider(height: 28),
        Text(l10n.keyframes, style: Theme.of(context).textTheme.titleSmall),
        if (layer.keyframes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l10n.noKeyframes),
          ),
        for (final entry in layer.keyframes.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.key),
            subtitle: Text(l10n.keyframeCount(entry.value.length)),
            trailing: IconButton(
              tooltip: l10n.clear,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => controller.clearKeyframes(layer, entry.key),
            ),
          ),
      ],
    );
  }
}

final class _ReactionsTab extends StatelessWidget {
  const _ReactionsTab({required this.manifest, required this.layer});
  final WidgetManifest manifest;
  final SceneLayer layer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Chip(
          avatar: const Icon(Icons.science_outlined, size: 18),
          label: Text(l10n.demoSignal),
        ),
        const SizedBox(height: 16),
        Text(l10n.demoSignalExplanation),
        const Divider(height: 28),
        if (manifest.bindings.isEmpty)
          Text(l10n.noBindings)
        else
          for (final binding in manifest.bindings)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.music_note_outlined),
                title: Text(binding.id),
                subtitle: Text(
                  '${binding.feature}\n${l10n.attack}: ${binding.attackMs} ms · ${l10n.release}: ${binding.releaseMs} ms · ${binding.curve}',
                ),
              ),
            ),
        if (manifest.expressions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(l10n.expressions, style: Theme.of(context).textTheme.titleSmall),
          for (final entry in manifest.expressions.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SelectableText('${entry.key} = ${entry.value}'),
            ),
        ],
      ],
    );
  }
}

final class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.maximum,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double maximum;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey<String>('$label-$value'),
      initialValue: (value / 1000).toStringAsFixed(2),
      decoration: InputDecoration(labelText: label, suffixText: 's'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      onFieldSubmitted: (text) {
        final seconds = double.tryParse(text);
        if (seconds != null && seconds >= 0 && seconds <= maximum / 1000) {
          onChanged(seconds * 1000);
        }
      },
    );
  }
}

final class _AnimationEditor extends StatelessWidget {
  const _AnimationEditor({
    required this.label,
    required this.animation,
    required this.onChanged,
  });
  final String label;
  final LayerAnimation animation;
  final ValueChanged<LayerAnimation> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: animation.style,
          items: const <String>['none', 'fade', 'slide', 'scale', 'blurIn', 'maskWipe']
              .map(
                (style) => DropdownMenuItem<String>(
                  value: style,
                  child: Text(style),
                ),
              )
              .toList(),
          onChanged: (style) {
            if (style != null) {
              onChanged(LayerAnimation(style: style, durationMs: animation.durationMs));
            }
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey<String>('$label-${animation.durationMs}'),
          initialValue: animation.durationMs.toString(),
          decoration: InputDecoration(labelText: l10n.duration, suffixText: 'ms'),
          keyboardType: TextInputType.number,
          onFieldSubmitted: (value) {
            final duration = int.tryParse(value);
            if (duration != null && duration >= 0 && duration <= 10000) {
              onChanged(LayerAnimation(style: animation.style, durationMs: duration));
            }
          },
        ),
      ],
    );
  }
}

/// Automatically generated parameter control used by full and quick inspectors.
final class ParameterEditor extends StatefulWidget {
  /// Creates a parameter control.
  const ParameterEditor({
    required this.controller,
    required this.layer,
    required this.parameter,
    this.compact = false,
    super.key,
  });

  /// Current editor state.
  final EditorController controller;

  /// Layer being edited.
  final SceneLayer layer;

  /// Manifest parameter schema.
  final ParameterSpec parameter;

  /// Whether to use the floating canvas layout.
  final bool compact;

  @override
  State<ParameterEditor> createState() => _ParameterEditorState();
}

class _ParameterEditorState extends State<ParameterEditor> {
  SceneLayer? _dragBefore;

  @override
  Widget build(BuildContext context) {
    final parameter = widget.parameter;
    final value = widget.layer.params[parameter.id] ?? parameter.defaultValue;
    final label = parameter.label.resolve(Localizations.localeOf(context).languageCode);
    return switch (parameter.type) {
      ParameterType.float || ParameterType.integer => _numeric(label, value),
      ParameterType.boolean => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label),
        value: value == true,
        onChanged: (next) => _commit(_withValue(parameter.id, next)),
      ),
      ParameterType.enumeration || ParameterType.choiceCards => DropdownButtonFormField<String>(
        key: ValueKey<String>('${widget.layer.id}-${parameter.id}-$value'),
        initialValue: value as String,
        decoration: InputDecoration(labelText: label, isDense: widget.compact),
        items: parameter.options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(_localizedOption(context, option)),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) {
            _commit(_withValue(parameter.id, next));
          }
        },
      ),
      ParameterType.color => _ColorField(
        label: label,
        value: value as String,
        onChanged: (next) => _commit(_withValue(parameter.id, next)),
      ),
      ParameterType.gradient => _GradientField(
        label: label,
        values: (value as List).cast<String>(),
        onChanged: (next) => _commit(_withValue(parameter.id, next)),
      ),
      ParameterType.text || ParameterType.multiline || ParameterType.font => _TextParameter(
        key: ValueKey<String>('text-${widget.layer.id}-${parameter.id}'),
        label: label,
        value: value as String? ?? '',
        multiline: parameter.type == ParameterType.multiline,
        onPreview: (next) => widget.controller.previewLayer(_withValue(parameter.id, next)),
        onCommit: _commitCurrent,
      ),
      ParameterType.image => OutlinedButton.icon(
        onPressed: () async {
          try {
            await widget.controller.importImage(widget.layer);
          } on Object catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error.toString())),
              );
            }
          }
        },
        icon: const Icon(Icons.image_outlined),
        label: Text(
          (value as String).isEmpty
              ? AppLocalizations.of(context).chooseImage
              : AppLocalizations.of(context).replaceImage,
        ),
      ),
      ParameterType.group => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _numeric(String label, Object? value) {
    final parameter = widget.parameter;
    final current = (value as num).toDouble();
    final minimum = parameter.minimum ?? 0;
    final maximum = parameter.maximum ?? 100;
    final isInteger = parameter.type == ParameterType.integer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              '${isInteger ? current.round() : current.toStringAsFixed(2)}${parameter.unit == null ? '' : ' ${parameter.unit}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (!widget.compact)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: AppLocalizations.of(context).addKeyframe,
                onPressed: () => widget.controller.addKeyframe(
                  widget.layer,
                  parameter.id,
                ),
                icon: const Icon(Icons.diamond_outlined, size: 17),
              ),
          ],
        ),
        Slider(
          value: current.clamp(minimum, maximum),
          min: minimum,
          max: maximum,
          divisions: isInteger ? (maximum - minimum).round().clamp(1, 1000) : null,
          label: isInteger ? current.round().toString() : current.toStringAsFixed(2),
          onChangeStart: (_) => _dragBefore = widget.layer,
          onChanged: (next) {
            final normalized = isInteger ? next.round() : next;
            widget.controller.previewLayer(_withValue(parameter.id, normalized));
          },
          onChangeEnd: (_) => _commitCurrent(_dragBefore),
        ),
      ],
    );
  }

  void _commitCurrent(SceneLayer? before) {
    final start = before ?? _dragBefore;
    if (start != null) {
      final current = widget.controller.project.layerById(start.id);
      if (current != null) {
        widget.controller.commitLayerChange(start, current);
      }
      _dragBefore = null;
    }
  }

  void _commit(SceneLayer after) {
    widget.controller.commitLayerChange(widget.layer, after);
  }

  SceneLayer _withValue(String id, Object? value) {
    final layer = widget.controller.project.layerById(widget.layer.id) ?? widget.layer;
    return layer.copyWith(
      params: <String, Object?>{...layer.params, id: value},
    );
  }
}

final class _TextParameter extends StatefulWidget {
  const _TextParameter({
    required this.label,
    required this.value,
    required this.multiline,
    required this.onPreview,
    required this.onCommit,
    super.key,
  });
  final String label;
  final String value;
  final bool multiline;
  final ValueChanged<String> onPreview;
  final ValueChanged<SceneLayer?> onCommit;

  @override
  State<_TextParameter> createState() => _TextParameterState();
}

class _TextParameterState extends State<_TextParameter> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  SceneLayer? _before;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(_TextParameter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && _textController.text != widget.value) {
      _textController.text = widget.value;
    }
  }

  void _focusChanged() {
    if (_focusNode.hasFocus) {
      _before = context.findAncestorWidgetOfExactType<ParameterEditor>()?.layer;
    } else if (_before != null) {
      widget.onCommit(_before);
      _before = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      minLines: widget.multiline ? 2 : 1,
      maxLines: widget.multiline ? 4 : 1,
      decoration: InputDecoration(labelText: widget.label),
      onTap: () {
        _before = context.findAncestorWidgetOfExactType<ParameterEditor>()?.layer;
      },
      onChanged: widget.onPreview,
      onSubmitted: (_) => _focusNode.unfocus(),
    );
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_focusChanged)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }
}

final class _ColorField extends StatelessWidget {
  const _ColorField({required this.label, required this.value, required this.onChanged});
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        InkWell(
          key: Key('color-$label-$value'),
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final next = await showDialog<String>(
              context: context,
              builder: (_) => _ColorDialog(value: value),
            );
            if (next != null) {
              onChanged(next);
            }
          },
          child: Container(
            width: 48,
            height: 36,
            decoration: BoxDecoration(
              color: parseSceneColor(value),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ),
      ],
    );
  }
}

final class _GradientField extends StatelessWidget {
  const _GradientField({required this.label, required this.values, required this.onChanged});
  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (var index = 0; index < values.length; index++)
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  _ColorField(
                    label: '',
                    value: values[index],
                    onChanged: (next) {
                      final colors = [...values]..[index] = next;
                      onChanged(colors);
                    },
                  ),
                  if (values.length > 2)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final colors = [...values]..removeAt(index);
                          onChanged(colors);
                        },
                        icon: const Icon(Icons.remove_circle, size: 16),
                      ),
                    ),
                ],
              ),
            if (values.length < 6)
              IconButton.outlined(
                onPressed: () => onChanged(<String>[...values, values.last]),
                icon: const Icon(Icons.add_rounded),
              ),
          ],
        ),
      ],
    );
  }
}

final class _ColorDialog extends StatefulWidget {
  const _ColorDialog({required this.value});
  final String value;

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  static const List<String> _palette = <String>[
    '#FFFFFF', '#B69CFF', '#7C4DFF', '#3DDC97',
    '#3ABFF8', '#FFD84D', '#FF7A90', '#FF5252',
    '#101014', '#26232E', '#F4EBFF', '#E8F8F0',
    '#6930C3', '#009688', '#FF6D00', '#000000',
  ];
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).chooseColor),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final color in _palette)
                  InkWell(
                    onTap: () => Navigator.of(context).pop(color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: parseSceneColor(color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: '#RRGGBB / #AARRGGBB'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (RegExp(r'^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(value)) {
              Navigator.of(context).pop(value.toUpperCase());
            }
          },
          child: Text(AppLocalizations.of(context).apply),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

String _localizedOption(BuildContext context, String option) {
  if (Localizations.localeOf(context).languageCode != 'ru') {
    return option;
  }
  return const <String, String>{
    'left': 'Слева', 'center': 'По центру', 'right': 'Справа',
    'regular': 'Обычный', 'medium': 'Средний', 'bold': 'Жирный',
    'none': 'Нет', 'perLetter': 'По буквам', 'typewriter': 'Печатная машинка',
    'fade': 'Плавно', 'slide': 'Сдвиг', 'cover': 'Заполнить',
    'contain': 'Вписать', 'vinyl': 'Винил', 'square': 'Квадрат',
    'circle': 'Круг', 'dust': 'Пыль', 'snow': 'Снег', 'rain': 'Дождь',
    'petals': 'Лепестки', 'sparks': 'Искры', 'bottom': 'Снизу',
    'top': 'Сверху', 'full': 'Весь слой', 'scale': 'Масштаб',
    'blurIn': 'Размытие', 'maskWipe': 'Маска',
  }[option] ?? option;
}
