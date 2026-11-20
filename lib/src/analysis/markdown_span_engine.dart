import 'package:flutter/material.dart';

import '../model/markdown_document_layout.dart';
import '../model/markdown_line_info.dart';
import '../theme/markdown_editor_theme.dart';
import 'default_inline_rules.dart';
import 'markdown_inline_rule.dart';
import 'markdown_token_type.dart';

/// Everything needed to turn a [MarkdownDocumentLayout] into a styled
/// [TextSpan].
class MarkdownSpanBuildContext {
  /// Creates a build context.
  const MarkdownSpanBuildContext({
    required this.text,
    required this.layout,
    required this.theme,
    required this.baseStyle,
    this.rules = kDefaultInlineRules,
    this.showSyntax = true,
    this.composing,
  });

  /// The full document source.
  final String text;

  /// The parsed layout of [text].
  final MarkdownDocumentLayout layout;

  /// The active theme.
  final MarkdownEditorTheme theme;

  /// The base style of the editing surface, usually the text style of the
  /// underlying text field.
  final TextStyle baseStyle;

  /// The inline rules to run, in any order; the engine sorts them by priority.
  final List<MarkdownInlineRule> rules;

  /// When `false`, the source is rendered as plain text (source mode).
  final bool showSyntax;

  /// The composing region of the current IME session, if any.
  final TextRange? composing;
}

/// Converts a parsed Markdown layout into the [TextSpan] rendered by the
/// editing surface.
///
/// The default implementation keeps the span text identical to the document
/// source, which is what makes a `TextEditingController`-based editor able to
/// style Markdown in place: every character, including its syntax markers,
/// stays addressable by the caret and by selection.
abstract class MarkdownSpanEngine {
  /// Const constructor for stateless engines.
  const MarkdownSpanEngine();

  /// Builds the styled span for [context].
  TextSpan build(MarkdownSpanBuildContext context);
}

/// The built-in span engine.
///
/// It styles block level constructs (headings, quotes, lists, fenced code) and
/// runs the inline rules for each line, merging overlapping styles so nested
/// constructs compose.
class DefaultMarkdownSpanEngine implements MarkdownSpanEngine {
  /// Creates the default engine.
  const DefaultMarkdownSpanEngine();

  @override
  TextSpan build(MarkdownSpanBuildContext context) {
    final String text = context.text;
    if (text.isEmpty) {
      return TextSpan(style: context.baseStyle, text: '');
    }
    if (!context.showSyntax) {
      return TextSpan(style: context.baseStyle, text: text);
    }

    final List<MarkdownInlineRule> rules = List<MarkdownInlineRule>.of(context.rules)
      ..sort((MarkdownInlineRule a, MarkdownInlineRule b) =>
          b.priority.compareTo(a.priority));

    final List<TextSpan> spans = <TextSpan>[];
    final List<MarkdownLineInfo> lines = context.layout.lines;

    for (int i = 0; i < lines.length; i++) {
      final MarkdownLineInfo line = lines[i];
      final TextStyle lineStyle = _baseStyleFor(line, context.theme, context.baseStyle);

      if (line.end > line.start) {
        final List<MarkdownStyleRange> ranges = <MarkdownStyleRange>[];
        _collectBlockRanges(line, context.theme, ranges);
        if (_acceptsInlineSyntax(line)) {
          final MarkdownInlineScan scan = MarkdownInlineScan(
            text: text,
            line: line,
            layout: context.layout,
            start: line.contentOffset,
            end: line.end,
            ranges: ranges,
          );
          for (final MarkdownInlineRule rule in rules) {
            rule.scan(scan);
          }
        }
        _addComposingRange(context, ranges);
        spans.addAll(
          _buildLineSpans(
            text: text,
            start: line.start,
            end: line.end,
            baseStyle: lineStyle,
            ranges: ranges,
            theme: context.theme,
          ),
        );
      }

      final int nextStart =
          i + 1 < lines.length ? lines[i + 1].start : text.length;
      if (nextStart > line.end) {
        spans.add(
          TextSpan(
            text: text.substring(line.end, nextStart),
            style: lineStyle,
          ),
        );
      }
    }

    return TextSpan(style: context.baseStyle, children: _merge(spans));
  }

  TextStyle _baseStyleFor(
    MarkdownLineInfo line,
    MarkdownEditorTheme theme,
    TextStyle fallback,
  ) {
    switch (line.kind) {
      case MarkdownLineKind.heading:
        return theme.headingStyle(line.headingLevel, fallback);
      case MarkdownLineKind.fencedCode:
        return fallback.merge(theme.styleForToken(MarkdownTokenType.codeBlock, fallback));
      case MarkdownLineKind.blockquote:
        return fallback.merge(theme.styleForToken(MarkdownTokenType.quote, fallback));
      case MarkdownLineKind.horizontalRule:
        if (theme.paintHorizontalRule) {
          return fallback.copyWith(color: const Color(0x00000000));
        }
        return fallback;
      case MarkdownLineKind.table:
      case MarkdownLineKind.blank:
      case MarkdownLineKind.paragraph:
      case MarkdownLineKind.bulletList:
      case MarkdownLineKind.orderedList:
      case MarkdownLineKind.taskList:
        return fallback;
    }
  }

