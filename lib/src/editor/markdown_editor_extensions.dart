import 'package:flutter/material.dart';

import '../analysis/default_line_analyzer.dart';
import '../analysis/default_inline_rules.dart';
import '../analysis/markdown_inline_rule.dart';
import '../analysis/markdown_span_engine.dart';
import '../decoration/default_line_decorators.dart';
import '../decoration/markdown_line_decorator.dart';
import '../model/markdown_document_layout.dart';

/// The parsing and rendering pipeline used by the editor, exposed as a set of
/// replaceable stages.
///
/// Every stage defaults to the built-in pipeline:
///
/// ```text
/// source text ──▶ MarkdownLineAnalyzer ──▶ MarkdownDocumentLayout
///                                             │
///                    MarkdownInlineRule list ─┴─▶ MarkdownSpanEngine ──▶ TextSpan
///                                             │
///                       MarkdownLineDecorator ─┴─▶ painted block decoration
/// ```
///
/// Applications can extend a single stage (`@mentions`, custom block syntax,
/// custom decoration) without replacing the rest.
@immutable
class MarkdownEditorExtensions {
  /// Creates an extension set.
  const MarkdownEditorExtensions({
    this.inlineRules = const <MarkdownInlineRule>[],
    this.replaceDefaultInlineRules = false,
    this.lineDecorators = const <MarkdownLineDecorator>[],
    this.replaceDefaultLineDecorators = false,
    this.spanEngine,
    this.lineAnalyzer,
  });

  /// Additional inline rules, appended to (or replacing) the defaults.
  ///
  /// Rules run in descending priority order. Use a priority between `1` and
  /// `35` for syntax that should be styled inside emphasis, and above `100`
  /// for syntax that must win over everything else.
  final List<MarkdownInlineRule> inlineRules;

  /// When `true`, [inlineRules] replace the built-in rules entirely.
  final bool replaceDefaultInlineRules;

  /// Additional line decorators painted behind the text.
  final List<MarkdownLineDecorator> lineDecorators;

  /// When `true`, [lineDecorators] replace the built-in decorators entirely.
  final bool replaceDefaultLineDecorators;

  /// Replaces the default span engine, which turns a layout into styled spans.
  final MarkdownSpanEngine? spanEngine;

  /// Replaces the default line analyzer, which turns source into a layout.
  final MarkdownLineAnalyzer? lineAnalyzer;

  /// The analyzer used by the editor.
  MarkdownLineAnalyzer get analyzer =>
      lineAnalyzer ?? const DefaultMarkdownLineAnalyzer();

  /// The span engine used by the editor.
  MarkdownSpanEngine get engine => spanEngine ?? const DefaultMarkdownSpanEngine();

  /// All inline rules that are active, sorted by descending priority.
  List<MarkdownInlineRule> get activeInlineRules {
    final List<MarkdownInlineRule> rules = <MarkdownInlineRule>[
      if (!replaceDefaultInlineRules) ...kDefaultInlineRules,
      ...inlineRules,
    ];
    rules.sort((MarkdownInlineRule a, MarkdownInlineRule b) =>
        b.priority.compareTo(a.priority));
    return rules;
  }

  /// All line decorators that are active, in painting order.
  List<MarkdownLineDecorator> get activeLineDecorators {
    final List<MarkdownLineDecorator> decorators = <MarkdownLineDecorator>[
      if (!replaceDefaultLineDecorators) ...kDefaultLineDecorators,
      ...lineDecorators,
    ];
    return decorators;
  }

  /// Returns a copy with the given fields replaced.
  MarkdownEditorExtensions copyWith({
    List<MarkdownInlineRule>? inlineRules,
    bool? replaceDefaultInlineRules,
    List<MarkdownLineDecorator>? lineDecorators,
    bool? replaceDefaultLineDecorators,
    MarkdownSpanEngine? spanEngine,
    MarkdownLineAnalyzer? lineAnalyzer,
  }) {
    return MarkdownEditorExtensions(
      inlineRules: inlineRules ?? this.inlineRules,
      replaceDefaultInlineRules:
          replaceDefaultInlineRules ?? this.replaceDefaultInlineRules,
      lineDecorators: lineDecorators ?? this.lineDecorators,
      replaceDefaultLineDecorators:
          replaceDefaultLineDecorators ?? this.replaceDefaultLineDecorators,
      spanEngine: spanEngine ?? this.spanEngine,
      lineAnalyzer: lineAnalyzer ?? this.lineAnalyzer,
    );
  }

  /// Parses [text] with the configured analyzer.
  MarkdownDocumentLayout analyze(String text) => analyzer.analyze(text);
}
