// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../controller/markdown_editor_controller.dart';
import '../theme/markdown_editor_theme.dart';
import '../toolbar/markdown_toolbar.dart';

/// Builds an empty state for the editing surface.
typedef MarkdownEmptyStateBuilder = Widget Function(BuildContext context);

/// Builds a replacement editing surface.
typedef MarkdownEditingSurfaceBuilder = Widget Function(
  BuildContext context,
  MarkdownEditingSurfaceContext surfaceContext,
);

/// Builds a replacement preview.
typedef MarkdownPreviewBuilder = Widget Function(
  BuildContext context,
  MarkdownPreviewContext previewContext,
);

/// Builds the widget used for a fenced code block in the preview.
typedef MarkdownCodeBlockBuilder = Widget Function(
  BuildContext context,
  MarkdownCodeBlockContext codeContext,
);

/// Builds the widget used for an image in the preview.
typedef MarkdownImageBuilder = Widget Function(
  BuildContext context,
  MarkdownImageContext imageContext,
);

/// Builds the widget used for a task list checkbox in the preview.
typedef MarkdownCheckboxBuilder = Widget Function(BuildContext context, bool value);

/// Builds the bullet of a list item in the preview.
typedef MarkdownBulletBuilder = Widget Function(
  BuildContext context,
  MarkdownBulletContext bulletContext,
);

/// Context for [MarkdownCodeBlockBuilder].
class MarkdownCodeBlockContext {
  /// Creates a code block context.
  const MarkdownCodeBlockContext({required this.code, this.language});

  /// The code inside the fence, without the fence lines.
  final String code;

  /// The info string of the fence, for example `dart`.
  final String? language;
}

/// Context for [MarkdownImageBuilder].
class MarkdownImageContext {
  /// Creates an image context.
  const MarkdownImageContext({
    required this.uri,
    this.alt,
    this.title,
  });

  /// The image location.
  final Uri uri;

  /// The alt text.
  final String? alt;

  /// The title attribute.
  final String? title;
}

/// Context for [MarkdownBulletBuilder].
class MarkdownBulletContext {
  /// Creates a bullet context.
  const MarkdownBulletContext({
    required this.index,
    required this.nestLevel,
    required this.ordered,
  });

  /// The index of the bullet within its nesting level.
  final int index;

  /// The nesting level.
  final int nestLevel;

  /// Whether the list is ordered.
  final bool ordered;
}

/// Context for [MarkdownEditingSurfaceBuilder].
class MarkdownEditingSurfaceContext {
  /// Creates a surface context.
  const MarkdownEditingSurfaceContext({
    required this.controller,
    required this.theme,
    required this.readOnly,
  });

  /// The editor controller.
  final MarkdownEditorController controller;

  /// The editor theme.
  final MarkdownEditorTheme theme;

  /// Whether the surface is read-only.
  final bool readOnly;
}

/// Context for [MarkdownPreviewBuilder].
class MarkdownPreviewContext {
  /// Creates a preview context.
  const MarkdownPreviewContext({
    required this.controller,
    required this.theme,
    required this.builders,
    required this.scrollController,
  });

  /// The editor controller holding the source.
  final MarkdownEditorController controller;

  /// The editor theme.
  final MarkdownEditorTheme theme;

  /// The builders the preview would use.
  final MarkdownEditorBuilders builders;

  /// The scroll controller of the preview pane, when it scrolls.
  final ScrollController? scrollController;
}

/// The replaceable widgets of a `MarkdownEditor`.
///
/// Everything the editor draws is reachable from this class. When a builder is
/// `null` the editor uses its built-in widget; when it is set, the builder is
/// responsible for the whole area:
///
/// ```dart
/// MarkdownEditor(
///   builders: MarkdownEditorBuilders(
///     toolbarBuilder: (context, toolbar) => MyToolbar(actions: toolbar.items),
///     codeBlockBuilder: (context, code) => HighlightedCode(code.code),
///   ),
/// )
/// ```
@immutable
class MarkdownEditorBuilders {
  /// Creates a builder set.
  const MarkdownEditorBuilders({
    this.toolbarBuilder,
    this.statusBarBuilder,
    this.editingSurfaceBuilder,
    this.previewBuilder,
    this.emptyStateBuilder,
    this.contextMenuBuilder,
    this.dividerBuilder,
    this.codeBlockBuilder,
    this.imageBuilder,
    this.checkboxBuilder,
    this.bulletBuilder,
    this.elementBuilders = const <String, MarkdownElementBuilder>{},
    this.paddingBuilders = const <String, MarkdownPaddingBuilder>{},
    this.syntaxHighlighter,
    this.inlineSyntaxes,
    this.blockSyntaxes,
    this.extensionSet,
    this.previewStyleSheet,
  });

