import 'package:flutter_test/flutter_test.dart';
import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';

void main() {
  const MarkdownLineAnalyzer analyzer = DefaultMarkdownLineAnalyzer();

  group('DefaultMarkdownLineAnalyzer', () {
    test('splits lines and records offsets', () {
      const String text = '# Title\n\nBody';
      final MarkdownDocumentLayout layout = analyzer.analyze(text);

      expect(layout.lineCount, 3);
      expect(layout.lines[0].kind, MarkdownLineKind.heading);
      expect(layout.lines[0].headingLevel, 1);
      expect(layout.lines[0].contentStart, 2);
      expect(layout.lines[1].kind, MarkdownLineKind.blank);
      expect(layout.lines[2].kind, MarkdownLineKind.paragraph);
      expect(
        text.substring(layout.lines[2].start, layout.lines[2].end),
        'Body',
      );
    });

    test('keeps a trailing empty line after a final newline', () {
      final MarkdownDocumentLayout layout = analyzer.analyze('one\n');
      expect(layout.lineCount, 2);
      expect(layout.lines[1].start, 4);
      expect(layout.lines[1].end, 4);
      expect(layout.lines[1].kind, MarkdownLineKind.blank);
    });

    test('parses nested block quotes', () {
      final MarkdownDocumentLayout layout = analyzer.analyze('> outer\n> > inner');
      expect(layout.lines[0].kind, MarkdownLineKind.blockquote);
      expect(layout.lines[0].quoteDepth, 1);
      expect(layout.lines[1].quoteDepth, 2);
      expect(layout.lines[1].contentStart, 4);
      expect(layout.blocks.single.kind, MarkdownBlockKind.quote);
      expect(layout.blocks.single.quoteDepth, 2);
    });

    test('parses bullet, ordered and task list items', () {
      final MarkdownDocumentLayout layout = analyzer.analyze(
        '- one\n1. two\n- [x] done\n- [ ] todo',
      );
      expect(layout.lines[0].kind, MarkdownLineKind.bulletList);
      expect(layout.lines[0].contentStart, 2);
      expect(layout.lines[1].kind, MarkdownLineKind.orderedList);
      expect(layout.lines[1].orderedNumber, 1);
      expect(layout.lines[2].kind, MarkdownLineKind.taskList);
      expect(layout.lines[2].isTask, isTrue);
      expect(layout.lines[2].taskChecked, isTrue);
      expect(layout.lines[3].taskChecked, isFalse);
      expect(layout.lines[3].contentStart, 6);
      expect(layout.blocks.single.kind, MarkdownBlockKind.list);
    });

    test('parses fenced code blocks with a language', () {
      const String text = 'before\n```dart\nvoid main() {}\n```\nafter';
      final MarkdownDocumentLayout layout = analyzer.analyze(text);
      expect(layout.lines[1].kind, MarkdownLineKind.fencedCode);
      expect(layout.lines[1].isFenceStart, isTrue);
      expect(layout.lines[1].fenceLanguage, 'dart');
      expect(layout.lines[2].kind, MarkdownLineKind.fencedCode);
      expect(layout.lines[3].isFenceEnd, isTrue);
      expect(layout.lines[4].kind, MarkdownLineKind.paragraph);

      final MarkdownBlock fence = layout.blocks
          .firstWhere((MarkdownBlock block) =>
              block.kind == MarkdownBlockKind.fencedCode);
      expect(fence.startLine, 1);
      expect(fence.endLine, 3);
      expect(fence.language, 'dart');
    });

    test('parses thematic breaks', () {
      final MarkdownDocumentLayout layout =
          analyzer.analyze('***\n- - -\n___');
      expect(layout.lines[0].kind, MarkdownLineKind.horizontalRule);
      expect(layout.lines[1].kind, MarkdownLineKind.horizontalRule);
      expect(layout.lines[2].kind, MarkdownLineKind.horizontalRule);
    });

    test('detects GitHub flavored markdown tables', () {
      final MarkdownDocumentLayout layout = analyzer.analyze(
        '| a | b |\n| --- | --- |\n| 1 | 2 |\n',
      );
      expect(layout.lines[0].kind, MarkdownLineKind.table);
      expect(layout.lines[1].kind, MarkdownLineKind.table);
      expect(layout.lines[1].isTableDelimiter, isTrue);
      expect(layout.lines[2].kind, MarkdownLineKind.table);
      expect(layout.blocks.single.kind, MarkdownBlockKind.table);
    });

    test('does not treat a bullet list as a paper table', () {
      final MarkdownDocumentLayout layout = analyzer.analyze('- a | b');
      expect(layout.lines[0].kind, MarkdownLineKind.bulletList);
    });

    test('resolves the line at an offset', () {
      const String text = 'a\nbb\nccc';
      final MarkdownDocumentLayout layout = analyzer.analyze(text);
      expect(layout.lineIndexAtOffset(0), 0);
      expect(layout.lineIndexAtOffset(2), 1);
      expect(layout.lineIndexAtOffset(5), 2);
      expect(layout.lineIndexAtOffset(999), 2);
      expect(layout.lineIndexAtOffset(-1), 0);
    });

    test('handles CRLF line endings without losing offsets', () {
      const String text = 'a\r\nb\r\n';
      final MarkdownDocumentLayout layout = analyzer.analyze(text);
      expect(layout.lineCount, 3);
      expect(layout.lines[0].end, 1);
      expect(layout.lines[1].start, 3);
      expect(layout.lines[1].end, 4);
      expect(layout.lines[1].text, 'b');
    });

    test('empty text yields a single empty line', () {
      final MarkdownDocumentLayout layout = analyzer.analyze('');
      expect(layout.lineCount, 1);
      expect(layout.lines.single.kind, MarkdownLineKind.blank);
      expect(layout.blocks, isEmpty);
    });
  });
}
