import 'package:flutter/foundation.dart';

/// The kind of a block of consecutive source lines.
///
/// Blocks are the unit used by block decorations, for example the rounded
/// background painted behind a fenced code block or the vertical bar painted
/// next to a block quote.
enum MarkdownBlockKind {
  /// A paragraph, possibly spanning several wrapped source lines.
  paragraph,

  /// A single heading line.
  heading,

  /// A block quote, including all of its nested lines.
  quote,

  /// A fenced code block.
  fencedCode,

  /// A run of list items.
  list,

  /// A table.
  table,

  /// A thematic break.
  horizontalRule,
}

/// A contiguous run of source lines that share a block level meaning.
@immutable
class MarkdownBlock {
  /// Creates a block description.
  const MarkdownBlock({
    required this.kind,
    required this.startLine,
    required this.endLine,
    this.quoteDepth = 0,
    this.language,
    this.listDepth = 0,
    this.headingLevel = 0,
  });

  /// The semantic kind of the block.
  final MarkdownBlockKind kind;

  /// Index of the first line of the block (inclusive).
  final int startLine;

  /// Index of the last line of the block (inclusive).
  final int endLine;

  /// Maximum block quote depth inside this block.
  final int quoteDepth;

  /// Info string of a fenced code block, for example `dart`.
  final String? language;

  /// Indentation level of a list block.
  final int listDepth;

  /// Heading level of a heading block.
  final int headingLevel;

  /// Number of source lines covered by this block.
  int get lineCount => endLine - startLine + 1;

  /// Whether [lineIndex] belongs to this block.
  bool containsLine(int lineIndex) =>
      lineIndex >= startLine && lineIndex <= endLine;

  @override
  String toString() {
    return 'MarkdownBlock(kind: ${kind.name}, lines: $startLine..$endLine, '
        'language: $language)';
  }

  @override
  bool operator ==(Object other) {
    return other is MarkdownBlock &&
        other.kind == kind &&
        other.startLine == startLine &&
        other.endLine == endLine &&
        other.quoteDepth == quoteDepth &&
        other.language == language &&
        other.listDepth == listDepth &&
        other.headingLevel == headingLevel;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        startLine,
        endLine,
        quoteDepth,
        language,
        listDepth,
        headingLevel,
      );
}
