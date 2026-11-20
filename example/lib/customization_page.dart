import 'package:flutter/material.dart';
import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';
import 'package:markdown/markdown.dart' as md;

import 'customizations.dart';

/// Demonstrates replacing every part of the editor.
class CustomizationPage extends StatefulWidget {
  /// Creates the customization demo.
  const CustomizationPage({super.key});

  @override
  State<CustomizationPage> createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> {
  final MarkdownEditorController _controller = MarkdownEditorController(
    text: '''
# Customization

This page replaces parts of the editor without forking the package.

Mention **@flutter** and tag this note **#extensible**.

> [!NOTE]
> Callouts are painted by a custom `MarkdownLineDecorator` that reads the
> document layout. The `> [!NOTE]` prefix stays part of the Markdown source.

```dart
MarkdownEditor(
  extensions: MarkdownEditorExtensions(
    inlineRules: [MentionInlineRule(), TagInlineRule()],
    lineDecorators: [CalloutLineDecorator()],
  ),
);
```

- [x] Custom inline rules
- [x] Custom decorations
- [ ] Your idea here

The preview renders ==highlighted text== through a custom
`MarkdownElementBuilder` and a custom `md.InlineSyntax`.
''',
  );

  MarkdownEditorMode _mode = MarkdownEditorMode.split;
  bool _debugDecorations = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData material = Theme.of(context);
    final bool wide = MediaQuery.sizeOf(context).width >= 900;
    final MarkdownEditorTheme theme = MarkdownEditorTheme(
      heading1: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: material.colorScheme.primary,
      ),
      heading2: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: material.colorScheme.primary.withValues(alpha: 0.85),
      ),
      quoteBarColor: const Color(0xFFEF6C00),
      quoteColor: const Color(0xFFEF6C00).withValues(alpha: 0.08),
      codeBlockColor: material.colorScheme.primary.withValues(alpha: 0.07),
      selectionColor: material.colorScheme.primary.withValues(alpha: 0.22),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SegmentedButton<MarkdownEditorMode>(
                segments: const <ButtonSegment<MarkdownEditorMode>>[
                  ButtonSegment<MarkdownEditorMode>(
                    value: MarkdownEditorMode.wysiwyg,
                    label: Text('WYSIWYG'),
                  ),
                  ButtonSegment<MarkdownEditorMode>(
                    value: MarkdownEditorMode.split,
                    label: Text('Split'),
                  ),
                  ButtonSegment<MarkdownEditorMode>(
                    value: MarkdownEditorMode.preview,
                    label: Text('Preview'),
                  ),
                ],
                selected: <MarkdownEditorMode>{_mode},
                onSelectionChanged: (Set<MarkdownEditorMode> selection) {
                  setState(() => _mode = selection.first);
                },
              ),
              FilterChip(
                label: const Text('Debug decoration boxes'),
                selected: _debugDecorations,
                onSelected: (bool value) =>
                    setState(() => _debugDecorations = value),
              ),
              OutlinedButton.icon(
                onPressed: () => _controller.insertBlock(
                  '> [!NOTE]\n> Inserted from the toolbar.',
                ),
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Callout'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: MarkdownEditor(
            controller: _controller,
            mode: _mode,
            theme: theme,
            splitDirection: wide ? Axis.horizontal : Axis.vertical,
            toolbar: MarkdownToolbarConfig(
              wrap: true,
              items: <MarkdownToolbarItem>[
                ...defaultMarkdownToolbarItems(),
                const MarkdownToolbarItem.separator(),
                const MarkdownToolbarItem(
                  command: InsertCalloutCommand(),
                  icon: Icons.lightbulb_outline,
                ),
                const MarkdownToolbarItem(
                  command: InsertSignatureCommand(),
                  icon: Icons.draw_outlined,
                ),
                MarkdownToolbarItem(
                  id: 'word-count',
                  builder: (BuildContext context, MarkdownToolbarItemState state) {
                    final int words = state.context.controller.text
                        .split(RegExp(r'\s+'))
                        .where((String word) => word.isNotEmpty)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$words words',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    );
                  },
                ),
              ],
            ),
            extensions: MarkdownEditorExtensions(
              inlineRules: const <MarkdownInlineRule>[
                MentionInlineRule(),
                TagInlineRule(),
              ],
              lineDecorators: <MarkdownLineDecorator>[
                const CalloutLineDecorator(),
                const ListGuideDecorator(),
                if (_debugDecorations) const DebugDecorationDecorator(),
              ],
            ),
            builders: MarkdownEditorBuilders(
              codeBlockBuilder: buildDemoCodeBlock,
              elementBuilders: <String, MarkdownElementBuilder>{
                'mark': MarkElementBuilder(),
              },
              inlineSyntaxes: <md.InlineSyntax>[MarkSyntax()],
              emptyStateBuilder: (BuildContext context) => Center(
                child: Text(
                  'Nothing here yet — start writing!',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              editingSurfaceBuilder: (
                BuildContext context,
                MarkdownEditingSurfaceContext surface,
              ) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: MarkdownEditingSurface(
                      controller: surface.controller,
                      theme: surface.theme,
                      readOnly: surface.readOnly,
                      hintText: 'Write some Markdown…',
                    ),
                  ),
                );
              },
              statusBarBuilder: (BuildContext context) => AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  final MarkdownLineInfo line = _controller.currentLine;
                  return Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      '${line.kind.name} · line ${line.index + 1} of '
                      '${_controller.layout.lineCount}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
