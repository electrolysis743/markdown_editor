import 'package:flutter/material.dart';

import '../controller/markdown_editor_controller.dart';
import '../model/markdown_block.dart';
import '../model/markdown_document_layout.dart';
import '../model/markdown_line_info.dart';
import '../theme/markdown_editor_theme.dart';

/// The state passed to a [MarkdownCommand] when it runs or reports its state.
class MarkdownCommandContext {
  /// Creates a command context.
  const MarkdownCommandContext({
    required this.controller,
    required this.theme,
  });

  /// The controller the command operates on.
  final MarkdownEditorController controller;

  /// The active theme, for commands that need colors or metrics.
  final MarkdownEditorTheme theme;

  /// The parsed document.
  MarkdownDocumentLayout get layout => controller.layout;

  /// The current selection.
  TextSelection get selection => controller.selection;

  /// The line that contains the caret.
  MarkdownLineInfo get line => controller.currentLine;

  /// The source text of the document.
  String get text => controller.text;

  /// The selected source text.
  String get selectedText => selection.isValid && !selection.isCollapsed
      ? text.substring(selection.start, selection.end)
      : '';
}

/// A single editor action, exposed through the toolbar and keyboard shortcuts.
///
/// Commands are stateless and application defined commands can be mixed with
/// the built-in ones:
///
/// ```dart
/// class InsertSignatureCommand extends MarkdownCommand {
///   const InsertSignatureCommand();
///
///   @override
///   String get id => 'insert-signature';
///
///   @override
///   String get label => 'Signature';
///
///   @override
///   IconData? get icon => Icons.draw_outlined;
///
///   @override
///   void execute(MarkdownCommandContext context) {
///     context.controller.insertBlock('--\nSent from my Flutter app');
///   }
/// }
/// ```
abstract class MarkdownCommand {
  /// Const constructor for stateless commands.
  const MarkdownCommand();

  /// A stable identifier, unique within a toolbar.
  String get id;

  /// A human readable label used by tooltips and menus.
  String get label;

  /// An optional icon used by the default toolbar.
  IconData? get icon => null;

  /// Whether the command is currently active, for example bold on a bold
  /// selection. The default toolbar renders active commands with an accent
  /// color.
  bool isActive(MarkdownCommandContext context) => false;

  /// Whether the command can run in the current state.
  bool isEnabled(MarkdownCommandContext context) => true;

  /// Runs the command.
  void execute(MarkdownCommandContext context);

  @override
  String toString() => '$runtimeType($id)';
}

// -----------------------------------------------------------------------------
// History
// -----------------------------------------------------------------------------

/// Undoes the last edit.
class UndoCommand extends MarkdownCommand {
  /// Creates the command.
  const UndoCommand();

  @override
  String get id => 'undo';

  @override
  String get label => 'Undo';

  @override
  IconData? get icon => Icons.undo;

  @override
  bool isEnabled(MarkdownCommandContext context) => context.controller.canUndo;

  @override
  void execute(MarkdownCommandContext context) => context.controller.undo();
}

/// Redoes the last undone edit.
class RedoCommand extends MarkdownCommand {
  /// Creates the command.
  const RedoCommand();

  @override
  String get id => 'redo';

  @override
  String get label => 'Redo';

  @override
  IconData? get icon => Icons.redo;

  @override
  bool isEnabled(MarkdownCommandContext context) => context.controller.canRedo;

  @override
  void execute(MarkdownCommandContext context) => context.controller.redo();
}

// -----------------------------------------------------------------------------
// Inline formatting
// -----------------------------------------------------------------------------

/// Toggles bold text.
class BoldCommand extends MarkdownCommand {
  /// Creates the command.
  const BoldCommand();

  @override
  String get id => 'bold';

  @override
  String get label => 'Bold';

  @override
  IconData? get icon => Icons.format_bold;

  @override
  bool isActive(MarkdownCommandContext context) =>
      MarkdownCommandSupport.isWrapped(context, '**', '**');

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.toggleInlineWrap(
      marker: '**',
      placeholder: 'bold text',
    );
  }
}

/// Toggles italic text.
class ItalicCommand extends MarkdownCommand {
  /// Creates the command.
  const ItalicCommand();

