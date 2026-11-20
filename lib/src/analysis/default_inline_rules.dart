import 'package:flutter/painting.dart';

import '../model/markdown_line_info.dart';
import 'markdown_inline_rule.dart';
import 'markdown_token_type.dart';

// The built-in inline rules.
//
// Each rule is a small, independent class so applications can remove one
// (through `MarkdownEditorExtensions.replaceDefaultInlineRules`) or add their
// own rules next to the defaults. The rules are ordered by priority; the values
// leave gaps so custom rules can be slotted between them.

// -----------------------------------------------------------------------------
// Escapes
// -----------------------------------------------------------------------------

/// Handles backslash escapes such as `\*` or `\_`.
class EscapeInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const EscapeInlineRule();

  static final RegExp _pattern = RegExp(r'\\([\\`*_{}\[\]()#+\-.!>~|])');

  @override
  int get priority => 100;

  @override
  bool get masksLowerPriority => true;

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(_pattern)) {
      scan.addMarker(match.start, match.start + 1, priority: priority);
      scan.mask(match.start + 1, match.end, priority: priority);
    }
  }
}

// -----------------------------------------------------------------------------
// Code
// -----------------------------------------------------------------------------

/// Handles inline code spans delimited by backtick runs.
class InlineCodeInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const InlineCodeInlineRule();

  @override
  int get priority => 90;

  @override
  bool get masksLowerPriority => true;

  @override
  void scan(MarkdownInlineScan scan) {
    int cursor = scan.start;
    while (cursor < scan.end) {
      if (scan.text[cursor] != '`' ||
          scan.isEscaped(cursor) ||
          scan.isMasked(cursor)) {
        cursor++;
        continue;
      }
      int runEnd = cursor;
      while (runEnd < scan.end && scan.text[runEnd] == '`') {
        runEnd++;
      }
      final int runLength = runEnd - cursor;
      int close = -1;
      int probe = runEnd;
      while (probe < scan.end) {
        if (scan.text[probe] == '`' && !scan.isMasked(probe)) {
          int probeEnd = probe;
          while (probeEnd < scan.end && scan.text[probeEnd] == '`') {
            probeEnd++;
          }
          if (probeEnd - probe == runLength) {
            close = probe;
            break;
          }
          probe = probeEnd;
          continue;
        }
        probe++;
      }
      if (close < 0) {
        cursor = runEnd;
        continue;
      }
      scan.addMarker(cursor, runEnd, priority: priority);
      scan.add(runEnd, close, MarkdownTokenType.code, priority: priority);
      scan.addMarker(close, close + runLength, priority: priority);
      scan.mask(cursor, close + runLength, priority: priority);
      cursor = close + runLength;
    }
  }
}

// -----------------------------------------------------------------------------
// Images and links
// -----------------------------------------------------------------------------

/// Handles inline images, `![alt](url "title")`.
class ImageInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const ImageInlineRule();

  static final RegExp _pattern = RegExp(
    r'!\[([^\]\n]*)\]\(\s*([^)\s]+)(?:\s+["\u0027]([^"\u0027\n]*)["\u0027])?\s*\)',
  );

  @override
  int get priority => 85;

  @override
  bool get masksLowerPriority => true;

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(_pattern)) {
      if (scan.isMasked(match.start)) {
        continue;
      }
      final String alt = match.group(1)!;
      final String url = match.group(2)!;
      final int bracket = match.start + 1;
      final int altStart = bracket + 1;
      final int altEnd = altStart + alt.length;
      final int urlStart = _urlStart(scan.text, altEnd, match.end);

      scan.addMarker(match.start, bracket + 1, priority: priority);
      scan.add(altStart, altEnd, MarkdownTokenType.imageAlt,
          priority: priority);
      scan.addMarker(altEnd, urlStart, priority: priority);
      scan.add(urlStart, urlStart + url.length, MarkdownTokenType.linkUrl,
          priority: priority);
      scan.addMarker(urlStart + url.length, match.end, priority: priority);
      scan.mask(match.start, match.end, priority: priority);
    }
  }
}

