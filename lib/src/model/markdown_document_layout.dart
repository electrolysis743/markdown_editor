import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'markdown_block.dart';
import 'markdown_line_info.dart';

/// An immutable parse of the document source into lines and blocks.
///
/// Layouts are produced by a `MarkdownLineAnalyzer` and cached by
/// `MarkdownEditorController`. They are cheap for typical documents (a single
/// linear pass over the source) and are recomputed only when the text changes.
@immutable
class MarkdownDocumentLayout {
  /// Creates a layout from already parsed lines and blocks.
  const MarkdownDocumentLayout({
    required this.text,
    required this.lines,
    required this.blocks,
  });

  /// Creates an empty layout for an empty document.
  factory MarkdownDocumentLayout.empty() {
    return const MarkdownDocumentLayout(
      text: '',
      lines: <MarkdownLineInfo>[
        MarkdownLineInfo(index: 0, start: 0, end: 0, text: ''),
      ],
      blocks: <MarkdownBlock>[],
    );
  }

  /// The full document source.
  final String text;

  /// The parsed source lines, always containing at least one element.
  final List<MarkdownLineInfo> lines;

  /// The block level grouping of the source lines.
  final List<MarkdownBlock> blocks;

  /// The number of source lines.
  int get lineCount => lines.length;

  /// The blocks whose lines intersect [startLine]..[endLine].
  List<MarkdownBlock> blocksBetween(int startLine, int endLine) {
    return blocks
        .where((MarkdownBlock block) =>
            block.endLine >= startLine && block.startLine <= endLine)
        .toList(growable: false);
  }

  /// Returns the line whose range contains [offset].
  ///
  /// Offsets at a line boundary resolve to the following line, which matches
  /// caret behaviour: a caret placed at the start of a line belongs to it.
  MarkdownLineInfo lineAtOffset(int offset) {
    return lines[lineIndexAtOffset(offset)];
  }

  /// Returns the index of the line that contains [offset].
  int lineIndexAtOffset(int offset) {
    if (offset <= 0) {
      return 0;
    }
    if (offset >= text.length) {
      // The caret can sit on the trailing empty line after a final newline.
      return lines.length - 1;
    }
    int low = 0;
    int high = lines.length - 1;
    while (low <= high) {
      final int mid = (low + high) >> 1;
      final MarkdownLineInfo line = lines[mid];
      if (offset < line.start) {
        high = mid - 1;
      } else if (offset > line.end) {
        low = mid + 1;
      } else {
        return mid;
      }
    }
    return lines.isEmpty ? 0 : lines.length - 1;
  }

  /// Returns the line at [index], or `null` when out of bounds.
  MarkdownLineInfo? lineAt(int index) {
    if (index < 0 || index >= lines.length) {
      return null;
    }
    return lines[index];
  }

  /// Returns the block at [index], or `null` when out of bounds.
  MarkdownBlock? blockAt(int index) {
    if (index < 0 || index >= blocks.length) {
      return null;
    }
    return blocks[index];
  }

  /// Returns the block that contains [lineIndex], or `null` for blank lines.
  MarkdownBlock? blockForLine(int lineIndex) {
    for (final MarkdownBlock block in blocks) {
      if (block.containsLine(lineIndex)) {
        return block;
      }
    }
    return null;
  }

  /// A text range covering all selected lines, clamped to the document.
  TextRange lineRangeForSelection(TextSelection selection) {
    final int startLine = lineIndexAtOffset(selection.start);
    final int endLine = lineIndexAtOffset(selection.end);
    return TextRange(
      start: lines[startLine].start,
      end: lines[endLine].end,
    );
  }

  @override
  String toString() =>
      'MarkdownDocumentLayout(lines: ${lines.length}, blocks: ${blocks.length})';
}
