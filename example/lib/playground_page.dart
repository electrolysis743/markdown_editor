import 'package:flutter/material.dart';
import 'package:markdown_editor/markdown_editor.dart';
import 'package:markdown/markdown.dart' as md;

import 'customizations.dart';
import 'sample_document.dart';

/// A full featured editor playground.
class PlaygroundPage extends StatefulWidget {
  /// Creates the playground.
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final MarkdownEditorController _controller =
      MarkdownEditorController(text: kSampleMarkdown);

  MarkdownEditorMode _mode = MarkdownEditorMode.split;
  MarkdownMarkerVisibility _visibility = MarkdownMarkerVisibility.dimmed;
  bool _showToolbar = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildSettingsBar(context),
        const Divider(height: 1),
        Expanded(
          child: MarkdownEditor(
            controller: _controller,
            mode: _mode,
            theme: MarkdownEditorTheme(markerVisibility: _visibility),
            toolbar: MarkdownToolbarConfig(visible: _showToolbar, wrap: true),
            splitDirection: wide ? Axis.horizontal : Axis.vertical,
            splitRatio: 0.5,
            enableTabIndentation: true,
            builders: MarkdownEditorBuilders(
              statusBarBuilder: (BuildContext context) =>
                  _StatusBar(controller: _controller),
              codeBlockBuilder: _buildCodeBlock,
              inlineSyntaxes: <md.InlineSyntax>[MarkSyntax()],
              elementBuilders: <String, MarkdownElementBuilder>{
                'mark': MarkElementBuilder(),
              },
            ),
            onTapLink: (BuildContext context, String text, String? href, String title) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped link "$text" -> $href')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: <Widget>[
          SegmentedButton<MarkdownEditorMode>(
            segments: const <ButtonSegment<MarkdownEditorMode>>[
              ButtonSegment<MarkdownEditorMode>(
                value: MarkdownEditorMode.wysiwyg,
                label: Text('WYSIWYG'),
                icon: Icon(Icons.edit_note),
              ),
              ButtonSegment<MarkdownEditorMode>(
                value: MarkdownEditorMode.source,
                label: Text('Source'),
              ),
              ButtonSegment<MarkdownEditorMode>(
                value: MarkdownEditorMode.preview,
                label: Text('Preview'),
              ),
              ButtonSegment<MarkdownEditorMode>(
                value: MarkdownEditorMode.split,
                label: Text('Split'),
                icon: Icon(Icons.vertical_split),
              ),
            ],
            selected: <MarkdownEditorMode>{_mode},
            onSelectionChanged: (Set<MarkdownEditorMode> selection) {
              setState(() => _mode = selection.first);
            },
          ),
          const SizedBox(width: 16),
          DropdownButton<MarkdownMarkerVisibility>(
            value: _visibility,
            underline: const SizedBox.shrink(),
            onChanged: (MarkdownMarkerVisibility? value) {
              if (value != null) {
                setState(() => _visibility = value);
              }
            },
            items: const <DropdownMenuItem<MarkdownMarkerVisibility>>[
              DropdownMenuItem<MarkdownMarkerVisibility>(
                value: MarkdownMarkerVisibility.visible,
                child: Text('Markers: visible'),
              ),
              DropdownMenuItem<MarkdownMarkerVisibility>(
                value: MarkdownMarkerVisibility.dimmed,
                child: Text('Markers: dimmed'),
              ),
              DropdownMenuItem<MarkdownMarkerVisibility>(
                value: MarkdownMarkerVisibility.hidden,
                child: Text('Markers: hidden'),
              ),
            ],
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('Toolbar'),
            selected: _showToolbar,
            onSelected: (bool value) => setState(() => _showToolbar = value),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Markdown source'),
                content: SizedBox(
                  width: 600,
                  height: 400,
                  child: SingleChildScrollView(
                    child: SelectableText(_controller.text),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.data_object),
            label: const Text('Show source'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              _controller.clearHistory();
              _controller.text = kSampleMarkdown;
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(
    BuildContext context,
    MarkdownCodeBlockContext code,
  ) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (code.language != null)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  code.language!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          SelectableText(
            code.code,
            style: const TextStyle(fontFamily: 'monospace', height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.controller});

  final MarkdownEditorController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final String text = controller.text;
        final int words = text
            .split(RegExp(r'\s+'))
            .where((String word) => word.trim().isNotEmpty)
            .length;
        return Container(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: <Widget>[
              Text(
                '$words words',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: 12),
              Text(
                '${text.length} characters',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(width: 12),
              Text(
                '${controller.layout.lineCount} lines',
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('Undo'),
              ),
              TextButton.icon(
                onPressed: controller.canRedo ? controller.redo : null,
                icon: const Icon(Icons.redo, size: 16),
                label: const Text('Redo'),
              ),
            ],
          ),
        );
      },
    );
  }
}
