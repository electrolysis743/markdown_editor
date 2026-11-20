import 'package:flutter/material.dart';

import 'commands/markdown_commands.dart';
import 'controller/markdown_editor_controller.dart';
import 'editor/markdown_editor_builders.dart';
import 'editor/markdown_editor_extensions.dart';
import 'editor/markdown_editor_scope.dart';
import 'markdown_editor_mode.dart';
import 'theme/markdown_editor_theme.dart';
import 'toolbar/markdown_toolbar.dart';
import 'widgets/markdown_editor_shortcuts.dart';
import 'widgets/markdown_editing_surface.dart';
import 'widgets/markdown_preview.dart';

/// An extensible WYSIWYG Markdown editor.
///
/// The editor keeps the document as plain Markdown source while rendering it
/// richly: headings, emphasis, links, inline code, fenced code blocks, quotes,
/// lists and tables are styled in place, and block decorations are painted
/// behind the text. A live preview rendered by `flutter_markdown_plus` shares
/// the same theme.
///
/// Every part is replaceable:
///
/// * [theme] styles every token; a partial theme keeps the defaults.
/// * [extensions] replaces the parser, the span engine or the inline rules.
/// * [builders] replaces the toolbar, surface, preview, empty state, code
///   blocks, images and adds `flutter_markdown_plus` element builders.
/// * [toolbar] controls the built-in toolbar and its items.
/// * [shortcutBindings] remaps the keyboard shortcuts.
///
/// ```dart
/// final MarkdownEditorController controller =
///     MarkdownEditorController(text: '# Hello');
///
/// @override
/// Widget build(BuildContext context) {
///   return Scaffold(
///     body: MarkdownEditor(
///       controller: controller,
///       mode: MarkdownEditorMode.split,
///       onChanged: (String markdown) => debugPrint(markdown),
///       theme: const MarkdownEditorTheme(
///         heading1: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
///       ),
///     ),
///   );
/// }
/// ```
class MarkdownEditor extends StatefulWidget {
  /// Creates a Markdown editor.
  const MarkdownEditor({
    super.key,
    this.controller,
    this.initialValue = '',
    this.onChanged,
    this.mode = MarkdownEditorMode.wysiwyg,
    this.theme = const MarkdownEditorTheme(),
    this.extensions = const MarkdownEditorExtensions(),
    this.builders = const MarkdownEditorBuilders(),
    this.toolbar = const MarkdownToolbarConfig(),
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.enableShortcuts = true,
    this.enableTabIndentation = false,
    this.shortcutBindings,
    this.hintText,
    this.onTapLink,
    this.onFocusChange,
    this.splitDirection = Axis.horizontal,
    this.splitRatio = 0.5,
    this.previewScrollController,
    this.padding,
    this.semanticsLabel,
  });

  /// The controller holding the document. When omitted the editor creates and
  /// owns one initialized with [initialValue].
  final MarkdownEditorController? controller;

  /// The initial document used when [controller] is `null`.
  final String initialValue;

  /// Called with the Markdown source whenever it changes.
  final ValueChanged<String>? onChanged;

  /// The layout mode.
  final MarkdownEditorMode mode;

  /// The theme. Missing fields fall back to the ambient Material theme.
  final MarkdownEditorTheme theme;

  /// The parsing and rendering pipeline extensions.
  final MarkdownEditorExtensions extensions;

  /// The replaceable widgets of the editor.
  final MarkdownEditorBuilders builders;

  /// The toolbar configuration.
  final MarkdownToolbarConfig toolbar;

  /// An optional focus node for the editing surface.
  final FocusNode? focusNode;

  /// Whether the surface requests focus when first built.
  final bool autofocus;

  /// Whether the document can be edited.
  final bool readOnly;

  /// Whether the default keyboard shortcuts are installed.
  final bool enableShortcuts;

  /// Whether Tab and Shift+Tab indent list items instead of moving focus.
  final bool enableTabIndentation;

  /// Replaces the default keyboard bindings.
  final Map<ShortcutActivator, MarkdownCommand>? shortcutBindings;

  /// Hint shown while the document is empty. Defaults to a built-in hint.
  final String? hintText;

  /// Called when a link in the preview is tapped.
  final void Function(BuildContext context, String text, String? href, String title)?
      onTapLink;

  /// Called when the editing surface gains or loses focus.
  final ValueChanged<bool>? onFocusChange;

  /// The direction of the split in [MarkdownEditorMode.split].
  final Axis splitDirection;

  /// The fraction of the split occupied by the editor (`0` to `1`).
  final double splitRatio;

  /// An optional scroll controller for the preview pane.
  final ScrollController? previewScrollController;

  /// Overrides the theme padding of the editing surface.
  final EdgeInsets? padding;

