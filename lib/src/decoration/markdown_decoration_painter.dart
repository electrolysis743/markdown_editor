import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../analysis/markdown_span_engine.dart';
import '../editor/markdown_editor_extensions.dart';
import '../model/markdown_block.dart';
import '../model/markdown_document_layout.dart';
import '../model/markdown_line_info.dart';
import '../theme/markdown_editor_theme.dart';
import 'markdown_line_decorator.dart';

/// Paints block decorations behind the editable text.
///
/// The painter lays out exactly the same spans as the editing surface, at the
/// same width, and derives line and block rectangles from that layout. This
/// keeps quote bars, code block backgrounds and rules aligned with the text
/// while the document scrolls, grows or is resized.
///
/// Geometry is cached in unscrolled text coordinates and translated by the
/// current scroll offset on every paint, so scrolling repaints without
/// rebuilding the widget tree.
class MarkdownDecorationPainter extends CustomPainter {
  /// Creates a decoration painter.
  MarkdownDecorationPainter({
    required this.text,
    required this.layout,
    required this.theme,
    required this.extensions,
    required this.baseStyle,
    required this.strutStyle,
    required this.textScaler,
    required this.textDirection,
    required this.scrollController,
    required this.textWidth,
    this.showSyntax = true,
    this.activeLineRange,
    required Listenable repaint,
  }) : super(repaint: repaint);

  /// The document source, which must match the editable text.
  final String text;

  /// The parsed layout of [text].
  final MarkdownDocumentLayout layout;

  /// The active theme.
  final MarkdownEditorTheme theme;

  /// The active extension set, used to build the same spans as the editor.
  final MarkdownEditorExtensions extensions;

  /// The text style of the editing surface.
  final TextStyle baseStyle;

  /// The strut style of the editing surface.
  ///
  /// It must be identical to the one used by the underlying text field,
  /// otherwise line heights, and therefore decorations, would drift.
  final StrutStyle strutStyle;

  /// The text scaler of the editing surface.
  final TextScaler textScaler;

  /// The text direction of the document.
  final TextDirection textDirection;

  /// The vertical scroll controller of the editing surface.
  final ScrollController scrollController;

  /// The width available to the text.
  final double textWidth;

  /// Whether Markdown syntax is styled.
  ///
  /// It must match `MarkdownEditorController.syntaxHighlighting`, otherwise the
  /// decorations would be laid out from spans the text field does not render.
  final bool showSyntax;

  /// The source range of the lines whose syntax markers stay visible.
  ///
  /// It must match the range the editing surface passes to the span engine,
  /// otherwise collapsing markers would change the text layout and the
  /// decorations would drift.
  final TextRange? activeLineRange;

  List<MarkdownLineBox>? _cachedLineBoxes;
  List<MarkdownBlockBox>? _cachedBlockBoxes;
  TextPainter? _cachedPainter;