  bool _acceptsInlineSyntax(MarkdownLineInfo line) {
    return line.kind != MarkdownLineKind.fencedCode &&
        line.kind != MarkdownLineKind.horizontalRule;
  }

  void _collectBlockRanges(
    MarkdownLineInfo line,
    MarkdownEditorTheme theme,
    List<MarkdownStyleRange> ranges,
  ) {
    if (line.kind == MarkdownLineKind.fencedCode) {
      // Only the fence lines are syntax; the code between them is content.
      if (line.isFenceStart || line.isFenceEnd) {
        ranges.add(
          MarkdownStyleRange(
            start: line.start,
            end: line.end,
            token: MarkdownTokenType.marker,
            priority: 200,
          ),
        );
      }
      return;
    }
    if (line.isTableDelimiter ||
        (line.kind == MarkdownLineKind.horizontalRule &&
            !theme.paintHorizontalRule)) {
      ranges.add(
        MarkdownStyleRange(
          start: line.start,
          end: line.end,
          token: MarkdownTokenType.marker,
          priority: 200,
        ),
      );
      return;
    }

    if (line.contentOffset > line.start) {
      final MarkdownTokenType token = switch (line.kind) {
        MarkdownLineKind.taskList => MarkdownTokenType.checkbox,
        MarkdownLineKind.bulletList ||
        MarkdownLineKind.orderedList =>
          MarkdownTokenType.listMarker,
        _ => MarkdownTokenType.marker,
      };
      ranges.add(
        MarkdownStyleRange(
          start: line.start,
          end: line.contentOffset,
          token: token,
          priority: 200,
        ),
      );
    }
  }

  void _addComposingRange(
    MarkdownSpanBuildContext context,
    List<MarkdownStyleRange> ranges,
  ) {
    final TextRange? composing = context.composing;
    if (composing == null || composing.isCollapsed) {
      return;
    }
    if (composing.end <= 0 || composing.start >= context.text.length) {
      return;
    }
    int clampOffset(int value) {
      if (value < 0) {
        return 0;
      }
      if (value > context.text.length) {
        return context.text.length;
      }
      return value;
    }

    ranges.add(
      MarkdownStyleRange(
        start: clampOffset(composing.start),
        end: clampOffset(composing.end),
        token: MarkdownTokenType.custom,
        style: const TextStyle(decoration: TextDecoration.underline),
        priority: 1000,
      ),
    );
  }

  List<TextSpan> _buildLineSpans({
    required String text,
    required int start,
    required int end,
    required TextStyle baseStyle,
    required List<MarkdownStyleRange> ranges,
    required MarkdownEditorTheme theme,
  }) {
    final Set<int> boundaries = <int>{start, end};
    for (final MarkdownStyleRange range in ranges) {
      if (range.isMask || range.end <= start || range.start >= end) {
        continue;
      }
      boundaries.add(range.start < start ? start : range.start);
      boundaries.add(range.end > end ? end : range.end);
    }
    final List<int> sorted = boundaries.toList()..sort();

    final List<TextSpan> spans = <TextSpan>[];
    for (int i = 0; i + 1 < sorted.length; i++) {
      final int from = sorted[i];
      final int to = sorted[i + 1];
      if (from >= to) {
        continue;
      }
      final List<MarkdownStyleRange> active = <MarkdownStyleRange>[
        for (final MarkdownStyleRange range in ranges)
          if (!range.isMask && range.start <= from && range.end >= to) range,
      ]..sort((MarkdownStyleRange a, MarkdownStyleRange b) {
          final int byPriority = a.priority.compareTo(b.priority);
          if (byPriority != 0) {
            return byPriority;
          }
          return a.start.compareTo(b.start);
        });

      TextStyle style = baseStyle;
      for (final MarkdownStyleRange range in active) {
        if (range.token == MarkdownTokenType.marker) {
          style = style.merge(theme.markerStyle(baseStyle));
        } else if (range.style != null) {
          style = style.merge(range.style!);
        } else {
          style = style.merge(theme.styleForToken(range.token, style));
        }
      }
      spans.add(TextSpan(text: text.substring(from, to), style: style));
    }
    return spans;
  }

  List<TextSpan> _merge(List<TextSpan> spans) {
    if (spans.length < 2) {
      return spans;
    }
    final List<TextSpan> merged = <TextSpan>[spans.first];
    for (int i = 1; i < spans.length; i++) {
      final TextSpan previous = merged.last;
      final TextSpan current = spans[i];
      if (previous.style == current.style && previous.recognizer == null) {
        merged[merged.length - 1] = TextSpan(
          text: '${previous.text ?? ''}${current.text ?? ''}',
          style: previous.style,
        );
      } else {
        merged.add(current);
      }
    }
    return merged;
  }
}
