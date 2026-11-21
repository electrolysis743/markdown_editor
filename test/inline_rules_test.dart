// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';

TextSpan buildSpan(
  String text, {
  MarkdownEditorTheme theme = const MarkdownEditorTheme(),
  List<MarkdownInlineRule> extraRules = const <MarkdownInlineRule>[],
  MarkdownLineAnalyzer analyzer = const DefaultMarkdownLineAnalyzer(),
  bool showSyntax = true,
  TextRange? activeLineRange,
}) {
  final MarkdownDocumentLayout layout = analyzer.analyze(text);
  final MarkdownEditorExtensions extensions =
      MarkdownEditorExtensions(inlineRules: extraRules);
  return extensions.engine.build(
    MarkdownSpanBuildContext(
      text: text,
      layout: layout,
      theme: theme,
      baseStyle: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
      rules: extensions.activeInlineRules,
      showSyntax: showSyntax,
      activeLineRange: activeLineRange,
    ),
  );
}

/// Whether the character at [offset] is collapsed to zero width.
bool collapsedAt(TextSpan root, int offset) => styleAt(root, offset)?.fontSize == 0;

/// Whether the character at [offset] is transparent but keeps its width.
bool hiddenAt(TextSpan root, int offset) =>
    styleAt(root, offset)?.color?.a == 0 && styleAt(root, offset)?.fontSize != 0;

TextStyle? styleAt(TextSpan root, int offset) {
  int cursor = 0;
  TextStyle? result;
  root.visitChildren((InlineSpan span) {
    if (span is! TextSpan) {
      return true;
    }
    final String text = span.text ?? '';
    if (offset >= cursor && offset < cursor + text.length) {
      result = span.style;
      return false;
    }
    cursor += text.length;
    return true;
  });
  return result;
}

