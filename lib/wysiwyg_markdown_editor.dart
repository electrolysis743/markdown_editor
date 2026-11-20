/// An extensible, WYSIWYG Markdown editor for Flutter.
///
/// The editor is built on top of `flutter_markdown_plus`: the preview uses its
/// renderer, and the editing surface reuses its `MarkdownStyleSheet` vocabulary
/// so editing and previewing look the same.
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';
///
/// void main() => runApp(const MaterialApp(home: EditorPage()));
///
/// class EditorPage extends StatefulWidget {
///   const EditorPage({super.key});
///
///   @override
///   State<EditorPage> createState() => _EditorPageState();
/// }
///
/// class _EditorPageState extends State<EditorPage> {
///   final MarkdownEditorController controller =
///       MarkdownEditorController(text: '# Hello Markdown');
///
///   @override
///   void dispose() {
///     controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: const Text('markdown_editor')),
///       body: MarkdownEditor(
///         controller: controller,
///         mode: MarkdownEditorMode.split,
///       ),
///     );
///   }
/// }
/// ```
library;

export 'package:flutter_markdown_plus/flutter_markdown_plus.dart'
    show
        BulletStyle,
        Markdown,
        MarkdownBody,
        MarkdownBulletParameters,
        MarkdownElementBuilder,
        MarkdownListItemCrossAxisAlignment,
        MarkdownPaddingBuilder,
        MarkdownStyleSheet,
        MarkdownStyleSheetBaseTheme,
        SyntaxHighlighter;

export 'src/analysis/default_inline_rules.dart';
export 'src/analysis/default_line_analyzer.dart';
export 'src/analysis/markdown_inline_rule.dart';
export 'src/analysis/markdown_span_engine.dart';
export 'src/analysis/markdown_token_type.dart';
export 'src/commands/markdown_commands.dart';
export 'src/controller/markdown_editor_controller.dart';
export 'src/controller/markdown_history.dart';
export 'src/decoration/default_line_decorators.dart';
export 'src/decoration/markdown_decoration_painter.dart';
export 'src/decoration/markdown_line_decorator.dart';
export 'src/editor/markdown_editor_builders.dart';
export 'src/editor/markdown_editor_extensions.dart';
export 'src/editor/markdown_editor_scope.dart';
export 'src/markdown_editor.dart';
export 'src/markdown_editor_mode.dart';
export 'src/model/markdown_block.dart';
export 'src/model/markdown_document_layout.dart';
export 'src/model/markdown_line_info.dart';
export 'src/theme/marker_visibility.dart';
export 'src/theme/markdown_editor_theme.dart';
export 'src/toolbar/markdown_toolbar.dart';
export 'src/widgets/markdown_editor_shortcuts.dart';
export 'src/widgets/markdown_editing_surface.dart';
export 'src/widgets/markdown_preview.dart';
