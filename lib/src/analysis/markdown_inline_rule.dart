import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../model/markdown_document_layout.dart';
import '../model/markdown_line_info.dart';
import 'markdown_token_type.dart';

/// A styled source range produced by a [MarkdownInlineRule].
@immutable
class MarkdownStyleRange {
  /// Creates a style range covering `[start, end)` of the document source.
  const MarkdownStyleRange({
    required this.start,
    required this.end,
    required this.token,
    this.style,
    this.priority = 0,
    this.isMask = false,
    this.payload,
  });

  /// Absolute offset of the first character of the range.
  final int start;

  /// Absolute offset just past the last character of the range.
  final int end;

  /// The semantic token used to resolve a style from the editor theme.
  final MarkdownTokenType token;

  /// An explicit style that overrides the theme style of [token].
  final TextStyle? style;

  /// Ranges with a higher priority are merged later, so they win on conflicts.
  final int priority;

  /// Whether this range hides its characters from lower priority rules.
  ///
  /// Masking is used by rules such as inline code and links so that emphasis
  /// markers inside their content are kept literal.
  final bool isMask;

  /// Optional application defined payload, for example a mention target.
  final Object? payload;

  /// Number of characters covered by the range.
  int get length => end - start;

  @override
  String toString() =>
      'MarkdownStyleRange($start..$end, token: ${token.name}, style: $style)';
}

/// The mutable state handed to a [MarkdownInlineRule] while it scans a line.
class MarkdownInlineScan {
  /// Creates a scan over the inline region of [line].
  MarkdownInlineScan({
    required this.text,
    required this.line,
    required this.layout,
    required this.start,
    required this.end,
    required this.ranges,
  });

  /// The full document source; offsets are absolute document offsets.
  final String text;

  /// The line currently being scanned.
  final MarkdownLineInfo line;

  /// The layout being rendered.
  final MarkdownDocumentLayout layout;

  /// Absolute offset where the inline region starts.
  final int start;

  /// Absolute offset where the inline region ends.
  final int end;

  /// The ranges collected so far. Rules append to this list.
  final List<MarkdownStyleRange> ranges;

  /// Whether [offset] belongs to the inline region.
  bool contains(int offset) => offset >= start && offset < end;

  /// Returns the matches of [pattern] that lie inside the scanned region.
  ///
  /// Rules should use this instead of `pattern.allMatches(text, start)` so
  /// that matches never cross the end of the line or of the scanned region.
  Iterable<RegExpMatch> matches(RegExp pattern) {
    return pattern
        .allMatches(text, start)
        .where((RegExpMatch match) => match.end <= end);
  }

  /// Whether the character at [offset] is escaped by a preceding backslash.
  bool isEscaped(int offset) {
    int backslashes = 0;
    for (int i = offset - 1; i >= start && text[i] == '\\'; i--) {
      backslashes++;
    }
    return backslashes.isOdd;
  }

  int _clamp(int value) {
    if (value < start) {
      return start;
    }
    if (value > end) {
      return end;
    }
    return value;
  }

  /// Whether [offset] is hidden from lower priority rules.
  bool isMasked(int offset) {
    for (final MarkdownStyleRange range in ranges) {
      if (range.isMask && offset >= range.start && offset < range.end) {
        return true;
      }
    }
    return false;
  }

  /// Adds a styled range.
  void add(
    int start,
    int end,
    MarkdownTokenType token, {
    TextStyle? style,
    int priority = 0,
    Object? payload,
  }) {
    if (end <= start) {
      return;
    }
    ranges.add(
      MarkdownStyleRange(
        start: _clamp(start),
        end: _clamp(end),
        token: token,
        style: style,
        priority: priority,
        payload: payload,
      ),
    );
  }

  /// Adds a marker range.
  void addMarker(int start, int end, {int priority = 0}) {
    add(start, end, MarkdownTokenType.marker, priority: priority);
  }

  /// Adds a range that hides its characters from lower priority rules.
  void mask(int start, int end, {int priority = 0}) {
    if (end <= start) {
      return;
    }
    ranges.add(
      MarkdownStyleRange(
        start: _clamp(start),
        end: _clamp(end),
        token: MarkdownTokenType.custom,
        isMask: true,
        priority: priority,
      ),
    );
  }
}

/// A pluggable rule that recognizes one Markdown inline construct.
///
/// Rules are stateless: [scan] receives the line region and appends
/// [MarkdownStyleRange]s to [MarkdownInlineScan.ranges]. The default engine
/// runs rules in descending [priority] order and then merges overlapping
/// ranges, so nested constructs such as `**bold _and italic_**` naturally
/// combine their styles.
///
/// Implement this class to add application specific syntax, for example
/// `@mentions`, `#tags` or `[[wiki links]]`:
///
/// ```dart
/// class MentionRule extends MarkdownInlineRule {
///   const MentionRule();
///
///   @override
///   int get priority => 40;
///
///   @override
///   void scan(MarkdownInlineScan scan) {
///     for (final match
///         in RegExp(r'@[a-zA-Z0-9_]+').allMatches(scan.text, scan.start, scan.end)) {
///       scan.add(
///         match.start,
///         match.end,
///         MarkdownTokenType.custom,
///         style: const TextStyle(color: Color(0xFF1E88E5)),
///       );
///     }
///   }
/// }
/// ```
abstract class MarkdownInlineRule {
  /// Const constructor for rules that hold no mutable state.
  const MarkdownInlineRule();

  /// Rules with a higher priority run first and their styles win conflicts.
  int get priority => 0;

  /// Whether the ranges produced by this rule hide their characters from
  /// lower priority rules.
  bool get masksLowerPriority => false;

  /// A human readable name, used in debug output.
  String get debugName => runtimeType.toString();

  /// Scans [scan] and appends style ranges.
  void scan(MarkdownInlineScan scan);
}