  /// An accessibility label for the whole editor.
  final String? semanticsLabel;

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late MarkdownEditorController _controller;
  late bool _ownsController;
  FocusNode? _ownedFocusNode;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ??
        MarkdownEditorController(text: widget.initialValue);
    _controller.addListener(_handleTextChanged);
    _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode = widget.focusNode ?? _ownedFocusNode!;
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleTextChanged);
      if (_ownsController) {
        _controller.dispose();
      }
      _ownsController = widget.controller == null;
      _controller =
          widget.controller ?? MarkdownEditorController(text: widget.initialValue);
      _controller.addListener(_handleTextChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChanged);
      _ownedFocusNode?.dispose();
      _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
      _focusNode = widget.focusNode ?? _ownedFocusNode!;
      _focusNode.addListener(_handleFocusChanged);
    }
    if (oldWidget.autofocus != widget.autofocus &&
        widget.autofocus &&
        !_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    widget.onChanged?.call(_controller.text);
  }

  void _handleFocusChanged() {
    widget.onFocusChange?.call(_focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final MarkdownEditorTheme theme = widget.theme.resolve(context);
    final Widget content = MarkdownEditorScope(
      theme: theme,
      extensions: widget.extensions,
      child: Builder(
        builder: (BuildContext context) {
          final Widget body = _buildBody(context, theme);
          return Semantics(
            label: widget.semanticsLabel,
            child: body,
          );
        },
      ),
    );
    return content;
  }

  Widget _buildBody(BuildContext context, MarkdownEditorTheme theme) {
    final bool showToolbar = widget.toolbar.visible &&
        widget.mode != MarkdownEditorMode.preview;
    final Widget? statusBar = widget.builders.statusBarBuilder?.call(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showToolbar) _buildToolbar(context, theme),
        Expanded(child: _buildContent(context, theme)),
        if (statusBar != null) statusBar,
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, MarkdownEditorTheme theme) {
    final MarkdownToolbarConfig config = widget.toolbar;
    final List<MarkdownToolbarItem> items =
        config.items ?? defaultMarkdownToolbarItems();
    final MarkdownToolbarContext toolbarContext = MarkdownToolbarContext(
      controller: _controller,
      items: items,
      theme: theme,
      toolbarTheme: config.theme,
      axis: config.axis,
    );
    final MarkdownToolbarBuilder? builder = widget.builders.toolbarBuilder;
    if (builder != null) {
      return builder(context, toolbarContext);
    }
    return MarkdownToolbar(
      controller: _controller,
      items: items,
      theme: theme,
      toolbarTheme: config.theme,
      axis: config.axis,
      wrap: config.wrap,
      itemBuilder: config.itemBuilder,
    );
  }

  Widget _buildContent(BuildContext context, MarkdownEditorTheme theme) {
    switch (widget.mode) {
      case MarkdownEditorMode.preview:
        return _buildPreview(context, theme);
      case MarkdownEditorMode.wysiwyg:
      case MarkdownEditorMode.source:
        return _buildSurface(context, theme);
      case MarkdownEditorMode.split:
        final int primary = (widget.splitRatio.clamp(0.05, 0.95) * 1000).round();
        final Widget divider = widget.builders.dividerBuilder?.call(context) ??
            (widget.splitDirection == Axis.horizontal
                ? const VerticalDivider(width: 1, thickness: 1)
                : const Divider(height: 1, thickness: 1));
        return Flex(
          direction: widget.splitDirection,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(flex: primary, child: _buildSurface(context, theme)),
            divider,
            Expanded(flex: 1000 - primary, child: _buildPreview(context, theme)),
          ],
        );
    }
  }

  Widget _buildSurface(BuildContext context, MarkdownEditorTheme theme) {
    final MarkdownEditingSurfaceContext surfaceContext =
        MarkdownEditingSurfaceContext(
      controller: _controller,
      theme: theme,
      readOnly: widget.readOnly,
    );
    final MarkdownEditingSurfaceBuilder? builder =
        widget.builders.editingSurfaceBuilder;
    final Widget surface = builder != null
        ? builder(context, surfaceContext)
        : MarkdownEditingSurface(
            controller: _controller,
            focusNode: _focusNode,
            theme: theme,
            extensions: widget.extensions,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            hintText: widget.hintText ?? 'Start writing Markdown…',
            emptyStateBuilder: widget.builders.emptyStateBuilder,
            contextMenuBuilder: widget.builders.contextMenuBuilder,
            showSyntax: widget.mode != MarkdownEditorMode.source,
            padding: widget.padding,
          );
    if (!widget.enableShortcuts || widget.readOnly) {
      return surface;
    }
    return MarkdownEditorShortcuts(
      controller: _controller,
      theme: theme,
      enabled: true,
      bindings: widget.shortcutBindings,
      enableTabIndentation: widget.enableTabIndentation,
      child: surface,
    );
  }

  Widget _buildPreview(BuildContext context, MarkdownEditorTheme theme) {
    final MarkdownPreviewContext previewContext = MarkdownPreviewContext(
      controller: _controller,
      theme: theme,
      builders: widget.builders,
      scrollController: widget.previewScrollController,
    );
    final MarkdownPreviewBuilder? builder = widget.builders.previewBuilder;
    if (builder != null) {
      return ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? child) =>
            builder(context, previewContext),
      );
    }
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, Widget? child) {
        return MarkdownPreview(
          data: _controller.text,
          controller: _controller,
          theme: theme,
          builders: widget.builders,
          scrollController: widget.previewScrollController,
          padding: theme.padding,
          onTapLink: widget.onTapLink == null
              ? null
              : (String text, String? href, String title) =>
                  widget.onTapLink!(context, text, href, title),
        );
      },
    );
  }
}