  @override
  String get id => 'italic';

  @override
  String get label => 'Italic';

  @override
  IconData? get icon => Icons.format_italic;

  @override
  bool isActive(MarkdownCommandContext context) =>
      MarkdownCommandSupport.isWrapped(context, '*', '*');

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.toggleInlineWrap(
      marker: '*',
      placeholder: 'italic text',
    );
  }
}

/// Toggles strikethrough text.
class StrikethroughCommand extends MarkdownCommand {
  /// Creates the command.
  const StrikethroughCommand();

  @override
  String get id => 'strikethrough';

  @override
  String get label => 'Strikethrough';

  @override
  IconData? get icon => Icons.format_strikethrough;

  @override
  bool isActive(MarkdownCommandContext context) =>
      MarkdownCommandSupport.isWrapped(context, '~~', '~~');

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.toggleInlineWrap(
      marker: '~~',
      placeholder: 'struck text',
    );
  }
}

/// Toggles inline code.
class InlineCodeCommand extends MarkdownCommand {
  /// Creates the command.
  const InlineCodeCommand();

  @override
  String get id => 'inline-code';

  @override
  String get label => 'Inline code';

  @override
  IconData? get icon => Icons.code;

  @override
  bool isActive(MarkdownCommandContext context) =>
      MarkdownCommandSupport.isWrapped(context, '`', '`');

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.toggleInlineWrap(
      marker: '`',
      placeholder: 'code',
    );
  }
}

/// Toggles highlighted text.
class HighlightCommand extends MarkdownCommand {
  /// Creates the command.
  const HighlightCommand();

  @override
  String get id => 'highlight';

  @override
  String get label => 'Highlight';

  @override
  IconData? get icon => Icons.highlight_outlined;

  @override
  bool isActive(MarkdownCommandContext context) =>
      MarkdownCommandSupport.isWrapped(context, '==', '==');

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.toggleInlineWrap(
      marker: '==',
      placeholder: 'highlighted text',
    );
  }
}

/// Inserts or edits a link.
class LinkCommand extends MarkdownCommand {
  /// Creates the command.
  const LinkCommand();

  @override
  String get id => 'link';

  @override
  String get label => 'Link';

  @override
  IconData? get icon => Icons.link;

  @override
  bool isActive(MarkdownCommandContext context) =>
      MarkdownCommandSupport.containsLink(context);

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.toggleInlineWrap(
      marker: '[',
      closingMarker: '](https://)',
      placeholder: 'link text',
    );
  }
}

/// Inserts an image.
class ImageCommand extends MarkdownCommand {
  /// Creates the command.
  const ImageCommand();

  @override
  String get id => 'image';

  @override
  String get label => 'Image';

  @override
  IconData? get icon => Icons.image_outlined;

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.toggleInlineWrap(
      marker: '![',
      closingMarker: '](https://)',
      placeholder: 'alt text',
    );
  }
}

// -----------------------------------------------------------------------------
// Block formatting
// -----------------------------------------------------------------------------

/// Applies a heading level (1-6) to the selected lines.
class HeadingCommand extends MarkdownCommand {
  /// Creates a heading command for [level].
  const HeadingCommand(this.level);

  /// The heading level, 1 through 6.
  final int level;

  @override
  String get id => 'heading$level';

  @override
  String get label => 'Heading $level';

  @override
  IconData? get icon => Icons.title;

  @override
  bool isActive(MarkdownCommandContext context) =>
      context.line.kind == MarkdownLineKind.heading &&
      context.line.headingLevel == level;

  @override
  void execute(MarkdownCommandContext context) {
    final MarkdownEditorController controller = context.controller;
    final bool alreadyActive = isActive(context);
    controller.setHeadingLevel(alreadyActive ? 0 : level);
  }
}

/// Removes the heading style from the selected lines.
class ParagraphCommand extends MarkdownCommand {
  /// Creates the command.
  const ParagraphCommand();

  @override
  String get id => 'paragraph';

  @override
  String get label => 'Paragraph';

  @override
  IconData? get icon => Icons.notes;