  double get _scrollOffset =>
      scrollController.hasClients ? scrollController.offset : 0;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.text.isEmpty) {
      return;
    }
    final double offset = _scrollOffset;
    final List<MarkdownLineBox> sourceLineBoxes = _lineBoxes(size);
    final List<MarkdownBlockBox> sourceBlockBoxes = _blockBoxes(sourceLineBoxes, size);

    final List<MarkdownLineBox> lineBoxes = <MarkdownLineBox>[
      for (final MarkdownLineBox box in sourceLineBoxes)
        MarkdownLineBox(
          line: box.line,
          rect: box.rect.translate(0, -offset),
        ),
    ];
    final List<MarkdownBlockBox> blockBoxes = <MarkdownBlockBox>[
      for (final MarkdownBlockBox box in sourceBlockBoxes)
        MarkdownBlockBox(
          block: box.block,
          rect: box.rect.translate(0, -offset),
        ),
    ];

    final MarkdownDecorationContext context = MarkdownDecorationContext(
      canvas: canvas,
      theme: theme,
      layout: layout,
      lineBoxes: lineBoxes,
      blockBoxes: blockBoxes,
      size: size,
      textDirection: textDirection,
      textScaler: textScaler,
      showSyntax: showSyntax,
      baseStyle: baseStyle,
      activeLineRange: activeLineRange,
      caretX: (int offset) {
        final TextPainter? painter = _cachedPainter;
        if (painter == null) {
          return 0;
        }
        return painter
            .getOffsetForCaret(TextPosition(offset: offset), Rect.zero)
            .dx;
      },
    );
    for (final MarkdownLineDecorator decorator in extensions.activeLineDecorators) {
      decorator.paint(context);
    }
  }

  List<MarkdownLineBox> _lineBoxes(Size size) {
    final List<MarkdownLineBox>? cached = _cachedLineBoxes;
    if (cached != null) {
      return cached;
    }
    final TextPainter painter = TextPainter(
      text: extensions.engine.build(
        MarkdownSpanBuildContext(
          text: text,
          layout: layout,
          theme: theme,
          baseStyle: baseStyle,
          rules: extensions.activeInlineRules,
          showSyntax: showSyntax,
          activeLineRange: activeLineRange,
        ),
      ),
      textDirection: textDirection,
      textScaler: textScaler,
      strutStyle: strutStyle,
    );
    painter.layout(maxWidth: textWidth);
    _cachedPainter = painter;

    final List<MarkdownLineInfo> lines = layout.lines;
    final double preferredHeight = painter.preferredLineHeight;
    final List<MarkdownLineBox> boxes = <MarkdownLineBox>[];

    double topFor(int offset) {
      return painter
          .getOffsetForCaret(TextPosition(offset: offset), Rect.zero)
          .dy;
    }

    for (int i = 0; i < lines.length; i++) {
      final MarkdownLineInfo line = lines[i];
      final double top = topFor(line.start);
      double bottom;
      if (i + 1 < lines.length) {
        bottom = topFor(lines[i + 1].start);
      } else {
        final List<TextBox> lastLineBoxes = painter.getBoxesForSelection(
          TextSelection(
            baseOffset: line.start,
            extentOffset: math.max(line.start, line.end),
          ),
        );
        if (lastLineBoxes.isEmpty) {
          bottom = top + preferredHeight;
        } else {
          bottom = lastLineBoxes
              .map((TextBox box) => box.bottom)
              .reduce(math.max);
        }
      }
      if (bottom <= top) {
        bottom = top + preferredHeight;
      }
      boxes.add(
        MarkdownLineBox(
          line: line,
          rect: Rect.fromLTRB(
            0,
            top,
            math.max(textWidth, size.width),
            bottom,
          ),
        ),
      );
    }
    _cachedLineBoxes = boxes;
    return boxes;
  }

  List<MarkdownBlockBox> _blockBoxes(
    List<MarkdownLineBox> lineBoxes,
    Size size,
  ) {
    final List<MarkdownBlockBox>? cached = _cachedBlockBoxes;
    if (cached != null) {
      return cached;
    }
    final Map<int, MarkdownLineBox> byIndex = <int, MarkdownLineBox>{
      for (final MarkdownLineBox box in lineBoxes) box.line.index: box,
    };
    final List<MarkdownBlockBox> boxes = <MarkdownBlockBox>[];
    for (final MarkdownBlock block in layout.blocks) {
      final MarkdownLineBox? first = byIndex[block.startLine];
      final MarkdownLineBox? last = byIndex[block.endLine];
      if (first == null || last == null) {
        continue;
      }
      boxes.add(
        MarkdownBlockBox(
          block: block,
          rect: Rect.fromLTRB(
            0,
            first.rect.top,
            math.max(first.rect.right, size.width),
            last.rect.bottom,
          ),
        ),
      );
    }
    _cachedBlockBoxes = boxes;
    return boxes;
  }

  @override
  bool shouldRepaint(MarkdownDecorationPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.layout != layout ||
        oldDelegate.theme != theme ||
        oldDelegate.extensions != extensions ||
        oldDelegate.baseStyle != baseStyle ||
        oldDelegate.strutStyle != strutStyle ||
        oldDelegate.textScaler != textScaler ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.scrollController != scrollController ||
        oldDelegate.textWidth != textWidth ||
        oldDelegate.showSyntax != showSyntax ||
        oldDelegate.activeLineRange != activeLineRange;
  }
}
