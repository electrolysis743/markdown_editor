import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_editor/markdown_editor.dart';

void main() {
  late MarkdownEditorController controller;

  setUp(() {
    controller = MarkdownEditorController(text: 'hello world');
  });

  tearDown(() {
    controller.dispose();
  });

  group('history', () {
    test('undoes and redoes edits', () {
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      const BoldCommand().execute(
        MarkdownCommandContext(
          controller: controller,
          theme: const MarkdownEditorTheme(),
        ),
      );
      expect(controller.text, '**hello** world');
      expect(controller.canUndo, isTrue);

      expect(controller.undo(), isTrue);
      expect(controller.text, 'hello world');

      expect(controller.redo(), isTrue);
      expect(controller.text, '**hello** world');
    });

    test('coalesces continuous single character edits', () {
      controller.clearHistory();
      for (final String character in <String>['a', 'b', 'c']) {
        controller.value = TextEditingValue(
          text: '${controller.text}$character',
          selection: TextSelection.collapsed(offset: controller.text.length + 1),
        );
      }
      expect(controller.text, 'hello worldabc');
      controller.undo();
      expect(controller.text.length, lessThan('hello worldabc'.length));
    });

    test('does not record undo steps while restoring', () {
      controller.clearHistory();
      controller.text = 'one';
      controller.text = 'two';
      expect(controller.history.undoCount, 2);

      controller.undo();
      expect(controller.text, 'one');
      expect(controller.history.undoCount, 1);

      controller.undo();
      expect(controller.text, 'hello world');
      expect(controller.history.undoCount, 0);

      controller.redo();
      controller.redo();
      expect(controller.text, 'two');
    });
  });

  group('inline operations', () {
    test('wraps and unwraps a selection', () {
      controller.text = 'hello world';
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);
      controller.toggleInlineWrap(marker: '**');
      expect(controller.text, '**hello** world');

      controller.selection =
          const TextSelection(baseOffset: 2, extentOffset: 7);
      controller.toggleInlineWrap(marker: '**');
      expect(controller.text, 'hello world');
    });

    test('unwraps when the markers surround the selection', () {
      controller.text = 'x **bold** y';
      controller.selection =
          const TextSelection(baseOffset: 4, extentOffset: 8);
      controller.toggleInlineWrap(marker: '**');
      expect(controller.text, 'x bold y');
    });

    test('wraps the word under a collapsed caret', () {
      controller.text = 'hello world';
      controller.selection = const TextSelection.collapsed(offset: 2);
      controller.toggleInlineWrap(marker: '*');
      expect(controller.text, '*hello* world');
    });

    test('inserts a placeholder when there is no word', () {
      controller.text = '';
      controller.selection = const TextSelection.collapsed(offset: 0);
      controller.toggleInlineWrap(marker: '**', placeholder: 'bold text');
      expect(controller.text, '**bold text**');
      expect(controller.selection.start, 2);
      expect(controller.selection.end, 11);
    });
  });

  group('block operations', () {
    test('applies and removes headings', () {
      controller.text = 'title';
      controller.selection = const TextSelection.collapsed(offset: 0);
      controller.setHeadingLevel(2);
      expect(controller.text, '## title');

      controller.setHeadingLevel(0);
      expect(controller.text, 'title');

      controller.setHeadingLevel(1);
      expect(controller.text, '# title');

      controller.setHeadingLevel(3);
      expect(controller.text, '### title');
    });

    test('toggles bullet lists on every selected line', () {
      controller.text = 'one\ntwo';
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 7);
      controller.toggleBulletList();
      expect(controller.text, '- one\n- two');

      controller.toggleBulletList();
      expect(controller.text, 'one\ntwo');
    });

    test('orders selected lines', () {
      controller.text = 'one\ntwo';
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 7);
      controller.toggleOrderedList();
      expect(controller.text, '1. one\n2. two');
    });

    test('toggles task list items and their state', () {
      controller.text = 'one';
      controller.selection = const TextSelection.collapsed(offset: 0);
      controller.toggleTaskList();
      expect(controller.text, '- [ ] one');

      controller.toggleTaskState();
      expect(controller.text, '- [x] one');

      controller.toggleTaskState();
      expect(controller.text, '- [ ] one');
    });

    test('toggles block quotes', () {
      controller.text = 'quoted';
      controller.selection = const TextSelection.collapsed(offset: 0);
      controller.toggleBlockquote();
      expect(controller.text, '> quoted');

      controller.toggleBlockquote();
      expect(controller.text, 'quoted');
    });

    test('indents and outdents', () {
      controller.text = 'item';
      controller.selection = const TextSelection.collapsed(offset: 0);
      controller.indentLines();
      expect(controller.text, '  item');

      controller.outdentLines();
      expect(controller.text, 'item');
    });

    test('inserts blocks around the caret line', () {
      controller.text = 'abc';
      controller.selection = const TextSelection.collapsed(offset: 1);
      controller.insertBlock('---');
      expect(controller.text, 'a\n---\nbc');
    });

    test('removes code fences through the command', () {
      controller.text = '```\ncode\n```';
      controller.selection = const TextSelection.collapsed(offset: 5);
      const CodeBlockCommand().execute(
        MarkdownCommandContext(
          controller: controller,
          theme: const MarkdownEditorTheme(),
        ),
      );
      expect(controller.text, 'code');
    });

    test('inserts code fences around a selection', () {
      controller.text = 'code';
      controller.selection =
          const TextSelection(baseOffset: 0, extentOffset: 4);
      const CodeBlockCommand().execute(
        MarkdownCommandContext(
          controller: controller,
          theme: const MarkdownEditorTheme(),
        ),
      );
      expect(controller.text, '```\ncode\n```');
    });
  });

  group('queries', () {
    test('reports the current line', () {
      controller.text = '# Title\n\nbody';
      controller.selection = const TextSelection.collapsed(offset: 8);
      expect(controller.currentLine.kind, MarkdownLineKind.blank);
      expect(controller.layout.lineCount, 3);
    });

    test('finds the word at an offset', () {
      controller.text = 'hello, world';
      final TextRange? range = controller.wordRangeAt(2);
      expect(range, isNotNull);
      expect(range!.start, 0);
      expect(range.end, 5);
      expect(controller.wordRangeAt(6), isNull);
    });
  });
}