  @override
  bool isActive(MarkdownCommandContext context) =>
      context.line.kind == MarkdownLineKind.paragraph ||
      context.line.kind == MarkdownLineKind.blank;

  @override
  void execute(MarkdownCommandContext context) {
    context.controller.setHeadingLevel(0);
  }
}

/// Toggles a block quote.
class BlockquoteCommand extends MarkdownCommand {
  /// Creates the command.
  const BlockquoteCommand();

  @override
  String get id => 'blockquote';

  @override
  String get label => 'Quote';

  @override
  IconData? get icon => Icons.format_quote;

  @override
  bool isActive(MarkdownCommandContext context) =>
      context.line.quoteDepth > 0;

  @override
  void execute(MarkdownCommandContext context) =>
      context.controller.toggleBlockquote();
}

/// Toggles a bullet list.
class BulletListCommand extends MarkdownCommand {
  /// Creates the command.
  const BulletListCommand();

  @override
  String get id => 'bullet-list';

  @override
  String get label => 'Bulleted list';

  @override
  IconData? get icon => Icons.format_list_bulleted;

  @override
  bool isActive(MarkdownCommandContext context) =>
      context.line.kind == MarkdownLineKind.bulletList;

  @override
  void execute(MarkdownCommandContext context) =>
      context.controller.toggleBulletList();
}

/// Toggles an ordered list.
class OrderedListCommand extends MarkdownCommand {
  /// Creates the command.
  const OrderedListCommand();

  @override
  String get id => 'ordered-list';

  @override
  String get label => 'Numbered list';

  @override
  IconData? get icon => Icons.format_list_numbered;

  @override
  bool isActive(MarkdownCommandContext context) =>
      context.line.kind == MarkdownLineKind.orderedList;

  @override
  void execute(MarkdownCommandContext context) =>
      context.controller.toggleOrderedList();
}

/// Toggles a task list.
class TaskListCommand extends MarkdownCommand {
  /// Creates the command.
  const TaskListCommand();

  @override
  String get id => 'task-list';

  @override
  String get label => 'Task list';

  @override
  IconData? get icon => Icons.checklist;

  @override
  bool isActive(MarkdownCommandContext context) =>
      context.line.kind == MarkdownLineKind.taskList;

  @override
  void execute(MarkdownCommandContext context) =>
      context.controller.toggleTaskList();
}

/// Flips the checkbox of the current task line.
class ToggleTaskCheckboxCommand extends MarkdownCommand {
  /// Creates the command.
  const ToggleTaskCheckboxCommand();

  @override
  String get id => 'toggle-task';

  @override
  String get label => 'Toggle task';

  @override
  IconData? get icon => Icons.check_box_outlined;

  @override
  bool isEnabled(MarkdownCommandContext context) =>
      context.line.isTask;

  @override
  void execute(MarkdownCommandContext context) =>
      context.controller.toggleTaskState();
}

/// Inserts or removes a fenced code block.
class CodeBlockCommand extends MarkdownCommand {
  /// Creates the command.
  const CodeBlockCommand({this.language = ''});

  /// The info string placed after the opening fence.
  final String language;

  @override
  String get id => 'code-block';

  @override
  String get label => 'Code block';

  @override
  IconData? get icon => Icons.data_object;

  @override
  bool isActive(MarkdownCommandContext context) {
    final MarkdownBlock? block =
        context.layout.blockForLine(context.line.index);
    return block?.kind == MarkdownBlockKind.fencedCode;
  }

  @override
  void execute(MarkdownCommandContext context) {
    final MarkdownEditorController controller = context.controller;
    final MarkdownBlock? block =
        context.layout.blockForLine(controller.currentLine.index);
    if (block != null && block.kind == MarkdownBlockKind.fencedCode) {
      controller.removeFence(block);
      return;
    }
    final String selected = context.selectedText;
    final String fence = '```$language';
    if (selected.isEmpty) {
      controller.insertBlock(
        '$fence\n\n```',
        caretOffset: fence.length + 1,
      );
      return;
    }
    controller.insertBlock(
      '$fence\n$selected\n```',
      caretOffset: fence.length + 1 + selected.length + 1,
    );
  }
}

