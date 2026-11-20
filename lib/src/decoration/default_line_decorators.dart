import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model/markdown_block.dart';
import '../model/markdown_line_info.dart';
import '../theme/markdown_editor_theme.dart';
import 'markdown_line_decorator.dart';

/// Paints the background and the vertical bar of block quotes.
class BlockquoteLineDecorator extends MarkdownLineDecorator {
  /// Creates the decorator.
  const BlockquoteLineDecorator({this.radius = 4});

  /// The corner radius of the quote background.
  final double radius;

  @override
  void paint(MarkdownDecorationContext context) {
    final MarkdownEditorTheme theme = context.theme;
    final Color? background = theme.quoteColor;
    final Color? barColor = theme.quoteBarColor;
    if (background == null && barColor == null) {
      return;
    }
    final Paint backgroundPaint = Paint()..color = background ?? Colors.transparent;
    final Paint barPaint = Paint()..color = barColor ?? Colors.transparent;

    for (final MarkdownBlockBox box in context.blockBoxes) {
      if (box.block.kind != MarkdownBlockKind.quote) {
        continue;
      }
      final Rect rect = box.rect;
      if (rect.height <= 0) {
        continue;
      }
      if (background != null) {
        context.canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom),
            Radius.circular(radius),
          ),
          backgroundPaint,
        );
      }
      if (barColor != null) {
        for (int depth = 1; depth <= box.block.quoteDepth; depth++) {
          final double left =
              rect.left + (depth - 1) * theme.listIndent + 1;
          context.canvas.drawRect(
            Rect.fromLTWH(
              left,
              rect.top,
              theme.quoteBarWidth,
              rect.height,
            ),
            barPaint,
          );
        }
      }
    }
  }
}

/// Paints the rounded background of fenced code blocks.
class FencedCodeBlockDecorator extends MarkdownLineDecorator {
  /// Creates the decorator.
  const FencedCodeBlockDecorator({this.radius = 6});

  /// The corner radius of the background.
  final double radius;

  @override
  void paint(MarkdownDecorationContext context) {
    final Color? color = context.theme.codeBlockColor;
    if (color == null) {
      return;
    }
    final Paint paint = Paint()..color = color;
    for (final MarkdownBlockBox box in context.blockBoxes) {
      if (box.block.kind != MarkdownBlockKind.fencedCode) {
        continue;
      }
      final Rect rect = box.rect;
      if (rect.height <= 0) {
        continue;
      }
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            rect.left,
            rect.top + 1,
            math.max(rect.right, context.size.width),
            rect.bottom - 1,
          ),
          Radius.circular(radius),
        ),
        paint,
      );
    }
  }
}

/// Paints the line of a thematic break.
///
/// When `MarkdownEditorTheme.paintHorizontalRule` is `true` (the default) the
/// dashes of `---` are rendered transparently by the span engine and only this
/// painted line is visible. Set it to `false` to keep the literal syntax.
class HorizontalRuleDecorator extends MarkdownLineDecorator {
  /// Creates the decorator.
  const HorizontalRuleDecorator();

  @override
  void paint(MarkdownDecorationContext context) {
    if (!context.theme.paintHorizontalRule) {
      return;
    }
    final Color color =
        context.theme.horizontalRuleColor ?? const Color(0x33000000);
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (final MarkdownLineBox box in context.lineBoxes) {
      if (box.line.kind != MarkdownLineKind.horizontalRule) {
        continue;
      }
      final double y = (box.rect.top + box.rect.bottom) / 2;
      context.canvas.drawLine(
        Offset(box.rect.left, y),
        Offset(math.max(box.rect.right, context.size.width), y),
        paint,
      );
    }
  }
}

/// Paints a subtle vertical guide for list indentation.
///
/// This decorator is not enabled by default; add it through
/// `MarkdownEditorExtensions.lineDecorators` when you want list guides.
class ListGuideDecorator extends MarkdownLineDecorator {
  /// Creates the decorator.
  const ListGuideDecorator({
    this.color = const Color(0x14000000),
    this.width = 2,
    this.indent = 4,
  });

  /// The color of the guide.
  final Color color;

  /// The width of the guide in logical pixels.
  final double width;

  /// The horizontal offset from the line start.
  final double indent;

  @override
  void paint(MarkdownDecorationContext context) {
    final Paint paint = Paint()..color = color;
    for (final MarkdownLineBox box in context.lineBoxes) {
      final MarkdownLineInfo line = box.line;
      if (line.kind != MarkdownLineKind.bulletList &&
          line.kind != MarkdownLineKind.orderedList &&
          line.kind != MarkdownLineKind.taskList) {
        continue;
      }
      if (line.listIndent <= 0) {
        continue;
      }
      final double x = box.rect.left + indent;
      context.canvas.drawRect(
        Rect.fromLTWH(x, box.rect.top, width, box.rect.height),
        paint,
      );
    }
  }
}

/// A debug decorator that paints the box of every line and block.
///
/// Useful while building custom decorators or diagnosing alignment.
class DebugDecorationDecorator extends MarkdownLineDecorator {
  /// Creates the decorator.
  const DebugDecorationDecorator({
    this.lineColor = const Color(0x3300E676),
    this.blockColor = const Color(0x33FF5252),
  });

  /// Color used for line boxes.
  final Color lineColor;

  /// Color used for block boxes.
  final Color blockColor;

  @override
  void paint(MarkdownDecorationContext context) {
    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke;
    final Paint blockPaint = Paint()
      ..color = blockColor
      ..style = PaintingStyle.stroke;
    for (final MarkdownLineBox box in context.lineBoxes) {
      context.canvas.drawRect(box.rect, linePaint);
    }
    for (final MarkdownBlockBox box in context.blockBoxes) {
      context.canvas.drawRect(box.rect, blockPaint);
    }
  }
}

/// The decorators enabled by default.
const List<MarkdownLineDecorator> kDefaultLineDecorators =
    <MarkdownLineDecorator>[
  FencedCodeBlockDecorator(),
  BlockquoteLineDecorator(),
  HorizontalRuleDecorator(),
];
