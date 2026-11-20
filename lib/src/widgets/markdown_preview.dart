// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../controller/markdown_editor_controller.dart';
import '../editor/markdown_editor_builders.dart';
import '../editor/markdown_editor_scope.dart';
import '../theme/markdown_editor_theme.dart';

/// A rendered Markdown preview powered by `flutter_markdown_plus`.
///
/// The preview shares the editor theme: `MarkdownEditorTheme.toMarkdownStyleSheet`
/// maps the editor styles onto a [MarkdownStyleSheet], so headings, quotes,
/// code blocks and lists look the same while editing and while previewing.
/// Every `flutter_markdown_plus` extension point is forwarded through
/// [builders] and [styleSheet].
class MarkdownPreview extends StatelessWidget {
  /// Creates a Markdown preview.
  const MarkdownPreview({
    super.key,
    required this.data,
    this.controller,
    this.theme,
    this.builders = const MarkdownEditorBuilders(),
    this.styleSheet,
    this.padding = const EdgeInsets.all(12),
    this.selectable = true,
    this.scrollable = true,
    this.scrollController,
    this.shrinkWrap = true,
    this.softLineBreak = true,
    this.onTapLink,
  });

  /// The Markdown source to render.
  final String data;

  /// The controller the source came from, if any.
  ///
  /// When provided, taps on links are handled through
  /// `MarkdownEditorActions`-style callbacks and commands can be executed from
  /// custom preview widgets.
  final MarkdownEditorController? controller;

  /// Overrides the theme from the surrounding scope.
  final MarkdownEditorTheme? theme;

  /// The preview builders.
  final MarkdownEditorBuilders builders;

  /// An explicit style sheet merged over the theme derived sheet.
  final MarkdownStyleSheet? styleSheet;

  /// Padding around the rendered document.
  final EdgeInsets padding;

  /// Whether the rendered text is selectable.
  final bool selectable;

  /// Whether the preview scrolls internally. When `false` it expands in its
  /// parent, which is useful inside a [CustomScrollView].
  final bool scrollable;

  /// An optional scroll controller for the preview.
  final ScrollController? scrollController;

  /// Whether the rendered document wraps its content.
  final bool shrinkWrap;

  /// Whether soft line breaks are preserved.
  final bool softLineBreak;

  /// Called when a link is tapped.
  final void Function(String text, String? href, String title)? onTapLink;

  @override
  Widget build(BuildContext context) {
    final MarkdownEditorTheme editorTheme =
        theme ?? MarkdownEditorScope.maybeOf(context)?.theme ?? MarkdownEditorTheme.fallback(context);
    MarkdownStyleSheet sheet = editorTheme.toMarkdownStyleSheet();
    sheet = mergeMarkdownStyleSheets(sheet, builders.previewStyleSheet);
    sheet = mergeMarkdownStyleSheets(sheet, styleSheet);
    final MarkdownStyleSheet finalSheet = sheet;

    final MarkdownBody body = MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: finalSheet,
      onTapLink: onTapLink,
      builders: _elementBuilders(),
      paddingBuilders: builders.paddingBuilders,
      imageBuilder: builders.imageBuilder == null
          ? null
          : (Uri uri, String? title, String? alt) => builders.imageBuilder!(
                context,
                MarkdownImageContext(uri: uri, alt: alt, title: title),
              ),
      checkboxBuilder: builders.checkboxBuilder == null
          ? null
          : (bool value) => builders.checkboxBuilder!(context, value),
      bulletBuilder: builders.bulletBuilder == null
          ? null
          : (MarkdownBulletParameters parameters) => builders.bulletBuilder!(
                context,
                MarkdownBulletContext(
                  index: parameters.index,
                  nestLevel: parameters.nestLevel,
                  ordered: parameters.style == BulletStyle.orderedList,
                ),
              ),
      syntaxHighlighter: builders.syntaxHighlighter,
      inlineSyntaxes: builders.inlineSyntaxes,
      blockSyntaxes: builders.blockSyntaxes,
      extensionSet: builders.extensionSet,
      softLineBreak: softLineBreak,
      shrinkWrap: shrinkWrap,
    );

    if (!scrollable) {
      return Padding(padding: padding, child: body);
    }
    return SingleChildScrollView(
      controller: scrollController,
      padding: padding,
      child: body,
    );
  }

  Map<String, MarkdownElementBuilder> _elementBuilders() {
    final Map<String, MarkdownElementBuilder> result =
        Map<String, MarkdownElementBuilder>.of(builders.elementBuilders);
    final MarkdownCodeBlockBuilder? codeBlockBuilder = builders.codeBlockBuilder;
    if (codeBlockBuilder != null && !result.containsKey('pre')) {
      result['pre'] = _CodeBlockElementBuilder(builder: codeBlockBuilder);
    }
    return result;
  }
}

/// Adapts a [MarkdownCodeBlockBuilder] to a `flutter_markdown_plus` element
/// builder for `pre` elements.
class _CodeBlockElementBuilder extends MarkdownElementBuilder {
  _CodeBlockElementBuilder({required this.builder});

  final MarkdownCodeBlockBuilder builder;
  String? _language;

  @override
  bool isBlockElement() => true;

  @override
  void visitElementBefore(md.Element element) {
    _language = _languageOf(element);
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return builder(
      context,
      MarkdownCodeBlockContext(
        code: element.textContent.replaceFirst(RegExp(r'\n$'), ''),
        language: _language,
      ),
    );
  }

  static String? _languageOf(md.Element element) {
    for (final md.Node child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        final String? classes = child.attributes['class'];
        if (classes == null || classes.isEmpty) {
          return null;
        }
        for (final String part in classes.split(' ')) {
          if (part.startsWith('language-')) {
            return part.substring('language-'.length);
          }
        }
      }
    }
    return null;
  }
}