/// Inserts a thematic break.
class HorizontalRuleCommand extends MarkdownCommand {
  /// Creates the command.
  const HorizontalRuleCommand();

  @override
  String get id => 'horizontal-rule';

  @override
  String get label => 'Divider';

  @override
  IconData? get icon => Icons.horizontal_rule;

  @override
  void execute(MarkdownCommandContext context) =>
      context.controller.insertBlock('---');
}

/// Inserts a table skeleton.
class TableCommand extends MarkdownCommand {
  /// Creates a table command.
  const TableCommand({this.columns = 2, this.rows = 2});

  /// Number of columns to create.
  final int columns;

  /// Number of body rows to create.
  final int rows;

  @override
  String get id => 'table';

  @override
  String get label => 'Table';

  @override
  IconData? get icon => Icons.table_chart_outlined;

  @override
  void execute(MarkdownCommandContext context) {
    final List<String> header = <String>[
      for (int i = 0; i < columns; i++) ' Column ${i + 1} ',
    ];
    final List<String> separator = <String>[
      for (int i = 0; i < columns; i++) ' --- ',
    ];
    final List<String> body = <String>[
      for (int i = 0; i < columns; i++) ' Cell ',
    ];
    final StringBuffer buffer = StringBuffer()
      ..writeln('|${header.join('|')}|')
      ..writeln('|${separator.join('|')}|');
    for (int i = 0; i < rows; i++) {
      buffer.writeln('|${body.join('|')}|');
    }
    context.controller.insertBlock(buffer.toString().trimRight());
  }
}

/// Indents the selected lines by one list level.
class IndentCommand extends MarkdownCommand {
  /// Creates the command.
  const IndentCommand();

  @override
  String get id => 'indent';

  @override
  String get label => 'Indent';

  @override
  IconData? get icon => Icons.format_indent_increase;

  @override
  void execute(MarkdownCommandContext context) =>
      context.controller.indentLines(spaces: 2);
}

/// Outdents the selected lines by one list level.
class OutdentCommand extends MarkdownCommand {
  /// Creates the command.
  const OutdentCommand();

  @override
  String get id => 'outdent';

  @override
  String get label => 'Outdent';

  @override
  IconData? get icon => Icons.format_indent_decrease;

  @override
  void execute(MarkdownCommandContext context) =>
      context.controller.outdentLines(spaces: 2);
}

/// Helpers shared by the built-in commands.
class MarkdownCommandSupport {
  const MarkdownCommandSupport._();

  /// Whether the selected text is wrapped by [open] and [close], or directly
  /// surrounded by them.
  static bool isWrapped(
    MarkdownCommandContext context,
    String open,
    String close,
  ) {
    final MarkdownEditorController controller = context.controller;
    final TextSelection selection = controller.selection;
    if (!selection.isValid) {
      return false;
    }
    final String text = controller.text;
    if (selection.isCollapsed) {
      final int offset = selection.start;
      if (offset < open.length || offset + close.length > text.length) {
        return false;
      }
      return text.substring(offset - open.length, offset) == open &&
          text.substring(offset, offset + close.length) == close;
    }
    final String selected = text.substring(selection.start, selection.end);
    if (selected.length >= open.length + close.length &&
        selected.startsWith(open) &&
        selected.endsWith(close)) {
      return true;
    }
    final int start = selection.start;
    final int end = selection.end;
    return start >= open.length &&
        end + close.length <= text.length &&
        text.substring(start - open.length, start) == open &&
        text.substring(end, end + close.length) == close;
  }

  /// Whether the current line or selection contains a link.
  static bool containsLink(MarkdownCommandContext context) {
    final String text = context.controller.text;
    final TextSelection selection = context.controller.selection;
    if (!selection.isValid) {
      return false;
    }
    int clamp(int value) {
      if (value < 0) {
        return 0;
      }
      if (value > text.length) {
        return text.length;
      }
      return value;
    }

    final int start =
        clamp(selection.isCollapsed ? selection.start - 1 : selection.start);
    final int end = clamp(selection.isCollapsed ? selection.start : selection.end);
    if (start >= end) {
      return false;
    }
    return text.substring(start, end).contains('](');
  }
}
