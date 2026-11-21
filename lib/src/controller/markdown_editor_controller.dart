import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../analysis/default_line_analyzer.dart';
import '../analysis/markdown_span_engine.dart';
import '../editor/markdown_editor_scope.dart';
import '../editor/markdown_editor_extensions.dart';
import '../model/markdown_block.dart';
import '../model/markdown_document_layout.dart';
import '../model/markdown_line_info.dart';
import '../theme/markdown_editor_theme.dart';
import '../theme/marker_visibility.dart';
import 'markdown_history.dart';

/// A [TextEditingController] that renders Markdown while editing it.
///
/// The controller owns three concerns:
///
/// * it keeps the plain Markdown source, exactly as typed, so the widget can be
///   dropped into any text based workflow;
/// * it parses the source into a [MarkdownDocumentLayout] and turns it into a
///   styled [TextSpan] through the active `MarkdownSpanEngine`;
/// * it provides selection aware editing operations and an undo / redo history
///   used by the built-in commands and toolbar.
///
/// Pass your own controller to `MarkdownEditor` to control the document, share
/// it between widgets, or apply commands programmatically:
///
/// ```dart
/// final MarkdownEditorController controller =
///     MarkdownEditorController(text: '# Hello');
///
/// MarkdownEditor(controller: controller);
///
/// controller.toggleInlineWrap(marker: '**', placeholder: 'bold text');
/// ```
class MarkdownEditorController extends TextEditingController {
  /// Creates a Markdown editing controller.
  MarkdownEditorController({
    super.text,
    MarkdownLineAnalyzer? analyzer,
    this.historyLimit = 200,
    this.historyCoalesceWindow = const Duration(milliseconds: 600),
  }) : _analyzer = analyzer ?? const DefaultMarkdownLineAnalyzer() {
    _history = MarkdownHistory(
      limit: historyLimit,
      coalesceWindow: historyCoalesceWindow,
    );
  }

  /// Maximum number of undo steps.
  final int historyLimit;

  /// Time window in which single character edits merge into one undo step.
  final Duration historyCoalesceWindow;

  late final MarkdownHistory _history;
  MarkdownLineAnalyzer _analyzer;
  bool _suppressHistory = false;

  MarkdownDocumentLayout? _cachedLayout;
  MarkdownLineAnalyzer? _cachedAnalyzer;
  String? _cachedText;

  /// Whether the editing surface styles Markdown syntax.
  ///
  /// When `false` the controller renders plain source text, which is what
  /// `MarkdownEditorMode.source` uses.
  bool syntaxHighlighting = true;

  /// The undo / redo history.
  MarkdownHistory get history => _history;

  /// The analyzer used by [layout].
  MarkdownLineAnalyzer get analyzer => _analyzer;

  set analyzer(MarkdownLineAnalyzer analyzer) {
    if (identical(analyzer, _analyzer)) {
      return;
    }
    _analyzer = analyzer;
    _invalidateLayout();
    notifyListeners();
  }

  /// Whether an undo step is available.
  bool get canUndo => _history.canUndo;

  /// Whether a redo step is available.
  bool get canRedo => _history.canRedo;

  /// The parsed document layout for the current text.
  MarkdownDocumentLayout get layout => layoutFor(_analyzer);

  /// The parsed layout for [text] using [analyzer], cached by analyzer and text.
  MarkdownDocumentLayout layoutFor(MarkdownLineAnalyzer analyzer) {
    final String currentText = text;
    if (_cachedLayout == null ||
        _cachedText != currentText ||
        !identical(_cachedAnalyzer, analyzer)) {
      _cachedLayout = analyzer.analyze(currentText);
      _cachedText = currentText;
      _cachedAnalyzer = analyzer;
    }
    return _cachedLayout!;
  }

  /// The line that contains the primary selection.
  MarkdownLineInfo get currentLine => layout.lineAtOffset(selection.start);

