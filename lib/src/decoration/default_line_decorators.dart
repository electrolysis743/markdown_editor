import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../model/markdown_block.dart';
import '../model/markdown_line_info.dart';
import '../theme/markdown_editor_theme.dart';
import '../theme/marker_visibility.dart';
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

/// Paints list bullets and ordered numbers in the
/// [MarkdownMarkerVisibility.hiddenExceptActiveLine] display mode.
///
/// In that mode the source markers of inactive lines are transparent but keep
/// their width, so the rendered marker can be drawn exactly over them and the
/// text stays where the rendered output puts it.
class ListMarkerDecorator extends MarkdownLineDecorator {
  /// Creates the decorator.
  const ListMarkerDecorator({this.bullet = '\u2022'});

  /// The glyph painted for bullet list items.
  final String bullet;

  @override
  void paint(MarkdownDecorationContext context) {
    if (!context.showSyntax ||
        context.theme.markerVisibility !=
            MarkdownMarkerVisibility.hiddenExceptActiveLine) {
      return;
    }
    for (final MarkdownLineBox box in context.lineBoxes) {
      final MarkdownLineInfo line = box.line;
      if (context.isActiveLine(line)) {
        continue;
      }
      final TextStyle style =
          _markerStyle(context, context.theme.listMarker);
      if (line.kind == MarkdownLineKind.bulletList) {
        _paintGlyph(context, box, bullet, style, alignEnd: false);
      } else if (line.kind == MarkdownLineKind.orderedList) {
        _paintGlyph(context, box, line.listMarker, style, alignEnd: true);
      }
    }
  }
}

/// Paints task list checkboxes in the
/// [MarkdownMarkerVisibility.hiddenExceptActiveLine] display mode.
///
/// The `[x]` / `[ ]` characters of inactive lines stay transparent, so the
/// checkbox appears exactly where the rendered output shows it. The same
/// Material icons the preview uses are painted, so both panes agree.
class TaskListDecorator extends MarkdownLineDecorator {
  /// Creates the decorator.
  const TaskListDecorator({
    this.checkedIcon = Icons.check_box,
    this.uncheckedIcon = Icons.check_box_outline_blank,
  });

  /// The icon painted for a checked task.
  final IconData checkedIcon;

  /// The icon painted for an unchecked task.
  final IconData uncheckedIcon;

  @override
  void paint(MarkdownDecorationContext context) {
    if (!context.showSyntax ||
        context.theme.markerVisibility !=
            MarkdownMarkerVisibility.hiddenExceptActiveLine) {
      return;
    }
    for (final MarkdownLineBox box in context.lineBoxes) {
      final MarkdownLineInfo line = box.line;
      if (line.kind != MarkdownLineKind.taskList ||
          context.isActiveLine(line)) {
        continue;
      }
      final int bracket = line.text.indexOf('[');
      if (bracket < 0) {
        continue;
      }
      final IconData icon = line.taskChecked ? checkedIcon : uncheckedIcon;
      _paintGlyph(
        context,
        box,
        String.fromCharCode(icon.codePoint),
        _iconStyle(context, icon),
        alignEnd: false,
        from: line.start + bracket,
        to: line.start + bracket + 3,
      );
    }
  }
}

/// The style that paints a Material icon glyph like an `Icon` widget would.
TextStyle _iconStyle(MarkdownDecorationContext context, IconData icon) {
  final TextStyle text = context.baseStyle.merge(context.theme.checkbox);
  return TextStyle(
    inherit: false,
    fontFamily: icon.fontFamily,
    package: icon.fontPackage,
    fontSize: context.theme.checkbox?.fontSize ?? text.fontSize ?? 14,
    color: text.color ?? const Color(0xFF000000),
  );
}

/// The style used to paint replacement markers: the document base style plus
/// the token style, with a guaranteed paint color.
TextStyle _markerStyle(
  MarkdownDecorationContext context,
  TextStyle? token,
) {
  final TextStyle style = context.baseStyle.merge(token);
  if (style.color != null) {
    return style;
  }
  return style.copyWith(
    color: context.theme.body?.color ?? const Color(0xFF000000),
  );
}

/// Paints [glyph] centered in the marker area of [box], or right aligned to the
/// content start when [alignEnd] is set.
void _paintGlyph(
  MarkdownDecorationContext context,
  MarkdownLineBox box,
  String glyph,
  TextStyle style, {
  required bool alignEnd,
  int? from,
  int? to,
}) {
  if (glyph.isEmpty) {
    return;
  }
  final MarkdownLineInfo line = box.line;
  final double left = context.caretX(from ?? line.start);
  final double right = context.caretX(to ?? line.contentOffset);
  if (right <= left) {
    return;
  }
  final TextPainter painter = TextPainter(
    text: TextSpan(text: glyph, style: style),
    textDirection: context.textDirection,
    textScaler: context.textScaler,
  )..layout();
  final double x = alignEnd
      ? right - painter.width - (style.fontSize ?? 4) * 0.3
      : left + (right - left - painter.width) / 2;
  final double y = (box.rect.top + box.rect.bottom - painter.height) / 2;
  painter.paint(context.canvas, Offset(x, y));
  painter.dispose();
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
  ListMarkerDecorator(),
  TaskListDecorator(),
];