/// Handles inline links, `[text](url)`, and reference style links,
/// `[text][label]`.
class LinkInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const LinkInlineRule();

  static final RegExp _inline = RegExp(
    r'\[([^\]\n]*)\]\(\s*([^)\s]+)(?:\s+["\u0027]([^"\u0027\n]*)["\u0027])?\s*\)',
  );
  static final RegExp _reference = RegExp(r'\[([^\]\n]+)\]\[([^\]\n]*)\]');

  @override
  int get priority => 80;

  @override
  bool get masksLowerPriority => true;

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(_inline)) {
      if (scan.isMasked(match.start)) {
        continue;
      }
      final String label = match.group(1)!;
      final String url = match.group(2)!;
      final int labelStart = match.start + 1;
      final int labelEnd = labelStart + label.length;
      final int urlStart = _urlStart(scan.text, labelEnd, match.end);

      scan.addMarker(match.start, labelStart, priority: priority);
      scan.add(labelStart, labelEnd, MarkdownTokenType.link,
          priority: priority);
      scan.addMarker(labelEnd, urlStart, priority: priority);
      scan.add(urlStart, urlStart + url.length, MarkdownTokenType.linkUrl,
          priority: priority);
      scan.addMarker(urlStart + url.length, match.end, priority: priority);
      scan.mask(match.start, match.end, priority: priority);
    }

    for (final RegExpMatch match in scan.matches(_reference)) {
      if (scan.isMasked(match.start)) {
        continue;
      }
      final String label = match.group(1)!;
      final String reference = match.group(2)!;
      final int labelStart = match.start + 1;
      final int labelEnd = labelStart + label.length;
      final int referenceStart = labelEnd + 2;

      scan.addMarker(match.start, labelStart, priority: priority);
      scan.add(labelStart, labelEnd, MarkdownTokenType.link,
          priority: priority);
      scan.addMarker(labelEnd, labelEnd + 2, priority: priority);
      scan.add(referenceStart, referenceStart + reference.length,
          MarkdownTokenType.linkUrl,
          priority: priority);
      scan.addMarker(
          referenceStart + reference.length, match.end, priority: priority);
      scan.mask(match.start, match.end, priority: priority);
    }
  }
}

/// Returns the offset of the destination part of an inline link or image.
///
/// The destination always follows the closing `]` and the `(` of the
/// construct, optionally separated by whitespace.
int _urlStart(String text, int labelEnd, int matchEnd) {
  int cursor = labelEnd;
  while (cursor < matchEnd && text[cursor] != '(') {
    cursor++;
  }
  if (cursor < matchEnd) {
    cursor++;
  }
  while (cursor < matchEnd && (text[cursor] == ' ' || text[cursor] == '\t')) {
    cursor++;
  }
  return cursor;
}

/// Handles autolinks written as `<https://example.com>`.
class AutolinkInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const AutolinkInlineRule();

  static final RegExp _pattern =
      RegExp(r'<((?:https?|ftp|mailto):[^>\s]+)>', caseSensitive: false);

  @override
  int get priority => 75;

  @override
  bool get masksLowerPriority => true;

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(_pattern)) {
      if (scan.isMasked(match.start)) {
        continue;
      }
      scan.addMarker(match.start, match.start + 1, priority: priority);
      scan.add(match.start + 1, match.end - 1, MarkdownTokenType.linkUrl,
          priority: priority);
      scan.addMarker(match.end - 1, match.end, priority: priority);
      scan.mask(match.start, match.end, priority: priority);
    }
  }
}

// -----------------------------------------------------------------------------
// Emphasis
// -----------------------------------------------------------------------------

/// Handles `**strong**`, `*emphasis*`, `__strong__` and `_emphasis_`, including
/// nesting.
class EmphasisInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const EmphasisInlineRule();

  @override
  int get priority => 60;

  @override
  void scan(MarkdownInlineScan scan) {
    final List<_DelimiterRun> runs = <_DelimiterRun>[];
    int cursor = scan.start;
    while (cursor < scan.end) {
      final String character = scan.text[cursor];
      if ((character != '*' && character != '_') ||
          scan.isEscaped(cursor) ||
          scan.isMasked(cursor)) {
        cursor++;
        continue;
      }
      int runEnd = cursor;
      while (runEnd < scan.end && scan.text[runEnd] == character) {
        runEnd++;
      }
      final String previous = cursor > scan.start ? scan.text[cursor - 1] : ' ';
      final String next = runEnd < scan.end ? scan.text[runEnd] : ' ';
      bool canOpen = !_isWhitespace(next);
      bool canClose = !_isWhitespace(previous);
      if (character == '_') {
        final bool previousIsWord = _isWordCharacter(previous);
        final bool nextIsWord = _isWordCharacter(next);
        if (previousIsWord && nextIsWord) {
          canOpen = false;
          canClose = false;
        } else {
          if (previousIsWord) {
            canOpen = false;
          }
          if (nextIsWord) {
            canClose = false;
          }
        }
      }
      runs.add(
        _DelimiterRun(
          start: cursor,
          length: runEnd - cursor,
          canOpen: canOpen,
          canClose: canClose,
          character: character,
        ),
      );
      cursor = runEnd;
    }

    if (runs.isEmpty) {
      return;
    }

    final Map<String, List<_DelimiterRun>> openers =
        <String, List<_DelimiterRun>>{
      '*': <_DelimiterRun>[],
      '_': <_DelimiterRun>[],
    };

    for (final _DelimiterRun run in runs) {
      while (run.canClose && run.remaining > 0) {
        final List<_DelimiterRun> stack = openers[run.character]!;
        if (stack.isEmpty) {
          break;
        }
        final _DelimiterRun opener = stack.last;
        if (opener.remaining <= 0) {
          stack.removeLast();
          continue;
        }
        final int use = (opener.remaining >= 2 && run.remaining >= 2) ? 2 : 1;
        final int openMarkerEnd = opener.start + opener.length - opener.usedOpen;
        final int openMarkerStart = openMarkerEnd - use;
        final int closeMarkerStart = run.start + run.usedClose;
        final int closeMarkerEnd = closeMarkerStart + use;

        scan.addMarker(openMarkerStart, openMarkerEnd, priority: priority);
        scan.add(
          openMarkerEnd,
          closeMarkerStart,
          use == 2 ? MarkdownTokenType.strong : MarkdownTokenType.emphasis,
          priority: priority,
        );
        scan.addMarker(closeMarkerStart, closeMarkerEnd, priority: priority);

        opener.usedOpen += use;
        run.usedClose += use;
        if (opener.usedOpen >= opener.length) {
          stack.removeLast();
        }
      }
      if (run.canOpen && run.remaining > 0) {
        openers[run.character]!.add(run);
      }
    }
  }

  static bool _isWhitespace(String character) =>
      character == ' ' || character == '\t' || character.isEmpty;

  static bool _isWordCharacter(String character) {
    if (character.isEmpty) {
      return false;
    }
    final int code = character.codeUnitAt(0);
    return (code >= 0x30 && code <= 0x39) ||
        (code >= 0x41 && code <= 0x5A) ||
        (code >= 0x61 && code <= 0x7A) ||
        code > 0x7F;
  }
}