void main() {
  group('DefaultMarkdownSpanEngine', () {
    test('keeps the span text identical to the source', () {
      const String text = '# Title\n\n**bold** and *italic* `code`\n';
      final TextSpan span = buildSpan(text);
      expect(span.toPlainText(), text);
    });

    test('styles strong emphasis', () {
      const String text = 'a **bold** b';
      final TextSpan span = buildSpan(text);
      expect(styleAt(span, 4)?.fontWeight, FontWeight.w700);
      expect(styleAt(span, 0)?.fontWeight, isNot(FontWeight.w700));
    });

    test('styles emphasis', () {
      const String text = 'a *italic* b';
      final TextSpan span = buildSpan(text);
      expect(styleAt(span, 3)?.fontStyle, FontStyle.italic);
    });

    test('styles inline code', () {
      const String text = 'a `code` b';
      final TextSpan span = buildSpan(text);
      expect(styleAt(span, 4)?.fontFamily, isNotNull);
    });

    test('styles strikethrough and highlight', () {
      const String text = '~~gone~~ ==marked==';
      final TextSpan span = buildSpan(text);
      expect(styleAt(span, 3)?.decoration, TextDecoration.lineThrough);
      expect(styleAt(span, 13)?.backgroundColor, isNotNull);
    });

    test('styles link text and destination differently', () {
      const String text = 'see [docs](https://example.com) now';
      final TextSpan span = buildSpan(text);
      final TextStyle? label = styleAt(span, 6);
      final TextStyle? url = styleAt(span, 15);
      expect(label, isNotNull);
      expect(url, isNotNull);
      expect(label!.color, isNot(url!.color));
    });

    test('nests emphasis inside strong', () {
      const String text = '**bold _italic_**';
      final TextSpan span = buildSpan(text);
      final TextStyle? style = styleAt(span, 10);
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.fontStyle, FontStyle.italic);
    });

    test('does not style markers inside inline code', () {
      const String text = '`**not bold**`';
      final TextSpan span = buildSpan(text);
      expect(styleAt(span, 4)?.fontWeight, isNot(FontWeight.w700));
    });

    test('dims markers according to the marker visibility', () {
      const String text = '**bold**';
      final TextSpan dimmed = buildSpan(text);
      final Color dimmedColor = styleAt(dimmed, 0)!.color!;
      expect(dimmedColor.a, lessThan(1));

      final TextSpan hidden = buildSpan(
        text,
        theme: const MarkdownEditorTheme(
          markerVisibility: MarkdownMarkerVisibility.hidden,
        ),
      );
      expect(styleAt(hidden, 0)!.color!.a, 0);
    });

    group('hiddenExceptActiveLine', () {
      const MarkdownEditorTheme theme = MarkdownEditorTheme(
        markerVisibility: MarkdownMarkerVisibility.hiddenExceptActiveLine,
      );

      test('collapses markers outside the active line only', () {
        const String text = '# Title\n**bold**';
        final int secondLine = text.indexOf('**');
        final TextSpan span = buildSpan(
          text,
          theme: theme,
          activeLineRange: TextRange(start: secondLine, end: text.length),
        );

        expect(span.toPlainText(), text);
        // `#` of the heading collapses so the heading starts at the margin.
        expect(collapsedAt(span, 0), isTrue);
        // The markers of the line being edited stay visible and faded.
        expect(collapsedAt(span, secondLine), isFalse);
        expect(styleAt(span, secondLine)!.color!.a, lessThan(1));
        expect(collapsedAt(span, secondLine + 2), isFalse);
        expect(styleAt(span, secondLine + 2)?.fontWeight, FontWeight.w700);
      });

      test('collapses every marker when no line is active', () {
        const String text = 'a `code` b';
        final TextSpan span = buildSpan(text, theme: theme);

        expect(span.toPlainText(), text);
        expect(collapsedAt(span, 2), isTrue);
        expect(collapsedAt(span, 7), isTrue);
        expect(styleAt(span, 3)?.fontFamily, isNotNull);
      });

      test('keeps styling content on collapsed lines', () {
        const String text = '~~gone~~';
        final TextSpan span = buildSpan(text, theme: theme);

        expect(collapsedAt(span, 0), isTrue);
        expect(
          styleAt(span, 3)?.decoration,
          TextDecoration.lineThrough,
        );
      });

      test('hides block prefixes but keeps their width', () {
        const String text = '-   item\n- [x] done\n> quoted';
        final TextSpan span = buildSpan(text, theme: theme);

        expect(span.toPlainText(), text);
        // The bullet is invisible but keeps one character of width, so the text
        // sits exactly where the rendered bullet and its gap put it.
        expect(hiddenAt(span, 0), isTrue);
        expect(collapsedAt(span, 0), isFalse);
        expect(hiddenAt(span, 1), isTrue);

        // The checkbox is hidden too: the decoration layer draws it.
        final int checkbox = text.indexOf('[x]');
        expect(hiddenAt(span, text.indexOf('- [x]')), isTrue);
        expect(hiddenAt(span, checkbox), isTrue);

        // Same for the block quote marker, so the painted bar stays clear.
        expect(hiddenAt(span, text.indexOf('> quoted')), isTrue);
      });

      test('collapses link and image destinations but not autolinks', () {
        const String text =
            'see [docs](https://x.dev) ![logo](https://y.dev/i.png) <https://z.dev>';
        final TextSpan span = buildSpan(text, theme: theme);

        expect(span.toPlainText(), text);
        expect(collapsedAt(span, text.indexOf('docs')), isFalse);
        expect(collapsedAt(span, text.indexOf('https://x.dev')), isTrue);
        expect(collapsedAt(span, text.indexOf('logo')), isFalse);
        expect(collapsedAt(span, text.indexOf('https://y.dev')), isTrue);
        // An autolink shows its URL, so the URL keeps its width.
        expect(collapsedAt(span, text.indexOf('https://z.dev')), isFalse);
      });

      test('hides block quote markers without shifting the text', () {
        const String text = '> quoted';
        final TextSpan span = buildSpan(text, theme: theme);

        expect(hiddenAt(span, 0), isTrue);
        expect(hiddenAt(span, 1), isTrue);
        expect(styleAt(span, 2)!.color!.a, greaterThan(0.5));
      });

      test('hides the marker of a heading inside a block quote', () {
        const String text = '> ## Quoted heading';
        final TextSpan span = buildSpan(text, theme: theme);
        final int content = text.indexOf('Quoted');

        // The quote indent stays so the heading clears the painted bar.
        expect(hiddenAt(span, 0), isTrue);
        expect(collapsedAt(span, 0), isFalse);
        // The heading text keeps its size and stays visible.
        expect(styleAt(span, content)?.fontSize, greaterThan(16));
        expect(hiddenAt(span, content), isFalse);
      });

      test('collapses fences, table delimiters and rules', () {
        const String text = '```dart\ncode\n```\n\n| a | b |\n| --- | --- |\n\n---';
        final TextSpan span = buildSpan(text, theme: theme);

        expect(span.toPlainText(), text);
        // The opening fence, the closing fence and the delimiter row collapse.
        expect(collapsedAt(span, 0), isTrue);
        expect(collapsedAt(span, text.indexOf('```\n\n')), isTrue);
        expect(collapsedAt(span, text.indexOf('| ---')), isTrue);
        // Code content and table cells keep their styling.
        expect(collapsedAt(span, text.indexOf('code')), isFalse);
        expect(collapsedAt(span, text.indexOf('| a |')), isFalse);
      });
    });

    test('applies heading sizes per level', () {      const String text = '# One\n## Two\n### Three';
      final TextSpan span = buildSpan(text);
      final double? h1 = styleAt(span, 2)?.fontSize;
      final double? h2 = styleAt(span, 8)?.fontSize;
      final double? h3 = styleAt(span, 14)?.fontSize;
      expect(h1, greaterThan(h2!));
      expect(h2, greaterThan(h3!));
    });

    test('marks task checkboxes', () {
      const String text = '- [x] done';
      final TextSpan span = buildSpan(text);
      expect(span.toPlainText(), text);
      expect(styleAt(span, 3)?.fontWeight, isNot(FontWeight.w700));
    });

    test('renders fenced code with a monospace style', () {
      const String text = '```\ncode\n```';
      final TextSpan span = buildSpan(text);
      expect(styleAt(span, 5)?.fontFamily, isNotNull);
    });

    test('renders plain text when syntax is disabled', () {
      final TextSpan span = buildSpan('**bold**', showSyntax: false);
      expect(styleAt(span, 0)?.fontWeight, isNot(FontWeight.w700));
      expect(span.toPlainText(), '**bold**');
    });

    test('supports custom inline rules', () {
      const String text = 'ping @alice now';
      final TextSpan span = buildSpan(
        text,
        extraRules: const <MarkdownInlineRule>[_AtRule()],
      );
      expect(styleAt(span, 6)?.color, const Color(0xFFFF0000));
      expect(styleAt(span, 0)?.color, const Color(0xFF000000));
    });

    test('custom rules can mask lower priority rules', () {
      const String text = '%%not **bold**%%';
      final TextSpan span = buildSpan(
        text,
        extraRules: const <MarkdownInlineRule>[_PercentMaskRule()],
      );
      expect(styleAt(span, 9)?.fontWeight, isNot(FontWeight.w700));
    });

    test('handles CRLF line endings', () {
      const String text = 'a\r\nb';
      final TextSpan span = buildSpan(text);
      expect(span.toPlainText(), text);
    });
  });
}

class _AtRule extends MarkdownInlineRule {
  const _AtRule();

  @override
  int get priority => 200;

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(RegExp(r'@\w+'))) {
      scan.add(
        match.start,
        match.end,
        MarkdownTokenType.custom,
        style: const TextStyle(color: Color(0xFFFF0000)),
      );
    }
  }
}

class _PercentMaskRule extends MarkdownInlineRule {
  const _PercentMaskRule();

  @override
  int get priority => 300;

  @override
  bool get masksLowerPriority => true;

  @override
  void scan(MarkdownInlineScan scan) {
    final RegExp pattern = RegExp(r'%%[^%]*%%');
    for (final RegExpMatch match in scan.matches(pattern)) {
      scan.mask(match.start, match.end);
    }
  }
}