  /// The source range of the line that contains the primary selection.
  TextRange get currentLineRange {
    final MarkdownLineInfo line = currentLine;
    return TextRange(start: line.start, end: line.end);
  }

  /// The source range spanning every line touched by the selection, or `null`
  /// when the selection is unset.
  ///
  /// This is the "active" range of
  /// [MarkdownMarkerVisibility.hiddenExceptActiveLine]: markers stay visible on
  /// these lines and collapse everywhere else. The editing surface passes the
  /// same range to `MarkdownDecorationPainter` so decorations keep matching the
  /// text layout.
  TextRange? get selectionLineRange {
    final TextSelection current = selection;
    if (!current.isValid) {
      return null;
    }
    return layout.lineRangeForSelection(current);
  }

  /// The lines touched by the current selection.
  List<MarkdownLineInfo> get selectedLines {
    final MarkdownDocumentLayout parsed = layout;
    final int startLine = parsed.lineIndexAtOffset(selection.start);
    final int endLine = parsed.lineIndexAtOffset(selection.end);
    return <MarkdownLineInfo>[
      for (int i = startLine; i <= endLine; i++) parsed.lines[i],
    ];
  }

  @override
  set value(TextEditingValue newValue) {
    final TextEditingValue oldValue = super.value;
    final bool textChanged = newValue.text != oldValue.text;
    if (textChanged && !_suppressHistory) {
      _history.record(oldValue, newValue);
    }
    if (textChanged) {
      _invalidateLayout();
    }
    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final MarkdownEditorScope? scope = MarkdownEditorScope.maybeOf(context);
    final MarkdownEditorTheme theme = scope?.theme ?? MarkdownEditorTheme.fallback(context);
    final MarkdownEditorExtensions extensions =
        scope?.extensions ?? const MarkdownEditorExtensions();
    final TextStyle baseStyle = style ??
        theme.body ??
        DefaultTextStyle.of(context).style;

    if (!syntaxHighlighting) {
      return TextSpan(style: baseStyle, text: text);
    }

    final MarkdownLineAnalyzer analyzer = extensions.lineAnalyzer ?? _analyzer;
    final MarkdownDocumentLayout parsed = layoutFor(analyzer);
    final bool revealActiveLine = theme.markerVisibility ==
        MarkdownMarkerVisibility.hiddenExceptActiveLine;
    final TextSelection current = selection;
    return extensions.engine.build(
      MarkdownSpanBuildContext(
        text: text,
        layout: parsed,
        theme: theme,
        baseStyle: baseStyle,
        rules: extensions.activeInlineRules,
        activeLineRange: revealActiveLine && current.isValid
            ? parsed.lineRangeForSelection(current)
            : null,
        composing: withComposing ? value.composing : null,
      ),
    );
  }

  void _invalidateLayout() {
    _cachedLayout = null;
    _cachedText = null;
    _cachedAnalyzer = null;
  }

  // ---------------------------------------------------------------------------
  // History
  // ---------------------------------------------------------------------------

  /// Undoes the last edit. Returns whether an edit was undone.
  bool undo() {
    final TextEditingValue? target = _history.undo(value);
    if (target == null) {
      return false;
    }
    _restore(target);
    return true;
  }

  /// Redoes the last undone edit. Returns whether an edit was redone.
  bool redo() {
    final TextEditingValue? target = _history.redo(value);
    if (target == null) {
      return false;
    }
    _restore(target);
    return true;
  }

  /// Clears the undo and redo history.
  void clearHistory() => _history.clear();

  void _restore(TextEditingValue target) {
    _suppressHistory = true;
    try {
      value = TextEditingValue(
        text: target.text,
        selection: _clampSelection(target.selection, target.text.length),
        composing: TextRange.empty,
      );
    } finally {
      _suppressHistory = false;
    }
    _invalidateLayout();
  }

  // ---------------------------------------------------------------------------
  // Low level editing
  // ---------------------------------------------------------------------------