/// Handles strikethrough, `~~text~~`.
class StrikethroughInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const StrikethroughInlineRule();

  static final RegExp _pattern = RegExp(r'~~(?=\S)([^~\n]*?\S)~~');

  @override
  int get priority => 50;

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(_pattern)) {
      if (scan.isMasked(match.start)) {
        continue;
      }
      scan.addMarker(match.start, match.start + 2, priority: priority);
      scan.add(match.start + 2, match.end - 2, MarkdownTokenType.strikethrough,
          priority: priority);
      scan.addMarker(match.end - 2, match.end, priority: priority);
    }
  }
}

/// Handles highlighted text, `==text==`.
class HighlightInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const HighlightInlineRule();

  static final RegExp _pattern = RegExp(r'==(?=\S)([^=\n]*?\S)==');

  @override
  int get priority => 45;

  @override
  void scan(MarkdownInlineScan scan) {
    for (final RegExpMatch match in scan.matches(_pattern)) {
      if (scan.isMasked(match.start)) {
        continue;
      }
      scan.addMarker(match.start, match.start + 2, priority: priority);
      scan.add(match.start + 2, match.end - 2, MarkdownTokenType.highlight,
          priority: priority);
      scan.addMarker(match.end - 2, match.end, priority: priority);
    }
  }
}

/// Handles hard line breaks expressed as two trailing spaces or a trailing
/// backslash.
class HardBreakInlineRule extends MarkdownInlineRule {
  /// Creates the rule.
  const HardBreakInlineRule();

  @override
  int get priority => 40;

  @override
  void scan(MarkdownInlineScan scan) {
    final MarkdownLineInfo line = scan.line;
    if (!line.hasNewline) {
      return;
    }
    final String lineText = line.text;
    if (lineText.endsWith('\\')) {
      final int offset = line.end - 1;
      if (offset >= scan.start) {
        scan.addMarker(offset, line.end, priority: priority);
      }
      return;
    }
    int trailingSpaces = 0;
    for (int i = lineText.length - 1; i >= 0 && lineText[i] == ' '; i--) {
      trailingSpaces++;
    }
    if (trailingSpaces >= 2) {
      final int offset = line.end - trailingSpaces;
      if (offset >= scan.start) {
        scan.addMarker(offset, line.end, priority: priority);
      }
    }
  }
}

/// A mutable delimiter run used by [EmphasisInlineRule].
class _DelimiterRun {
  _DelimiterRun({
    required this.start,
    required this.length,
    required this.canOpen,
    required this.canClose,
    required this.character,
  });

  final int start;
  final int length;
  final bool canOpen;
  final bool canClose;
  final String character;

  int usedOpen = 0;
  int usedClose = 0;

  int get remaining => length - usedOpen - usedClose;

  @override
  String toString() => '_DelimiterRun($character * $length @ $start)';
}

/// The rules enabled by default, in priority order.
const List<MarkdownInlineRule> kDefaultInlineRules = <MarkdownInlineRule>[
  EscapeInlineRule(),
  InlineCodeInlineRule(),
  ImageInlineRule(),
  LinkInlineRule(),
  AutolinkInlineRule(),
  EmphasisInlineRule(),
  StrikethroughInlineRule(),
  HighlightInlineRule(),
  HardBreakInlineRule(),
];

/// Convenience alias so consumers can build ranges without importing painting.
typedef MarkdownRuleTextStyle = TextStyle;