  /// Replaces the toolbar.
  final MarkdownToolbarBuilder? toolbarBuilder;

  /// Builds a status bar below the editor; when `null` there is no status bar.
  final WidgetBuilder? statusBarBuilder;

  /// Replaces the WYSIWYG editing surface.
  final MarkdownEditingSurfaceBuilder? editingSurfaceBuilder;

  /// Replaces the preview pane.
  final MarkdownPreviewBuilder? previewBuilder;

  /// Builds the widget shown while the document is empty.
  final MarkdownEmptyStateBuilder? emptyStateBuilder;

  /// Builds the text selection toolbar of the editing surface.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Builds the divider between the editor and the preview in split mode.
  final WidgetBuilder? dividerBuilder;

  /// Builds fenced code blocks in the preview.
  final MarkdownCodeBlockBuilder? codeBlockBuilder;

  /// Builds images in the preview.
  final MarkdownImageBuilder? imageBuilder;

  /// Builds task list checkboxes in the preview.
  final MarkdownCheckboxBuilder? checkboxBuilder;

  /// Builds list bullets in the preview.
  final MarkdownBulletBuilder? bulletBuilder;

  /// Extra `flutter_markdown_plus` element builders for the preview, keyed by
  /// tag.
  final Map<String, MarkdownElementBuilder> elementBuilders;

  /// Extra `flutter_markdown_plus` padding builders for the preview.
  final Map<String, MarkdownPaddingBuilder> paddingBuilders;

  /// Highlights code in the preview, when no [codeBlockBuilder] is given.
  final SyntaxHighlighter? syntaxHighlighter;

  /// Extra inline syntaxes for the preview parser.
  final List<md.InlineSyntax>? inlineSyntaxes;

  /// Extra block syntaxes for the preview parser.
  final List<md.BlockSyntax>? blockSyntaxes;

  /// The Markdown extension set used by the preview parser.
  final md.ExtensionSet? extensionSet;

  /// An explicit style sheet for the preview, merged over the theme's sheet.
  final MarkdownStyleSheet? previewStyleSheet;

  /// Returns a copy with the given fields replaced.
  MarkdownEditorBuilders copyWith({
    MarkdownToolbarBuilder? toolbarBuilder,
    WidgetBuilder? statusBarBuilder,
    MarkdownEditingSurfaceBuilder? editingSurfaceBuilder,
    MarkdownPreviewBuilder? previewBuilder,
    MarkdownEmptyStateBuilder? emptyStateBuilder,
    EditableTextContextMenuBuilder? contextMenuBuilder,
    WidgetBuilder? dividerBuilder,
    MarkdownCodeBlockBuilder? codeBlockBuilder,
    MarkdownImageBuilder? imageBuilder,
    MarkdownCheckboxBuilder? checkboxBuilder,
    MarkdownBulletBuilder? bulletBuilder,
    Map<String, MarkdownElementBuilder>? elementBuilders,
    Map<String, MarkdownPaddingBuilder>? paddingBuilders,
    SyntaxHighlighter? syntaxHighlighter,
    List<md.InlineSyntax>? inlineSyntaxes,
    List<md.BlockSyntax>? blockSyntaxes,
    md.ExtensionSet? extensionSet,
    MarkdownStyleSheet? previewStyleSheet,
  }) {
    return MarkdownEditorBuilders(
      toolbarBuilder: toolbarBuilder ?? this.toolbarBuilder,
      statusBarBuilder: statusBarBuilder ?? this.statusBarBuilder,
      editingSurfaceBuilder:
          editingSurfaceBuilder ?? this.editingSurfaceBuilder,
      previewBuilder: previewBuilder ?? this.previewBuilder,
      emptyStateBuilder: emptyStateBuilder ?? this.emptyStateBuilder,
      contextMenuBuilder: contextMenuBuilder ?? this.contextMenuBuilder,
      dividerBuilder: dividerBuilder ?? this.dividerBuilder,
      codeBlockBuilder: codeBlockBuilder ?? this.codeBlockBuilder,
      imageBuilder: imageBuilder ?? this.imageBuilder,
      checkboxBuilder: checkboxBuilder ?? this.checkboxBuilder,
      bulletBuilder: bulletBuilder ?? this.bulletBuilder,
      elementBuilders: elementBuilders ?? this.elementBuilders,
      paddingBuilders: paddingBuilders ?? this.paddingBuilders,
      syntaxHighlighter: syntaxHighlighter ?? this.syntaxHighlighter,
      inlineSyntaxes: inlineSyntaxes ?? this.inlineSyntaxes,
      blockSyntaxes: blockSyntaxes ?? this.blockSyntaxes,
      extensionSet: extensionSet ?? this.extensionSet,
      previewStyleSheet: previewStyleSheet ?? this.previewStyleSheet,
    );
  }
}