  /// Replaces [range] with [replacement] and sets the selection.
  void replaceSource(
    TextRange range, {
    String replacement = '',
    TextSelection? selection,
  }) {
    final int start = range.start.clamp(0, text.length);
    final int end = range.end.clamp(0, text.length);
    final String next = text.replaceRange(start, end, replacement);
    value = TextEditingValue(
      text: next,
      selection: _clampSelection(
        selection ?? TextSelection.collapsed(offset: start + replacement.length),
        next.length,
      ),
      composing: TextRange.empty,
    );
  }

  /// Replaces the current selection, or inserts at the caret when collapsed.
  ///
  /// [selectionBase] and [selectionExtent] are offsets relative to the start of
  /// [replacement]; when omitted the caret is placed at the end of the inserted
  /// text.
  void insertText(
    String replacement, {
    int? selectionBase,
    int? selectionExtent,
  }) {
    final TextSelection current = selection;
    final int start = current.isValid ? current.start : text.length;
    final int end = current.isValid ? current.end : text.length;
    final String next = text.replaceRange(start, end, replacement);
    final int base = start + (selectionBase ?? replacement.length);
    final int extent = start + (selectionExtent ?? selectionBase ?? replacement.length);
    value = TextEditingValue(
      text: next,
      selection: _clampSelection(
        TextSelection(baseOffset: base, extentOffset: extent),
        next.length,
      ),
      composing: TextRange.empty,
    );
  }

