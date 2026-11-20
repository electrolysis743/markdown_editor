import 'dart:ui' show TextRange;

import 'package:flutter/foundation.dart';

/// The semantic kind of a single line of Markdown source.
///
/// The line kind drives both the visual style of the line (see
/// `MarkdownEditorTheme`) and the block decorations painted behind the text
/// (see `MarkdownLineDecorator`).
enum MarkdownLineKind {
  /// An empty line, or a line containing only whitespace.
  blank,

  /// A regular paragraph line, including lazy continuation lines.
  paragraph,

  /// An ATX heading line, e.g. `## Title`.
  heading,

  /// A `-`, `*` or `+` list item.
  bulletList,

  /// A `1.` / `1)` ordered list item.
  orderedList,

  /// A list item with a task checkbox, e.g. `- [x] Done`.
  taskList,

  /// A line that belongs to a block quote, e.g. `> quoted`.
  blockquote,

  /// A line inside a fenced code block, including the opening and closing
  /// fence lines.
  fencedCode,

  /// A line that belongs to a table (header row, delimiter row or body row).
  table,

  /// A thematic break, e.g. `---` or `***`.
  horizontalRule,
}

/// An immutable description of one source line of a Markdown document.
///
/// Offsets are absolute offsets into the document text. [end] points at the
/// line feed (or at the end of the document) and never includes the line
/// ending itself, so `text.substring(line.start, line.end)` reproduces the
/// raw source of the line.
@immutable
class MarkdownLineInfo {
  /// Creates a line description.
  const MarkdownLineInfo({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
    this.kind = MarkdownLineKind.blank,
    this.headingLevel = 0,
    this.quoteDepth = 0,
    this.listIndent = 0,
    this.listMarker = '',
    this.orderedNumber,
    this.isTask = false,
    this.taskChecked = false,
    this.isFenceStart = false,
    this.isFenceEnd = false,
    this.fenceLanguage,
    this.fenceDepth = 0,
    this.isTableDelimiter = false,
    this.contentStart,
    this.blockIndex = -1,
    this.hasNewline = false,
  });

  /// Zero based index of this line inside the document.
  final int index;

  /// Absolute offset of the first character of the line.
  final int start;

  /// Absolute offset just past the last character of the line, excluding the
  /// line ending.
  final int end;

  /// The raw source text of the line, without its line ending.
  final String text;

  /// The semantic kind of the line.
  final MarkdownLineKind kind;

  /// Heading level (1-6) for [MarkdownLineKind.heading] lines, `0` otherwise.
  final int headingLevel;

  /// Nesting depth of the block quote prefix (`> >` is depth 2).
  final int quoteDepth;

  /// Number of leading spaces before the list marker or block content.
  final int listIndent;

  /// The raw list marker, for example `-` or `1.`.
  final String listMarker;

  /// The ordered list number for [MarkdownLineKind.orderedList] lines.
  final int? orderedNumber;

  /// Whether this line is a task list item, i.e. contains `[ ]` or `[x]`.
  final bool isTask;

  /// Whether the task checkbox of this line is checked.
  final bool taskChecked;

  /// Whether this line opens a fenced code block.
  final bool isFenceStart;

  /// Whether this line closes a fenced code block.
  final bool isFenceEnd;

  /// The info string of a fenced code block, for example `dart`.
  final String? fenceLanguage;

  /// How many fenced code blocks enclose this line (`0` for lines outside of
  /// any fenced code block).
  final int fenceDepth;

  /// Whether this line is the `|---|---|` delimiter row of a table.
  final bool isTableDelimiter;

  /// Absolute offset where the inline content of the line begins, after the
  /// block level markers such as `#`, `>` or `- `.
  final int? contentStart;

  /// Index of the enclosing block in `MarkdownDocumentLayout.blocks`, or `-1`.
  final int blockIndex;

  /// Whether the line is terminated by a line feed.
  final bool hasNewline;

  /// Number of characters in the line, excluding the line ending.
  int get length => end - start;

  /// Whether the line contains nothing but whitespace.
  bool get isBlank => kind == MarkdownLineKind.blank;

  /// Absolute offset where inline content starts; defaults to [start].
  int get contentOffset => contentStart ?? start;

  /// A text range that covers the whole line, excluding the line ending.
  TextRange get range => TextRange(start: start, end: end);

  /// A text range that covers the inline content of the line.
  TextRange get contentRange => TextRange(start: contentOffset, end: end);

  /// Returns a copy with the given fields replaced.
  MarkdownLineInfo copyWith({
    int? index,
    int? start,
    int? end,
    String? text,
    MarkdownLineKind? kind,
    int? headingLevel,
    int? quoteDepth,
    int? listIndent,
    String? listMarker,
    int? orderedNumber,
    bool? isTask,
    bool? taskChecked,
    bool? isFenceStart,
    bool? isFenceEnd,
    String? fenceLanguage,
    int? fenceDepth,
    bool? isTableDelimiter,
    int? contentStart,
    int? blockIndex,
    bool? hasNewline,
  }) {
    return MarkdownLineInfo(
      index: index ?? this.index,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
      kind: kind ?? this.kind,
      headingLevel: headingLevel ?? this.headingLevel,
      quoteDepth: quoteDepth ?? this.quoteDepth,
      listIndent: listIndent ?? this.listIndent,
      listMarker: listMarker ?? this.listMarker,
      orderedNumber: orderedNumber ?? this.orderedNumber,
      isTask: isTask ?? this.isTask,
      taskChecked: taskChecked ?? this.taskChecked,
      isFenceStart: isFenceStart ?? this.isFenceStart,
      isFenceEnd: isFenceEnd ?? this.isFenceEnd,
      fenceLanguage: fenceLanguage ?? this.fenceLanguage,
      fenceDepth: fenceDepth ?? this.fenceDepth,
      isTableDelimiter: isTableDelimiter ?? this.isTableDelimiter,
      contentStart: contentStart ?? this.contentStart,
      blockIndex: blockIndex ?? this.blockIndex,
      hasNewline: hasNewline ?? this.hasNewline,
    );
  }

  @override
  String toString() {
    return 'MarkdownLineInfo(index: $index, kind: ${kind.name}, '
        'range: $start..$end, text: ${text.length > 24 ? '${text.substring(0, 24)}…' : text})';
  }

  @override
  bool operator ==(Object other) {
    return other is MarkdownLineInfo &&
        other.index == index &&
        other.start == start &&
        other.end == end &&
        other.text == text &&
        other.kind == kind &&
        other.headingLevel == headingLevel &&
        other.quoteDepth == quoteDepth &&
        other.listIndent == listIndent &&
        other.listMarker == listMarker &&
        other.orderedNumber == orderedNumber &&
        other.isTask == isTask &&
        other.taskChecked == taskChecked &&
        other.isFenceStart == isFenceStart &&
        other.isFenceEnd == isFenceEnd &&
        other.fenceLanguage == fenceLanguage &&
        other.fenceDepth == fenceDepth &&
        other.isTableDelimiter == isTableDelimiter &&
        other.contentStart == contentStart &&
        other.blockIndex == blockIndex &&
        other.hasNewline == hasNewline;
  }

  @override
  int get hashCode => Object.hash(
        index,
        start,
        end,
        text,
        kind,
        headingLevel,
        quoteDepth,
        listIndent,
        listMarker,
        orderedNumber,
        isTask,
        taskChecked,
        isFenceStart,
        isFenceEnd,
        fenceLanguage,
        fenceDepth,
        isTableDelimiter,
        contentStart,
        blockIndex,
        hasNewline,
      );
}
