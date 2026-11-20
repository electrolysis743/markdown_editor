import 'package:flutter/material.dart';
import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';
import 'package:markdown/markdown.dart' as md;

/// A custom inline rule that styles `@mentions`.
class MentionInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const MentionInlineRule({
    this.color = const Color(0xFF00695C),
  });

  /// The color of mentions.
  final Color color;

  @override
  int get priority => 38;

  @override
  String get debugName => 'MentionInlineRule';

  static final RegExp _pattern = RegExp(r'@[A-Za-z0-9_]{2,}');

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(_pattern)) {
      if (scan.isMasked(match.start)) {
        continue;
      }
      final int before = match.start - 1;
      if (before >= scan.start && _isWord(scan.text[before])) {
        continue;
      }
      scan.add(
        match.start,
        match.end,
        MarkdownTokenType.custom,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          backgroundColor: color.withValues(alpha: 0.1),
        ),
      );
    }
  }

  static bool _isWord(String character) {
    final int code = character.codeUnitAt(0);
    return (code >= 0x30 && code <= 0x39) ||
        (code >= 0x41 && code <= 0x5A) ||
        (code >= 0x61 && code <= 0x7A) ||
        code == 0x5F;
  }
}

/// A custom inline rule that styles `#tags`.
class TagInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const TagInlineRule({this.color = const Color(0xFF6A1B9A)});

  /// The color of tags.
  final Color color;

  @override
  int get priority => 37;

  static final RegExp _pattern = RegExp(r'#[A-Za-z][A-Za-z0-9_-]*');

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(_pattern)) {
      if (scan.isMasked(match.start)) {
        continue;
      }
      scan.add(
        match.start,
        match.end,
        MarkdownTokenType.custom,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      );
    }
  }
}

/// A custom decoration that highlights `> [!NOTE]` callouts in the editor.
class CalloutLineDecorator extends MarkdownLineDecorator {
  /// Creates the decorator.
  const CalloutLineDecorator({this.color = const Color(0xFFEF6C00)});

  /// The accent color of the callout.
  final Color color;

  @override
  void paint(MarkdownDecorationContext context) {
    final Paint background = Paint()..color = color.withValues(alpha: 0.10);
    final Paint bar = Paint()..color = color;
    for (final MarkdownBlockBox box in context.blockBoxes) {
      if (box.block.kind != MarkdownBlockKind.quote) {
        continue;
      }
      final MarkdownLineInfo line = context.layout.lines[box.block.startLine];
      if (!line.text.contains('[!NOTE]')) {
        continue;
      }
      final Rect rect = box.rect;
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        background,
      );
      context.canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, 3, rect.height),
        bar,
      );
    }
  }
}

/// A custom command that inserts a callout block.
class InsertCalloutCommand extends MarkdownCommand {
  /// Creates the command.
  const InsertCalloutCommand();

  @override
  String get id => 'insert-callout';

  @override
  String get label => 'Insert callout';

  @override
  IconData? get icon => Icons.lightbulb_outline;

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.insertBlock(
      '> [!NOTE]\n> Everything here is rendered by a custom decorator.',
    );
  }
}

/// A custom command that appends a signature.
class InsertSignatureCommand extends MarkdownCommand {
  /// Creates the command.
  const InsertSignatureCommand();

  @override
  String get id => 'insert-signature';

  @override
  String get label => 'Insert signature';

  @override
  IconData? get icon => Icons.draw_outlined;

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.insertBlock(
      '---\n\n_Written with wysiwyg_markdown_editor_',
    );
  }
}

/// A Markdown inline syntax that produces `<mark>` elements in the preview.
class MarkSyntax extends md.InlineSyntax {
  /// Creates the syntax.
  MarkSyntax() : super(r'==(?=\S)([^=\n]*?\S)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match[1] ?? ''));
    return true;
  }
}

/// Renders `<mark>` elements produced by [MarkSyntax].
class MarkElementBuilder extends MarkdownElementBuilder {
  /// Creates the builder.
  MarkElementBuilder();

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        element.textContent,
        style: (parentStyle ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A code block widget with a language chip, used by the customization demo.
Widget buildDemoCodeBlock(
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
        Row(
          children: <Widget>[
            Icon(Icons.code, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              code.language ?? 'text',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SelectableText(
          code.code,
          style: const TextStyle(fontFamily: 'monospace', height: 1.45),
        ),
      ],
    ),
  );
}
