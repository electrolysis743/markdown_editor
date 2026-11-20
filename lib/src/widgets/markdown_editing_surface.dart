import 'package:flutter/material.dart';

import '../controller/markdown_editor_controller.dart';
import '../decoration/markdown_decoration_painter.dart';
import '../editor/markdown_editor_builders.dart';
import '../editor/markdown_editor_extensions.dart';
import '../editor/markdown_editor_scope.dart';
import '../theme/markdown_editor_theme.dart';

/// The editable WYSIWYG surface.
///
/// It renders a [TextField] whose spans are produced by
/// `MarkdownEditorController.buildTextSpan`, and paints block decorations
/// (code backgrounds, quote bars, rules) behind the text on a separate layer.
///
/// The surface is public so applications can embed it directly or wrap it with
/// their own chrome. `MarkdownEditor` uses it for the editable half of every
/// mode.
class MarkdownEditingSurface extends StatefulWidget {
  /// Creates an editing surface.
  const MarkdownEditingSurface({
    super.key,
    required this.controller,
    this.focusNode,
    this.scrollController,
    this.theme,
    this.extensions,
    this.readOnly = false,
    this.autofocus = false,
    this.hintText,
    this.emptyStateBuilder,
    this.contextMenuBuilder,
    this.showDecorations = true,
    this.showSyntax = true,
    this.textAlign = TextAlign.start,
    this.padding,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.smartDashesType = SmartDashesType.disabled,
    this.smartQuotesType = SmartQuotesType.disabled,
    this.onTap,
  });

  /// The controller that holds the Markdown source.
  final MarkdownEditorController controller;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// An optional scroll controller for the inner text viewport.
  final ScrollController? scrollController;

  /// Overrides the theme from the surrounding [MarkdownEditorScope].
  final MarkdownEditorTheme? theme;

  /// Overrides the extension set from the surrounding [MarkdownEditorScope].
  final MarkdownEditorExtensions? extensions;

  /// Whether the document can be edited.
  final bool readOnly;

  /// Whether the surface grabs focus when it is first built.
  final bool autofocus;

  /// Hint shown while the document is empty.
  final String? hintText;

  /// Replaces the hint with a custom empty state widget.
  final MarkdownEmptyStateBuilder? emptyStateBuilder;

  /// Builds the text selection toolbar.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Whether block decorations are painted behind the text.
  final bool showDecorations;

  /// Whether Markdown syntax is styled. Set to `false` for plain source mode.
  final bool showSyntax;

  /// The alignment of the text.
  final TextAlign textAlign;

  /// Overrides the theme padding.
  final EdgeInsets? padding;

  /// Whether to autocorrect text.
  final bool autocorrect;

  /// Whether to show the platform suggestion bar.
  final bool enableSuggestions;

  /// The smart dashes policy of the field.
  final SmartDashesType smartDashesType;

  /// The smart quotes policy of the field.
  final SmartQuotesType smartQuotesType;

  /// Called when the surface is tapped, instead of focusing the field.
  final VoidCallback? onTap;

  @override
  State<MarkdownEditingSurface> createState() => _MarkdownEditingSurfaceState();
}

class _MarkdownEditingSurfaceState extends State<MarkdownEditingSurface> {
  FocusNode? _ownedFocusNode;
  ScrollController? _ownedScrollController;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  ScrollController get _scrollController =>
      widget.scrollController ?? (_ownedScrollController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    widget.controller.syntaxHighlighting = widget.showSyntax;
  }

  @override
  void didUpdateWidget(MarkdownEditingSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        widget.showSyntax != oldWidget.showSyntax) {
      widget.controller.syntaxHighlighting = widget.showSyntax;
    }
    if (widget.focusNode != oldWidget.focusNode && _ownedFocusNode != null) {
      _ownedFocusNode!.dispose();
      _ownedFocusNode = null;
    }
    if (widget.scrollController != oldWidget.scrollController &&
        _ownedScrollController != null) {
      _ownedScrollController!.dispose();
      _ownedScrollController = null;
    }
  }

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    _ownedScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MarkdownEditorScope? scope = MarkdownEditorScope.maybeOf(context);
    final MarkdownEditorTheme theme =
        widget.theme ?? scope?.theme ?? MarkdownEditorTheme.fallback(context);
    final MarkdownEditorExtensions extensions =
        widget.extensions ?? scope?.extensions ?? const MarkdownEditorExtensions();
    final TextStyle baseStyle = theme.resolveBody(context);
    final EdgeInsets padding = widget.padding ?? theme.padding;
    // An explicit, non-forced strut gives every line at least the body line
    // height while letting larger styles (headings, code) grow their line.
    // The decoration painter receives the same strut so its line boxes match
    // the ones the text field lays out.
    final StrutStyle strutStyle = StrutStyle.fromTextStyle(
      baseStyle,
      forceStrutHeight: false,
    );

    final ThemeData materialTheme = Theme.of(context);
    final TextSelectionThemeData selectionTheme = TextSelectionThemeData(
      cursorColor: theme.cursorColor,
      selectionColor: theme.selectionColor,
      selectionHandleColor: theme.cursorColor,
    );

    return Theme(
      data: materialTheme.copyWith(textSelectionTheme: selectionTheme),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap ?? () => _focusNode.requestFocus(),
        child: Padding(
          padding: padding,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double textWidth = constraints.maxWidth;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: <Widget>[
                  if (widget.showDecorations)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: widget.controller,
                          builder: (BuildContext context, Widget? child) {
                            return CustomPaint(
                              painter: MarkdownDecorationPainter(
                                text: widget.controller.text,
                                layout: widget.controller.layout,
                                theme: theme,
                                extensions: extensions,
                                baseStyle: baseStyle,
                                strutStyle: strutStyle,
                                textScaler: MediaQuery.textScalerOf(context),
                                textDirection: Directionality.of(context),
                                scrollController: _scrollController,
                                textWidth: textWidth,
                                repaint: _scrollController,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    readOnly: widget.readOnly,
                    autofocus: widget.autofocus,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    style: baseStyle,
                    strutStyle: strutStyle,
                    textAlign: widget.textAlign,
                    textDirection: Directionality.of(context),
                    textAlignVertical: TextAlignVertical.top,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: widget.autocorrect,
                    enableSuggestions: widget.enableSuggestions,
                    smartDashesType: widget.smartDashesType,
                    smartQuotesType: widget.smartQuotesType,
                    cursorColor: theme.cursorColor,
                    cursorWidth: 1.6,
                    cursorRadius: const Radius.circular(2),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                    contextMenuBuilder: widget.contextMenuBuilder,
                    scrollPadding: EdgeInsets.zero,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation:
                            Listenable.merge(<Listenable>[
                          widget.controller,
                          _focusNode,
                        ]),
                        builder: (BuildContext context, Widget? child) {
                          if (widget.controller.text.isNotEmpty ||
                              _focusNode.hasFocus) {
                            return const SizedBox.shrink();
                          }
                          final MarkdownEmptyStateBuilder? builder =
                              widget.emptyStateBuilder;
                          if (builder != null) {
                            return builder(context);
                          }
                          final String? hint = widget.hintText;
                          if (hint == null || hint.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              hint,
                              style: theme.hint ??
                                  baseStyle.copyWith(
                                    color: theme.hintColor ??
                                        baseStyle.color?.withValues(alpha: 0.5),
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