  /// Selects all text.
  void selectAllSource() {
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  // ---------------------------------------------------------------------------
  // Inline operations
  // ---------------------------------------------------------------------------

  /// Wraps or unwraps the selection with [marker].
  ///
  /// When the selection is collapsed the word under the caret is wrapped, or a
  /// [placeholder] is inserted and selected when there is no word. When the
  /// selection is already wrapped (either including the markers or surrounded
  /// by them) the markers are removed.
  void toggleInlineWrap({
    required String marker,
    String placeholder = '',
    String? closingMarker,
  }) {
    final String close = closingMarker ?? marker;
    if (marker.isEmpty) {
      return;
    }
    final bool hasSelection = selection.isValid && !selection.isCollapsed;
    if (!hasSelection) {
      final TextRange? word = wordRangeAt(selection.isValid ? selection.start : 0);
      if (word != null) {
        final String content = text.substring(word.start, word.end);
        value = TextEditingValue(
          text: text.replaceRange(word.start, word.end, '$marker$content$close'),
          selection: TextSelection(
            baseOffset: word.start + marker.length,
            extentOffset: word.start + marker.length + content.length,
          ),
        );
        return;
      }
      final String inserted = '$marker$placeholder$close';
      insertText(
        inserted,
        selectionBase: marker.length,
        selectionExtent: marker.length + placeholder.length,
      );
      return;
    }

    final int start = selection.start;
    final int end = selection.end;
    final String selected = text.substring(start, end);

    if (selected.length >= marker.length + close.length &&
        selected.startsWith(marker) &&
        selected.endsWith(close)) {
      final String inner =
          selected.substring(marker.length, selected.length - close.length);
      replaceSource(
        TextRange(start: start, end: end),
        replacement: inner,
        selection: TextSelection(
          baseOffset: start,
          extentOffset: start + inner.length,
        ),
      );
      return;
    }

    final bool surroundedBefore = start >= marker.length &&
        text.substring(start - marker.length, start) == marker;
    final bool surroundedAfter = end + close.length <= text.length &&
        text.substring(end, end + close.length) == close;
    if (surroundedBefore && surroundedAfter) {
      final String next = text
          .replaceRange(end, end + close.length, '')
          .replaceRange(start - marker.length, start, '');
      value = TextEditingValue(
        text: next,
        selection: TextSelection(
          baseOffset: start - marker.length,
          extentOffset: end - marker.length,
        ),
      );
      return;
    }

    final String next = text.replaceRange(start, end, '$marker$selected$close');
    value = TextEditingValue(
      text: next,
      selection: TextSelection(
        baseOffset: start + marker.length,
        extentOffset: start + marker.length + selected.length,
      ),
    );
  }

  /// Toggles one line prefix on every selected line.
  ///
  /// When every selected line already matches [pattern], the matched prefix is
  /// removed; otherwise [prefix] (or `prefixFor(index)` for ordered lists) is
  /// prepended to lines that do not already match.
  void toggleLinePrefix({
    required RegExp pattern,
    String? prefix,
    String Function(int index)? prefixFor,
    bool removeWhenAllMatch = true,
    bool Function(String line)? skip,
    bool Function(String line)? alreadyPrefixed,
  }) {
    final List<MarkdownLineInfo> lines = selectedLines;
    final bool allMatch = removeWhenAllMatch &&
        lines.every((MarkdownLineInfo line) =>
            (skip?.call(line.text) ?? false) || pattern.hasMatch(line.text));

    _transformSelectedLines((String line, int index, int absoluteIndex) {
      if (skip?.call(line) ?? false) {
        return line;
      }
      if (allMatch) {
        return line.replaceFirst(pattern, '');
      }
      if (alreadyPrefixed?.call(line) ?? pattern.hasMatch(line)) {
        return line;
      }
      final String marker = prefixFor?.call(index) ?? prefix ?? '';
      return '$marker$line';
    });
  }

  /// Applies the heading level [level] (0 removes the heading) to every
  /// selected line.
  void setHeadingLevel(int level) {
    _transformSelectedLines((String line, int index, int absoluteIndex) {
      final String content =
          line.replaceFirst(RegExp(r'^\s{0,3}#{1,6}(?:[ \t]+|$)'), '');
      if (level <= 0) {
        return content;
      }
      return '${'#' * level}${content.isEmpty ? '' : ' '}$content';
    });
  }

  /// Toggles a `>` block quote prefix on every selected line.
  void toggleBlockquote() {
    final bool allQuoted = selectedLines.every(
      (MarkdownLineInfo line) =>
          line.text.trim().isEmpty || line.text.startsWith('>'),
    );
    _transformSelectedLines((String line, int index, int absoluteIndex) {
      if (line.trim().isEmpty) {
        return line;
      }
      if (allQuoted) {
        return line.replaceFirst(RegExp(r'^>\s?'), '');
      }
      return '> $line';
    });
  }

  /// Toggles a `-` bullet list prefix on every selected line.
  void toggleBulletList() {
    final RegExp bullet = RegExp(r'^\s*[-*+]\s+');
    final bool allBullets = selectedLines.every(
      (MarkdownLineInfo line) =>
          line.text.trim().isEmpty || bullet.hasMatch(line.text),
    );
    _transformSelectedLines((String line, int index, int absoluteIndex) {
      if (line.trim().isEmpty) {
        return line;
      }
      if (allBullets) {
        return line.replaceFirst(bullet, '');
      }
      if (RegExp(r'^\s*\d{1,9}[.)]\s+').hasMatch(line)) {
        return line.replaceFirst(RegExp(r'^\s*\d{1,9}[.)]\s+'), '- ');
      }
      return bullet.hasMatch(line) ? line : '- $line';
    });
  }

  /// Toggles an ordered list prefix on every selected line.
  void toggleOrderedList() {
    final RegExp ordered = RegExp(r'^\s*\d{1,9}[.)]\s+');
    final bool allOrdered = selectedLines.every(
      (MarkdownLineInfo line) =>
          line.text.trim().isEmpty || ordered.hasMatch(line.text),
    );
    int counter = 0;
    _transformSelectedLines((String line, int index, int absoluteIndex) {
      if (line.trim().isEmpty) {
        return line;
      }
      if (allOrdered) {
        return line.replaceFirst(ordered, '');
      }
      counter++;
      final String numbered = '$counter. ';
      if (RegExp(r'^\s*[-*+]\s+').hasMatch(line)) {
        return line.replaceFirst(RegExp(r'^\s*[-*+]\s+'), numbered);
      }
      return ordered.hasMatch(line) ? line : '$numbered$line';
    });
  }

  /// Toggles a `- [ ]` task list prefix on every selected line.
  void toggleTaskList() {
    final RegExp task = RegExp(r'^\s*[-*+]\s+\[[ xX]\]\s+');
    final bool allTasks = selectedLines.every(
      (MarkdownLineInfo line) =>
          line.text.trim().isEmpty || task.hasMatch(line.text),
    );
    _transformSelectedLines((String line, int index, int absoluteIndex) {
      if (line.trim().isEmpty) {
        return line;
      }
      if (allTasks) {
        return line.replaceFirst(task, '- ');
      }
      if (task.hasMatch(line)) {
        return line;
      }
      final RegExp bullet = RegExp(r'^\s*[-*+]\s+');
      if (bullet.hasMatch(line)) {
        final String prefix = bullet.firstMatch(line)!.group(0)!;
        return line.replaceFirst(bullet, '$prefix[ ] ');
      }
      return '- [ ] $line';
    });
  }

  /// Flips the checkbox of the current line or of every selected task line.
  void toggleTaskState() {
    _transformSelectedLines((String line, int index, int absoluteIndex) {
      final RegExpMatch? match = RegExp(r'\[([ xX])\]').firstMatch(line);
      if (match == null) {
        return line;
      }
      final String replacement = match.group(1) == ' ' ? '[x]' : '[ ]';
      return line.replaceRange(match.start, match.end, replacement);
    });
  }

  /// Indents every selected line by [spaces].
  void indentLines({int spaces = 2}) {
    _transformSelectedLines((String line, int index, int absoluteIndex) {
      if (line.isEmpty) {
        return line;
      }
      return '${' ' * spaces}$line';
    });
  }

  /// Removes up to [spaces] leading spaces from every selected line.
  void outdentLines({int spaces = 2}) {
    _transformSelectedLines((String line, int index, int absoluteIndex) {
      int removed = 0;
      int cursor = 0;
      while (cursor < line.length && cursor < spaces && line[cursor] == ' ') {
        cursor++;
        removed++;
      }
      return removed == 0 ? line : line.substring(cursor);
    });
  }

  /// Inserts [snippet] as its own block, replacing the current selection.
  ///
  /// [caretOffset] is relative to the start of the inserted snippet. When it is
  /// omitted the caret is placed at the end of the snippet.
  void insertBlock(String snippet, {int? caretOffset}) {
    final TextSelection current = selection;
    final int insertionPoint =
        current.isValid ? current.start : text.length;
    final int removalEnd = current.isValid ? current.end : insertionPoint;
    final MarkdownLineInfo line = layout.lineAtOffset(insertionPoint);
    final bool atLineStart = insertionPoint <= line.start;
    final bool atLineEnd = removalEnd >= line.end;
    final String prefix = atLineStart ? '' : '\n';
    final String suffix = atLineEnd ? '' : '\n';
    final String insertion = '$prefix$snippet$suffix';
    final String next = text.replaceRange(insertionPoint, removalEnd, insertion);
    final int caret =
        insertionPoint + prefix.length + (caretOffset ?? snippet.length);
    value = TextEditingValue(
      text: next,
      selection: _clampSelection(
        TextSelection.collapsed(offset: caret),
        next.length,
      ),
      composing: TextRange.empty,
    );
  }

  /// Removes the fences of a fenced code block [block], keeping its content.
  void removeFence(MarkdownBlock block) {
    if (block.kind != MarkdownBlockKind.fencedCode) {
      return;
    }
    final MarkdownDocumentLayout parsed = layout;
    final MarkdownLineInfo? open = parsed.lineAt(block.startLine);
    if (open == null) {
      return;
    }
    final MarkdownLineInfo? close =
        block.endLine > block.startLine ? parsed.lineAt(block.endLine) : null;

    String next = text;
    if (close != null) {
      int start = close.start;
      if (start > 0 && next[start - 1] == '\n') {
        start -= 1;
        if (start > 0 && next[start - 1] == '\r') {
          start -= 1;
        }
      }
      next = next.replaceRange(start, close.end, '');
    }
    int end = open.end;
    if (end < text.length && text[end] == '\r') {
      end += 1;
    }
    if (end < text.length && text[end] == '\n') {
      end += 1;
    }
    final int removeStart = open.start;
    next = next.replaceRange(removeStart, end, '');
    value = TextEditingValue(
      text: next,
      selection: _clampSelection(
        TextSelection.collapsed(offset: removeStart),
        next.length,
      ),
      composing: TextRange.empty,
    );
  }

  /// Returns the word range around [offset], or `null` when there is no word.
  TextRange? wordRangeAt(int offset) {
    final int safeOffset = offset.clamp(0, text.length);
    if (text.isEmpty) {
      return null;
    }
    bool isWord(int index) {
      if (index < 0 || index >= text.length) {
        return false;
      }
      final int code = text.codeUnitAt(index);
      return (code >= 0x30 && code <= 0x39) ||
          (code >= 0x41 && code <= 0x5A) ||
          (code >= 0x61 && code <= 0x7A) ||
          code == 0x5F ||
          (code >= 0x4E00 && code <= 0x9FFF) ||
          (code >= 0x3040 && code <= 0x30FF) ||
          (code >= 0xAC00 && code <= 0xD7AF);
    }

    int start = safeOffset;
    while (start > 0 && isWord(start - 1)) {
      start--;
    }
    int end = safeOffset;
    while (end < text.length && isWord(end)) {
      end++;
    }
    if (start == end) {
      return null;
    }
    return TextRange(start: start, end: end);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _transformSelectedLines(
    String Function(String line, int index, int absoluteIndex) transform,
  ) {
    final TextSelection current = selection;
    if (!current.isValid) {
      return;
    }
    final MarkdownDocumentLayout parsed = layout;
    final int startLine = parsed.lineIndexAtOffset(current.start);
    final int endLine = parsed.lineIndexAtOffset(current.end);
    final int blockStart = parsed.lines[startLine].start;
    final int blockEnd = parsed.lines[endLine].end;
    final String block = text.substring(blockStart, blockEnd);
    final List<String> original = block.split('\n');
    final List<String> updated = <String>[
      for (int i = 0; i < original.length; i++)
        transform(original[i], i, startLine + i),
    ];
    if (updated.join('\n') == block) {
      return;
    }

    final List<int> newStarts = <int>[];
    int cursor = blockStart;
    for (final String line in updated) {
      newStarts.add(cursor);
      cursor += line.length + 1;
    }
    final String newBlock = updated.join('\n');
    final String nextText = text.replaceRange(blockStart, blockEnd, newBlock);
    final int delta = newBlock.length - block.length;

    int mapOffset(int offset) {
      final int lineIndex = parsed.lineIndexAtOffset(offset);
      if (lineIndex < startLine || lineIndex > endLine) {
        return _clampInt(offset + delta, 0, nextText.length);
      }
      final int local = lineIndex - startLine;
      final int column = offset - parsed.lines[lineIndex].start;
      return _clampInt(
        newStarts[local] + math.min(column, updated[local].length),
        0,
        nextText.length,
      );
    }

    value = TextEditingValue(
      text: nextText,
      selection: _clampSelection(
        TextSelection(
          baseOffset: mapOffset(current.start),
          extentOffset: mapOffset(current.end),
        ),
        nextText.length,
      ),
      composing: TextRange.empty,
    );
  }

  static TextSelection _clampSelection(TextSelection selection, int length) {
    final int base = _clampInt(selection.baseOffset, 0, length);
    final int extent = _clampInt(selection.extentOffset, 0, length);
    return TextSelection(baseOffset: base, extentOffset: extent);
  }

  static int _clampInt(int value, int lower, int upper) {
    if (value < lower) {
      return lower;
    }
    if (value > upper) {
      return upper;
    }
    return value;
  }
}
