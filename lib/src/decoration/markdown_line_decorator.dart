import 'package:flutter/material.dart';

import '../model/markdown_block.dart';
import '../model/markdown_document_layout.dart';
import '../model/markdown_line_info.dart';
import '../theme/markdown_editor_theme.dart';

/// The on-screen geometry of one source line, in the coordinate space of the
/// editing surface.
@immutable
class MarkdownLineBox {
  /// Creates a line box.
  const MarkdownLineBox({required this.line, required this.rect});

  /// The source line this box describes.
  final MarkdownLineInfo line;

  /// The rectangle occupied by the line, including the space taken by
  /// Markdown markers.
  final Rect rect;

  @override
  String toString() => 'MarkdownLineBox(${line.index}, $rect)';
}

/// The on-screen geometry of one block, computed from its line boxes.
@immutable
class MarkdownBlockBox {
  /// Creates a block box.
  const MarkdownBlockBox({required this.block, required this.rect});

  /// The block this box describes.
  final MarkdownBlock block;

  /// The rectangle covering all lines of the block.
  final Rect rect;

  @override
  String toString() => 'MarkdownBlockBox(${block.kind.name}, $rect)';
}

/// Everything a [MarkdownLineDecorator] needs to paint.
class MarkdownDecorationContext {
  /// Creates a decoration context.
  MarkdownDecorationContext({
    required this.canvas,
    required this.theme,
    required this.layout,
    required this.lineBoxes,
    required this.blockBoxes,
    required this.size,
    required this.textDirection,
  });

  /// The canvas to paint on.
  final Canvas canvas;

  /// The active editor theme.
  final MarkdownEditorTheme theme;

  /// The parsed layout.
  final MarkdownDocumentLayout layout;

  /// The geometry of every visible line, in painting order.
  final List<MarkdownLineBox> lineBoxes;

  /// The geometry of every visible block.
  final List<MarkdownBlockBox> blockBoxes;

  /// The size of the painted area (excluding the editor padding).
  final Size size;

  /// The text direction of the document.
  final TextDirection textDirection;

  /// Returns the line box at [lineIndex], or `null` when it is not painted.
  MarkdownLineBox? lineBoxAt(int lineIndex) {
    for (final MarkdownLineBox box in lineBoxes) {
      if (box.line.index == lineIndex) {
        return box;
      }
    }
    return null;
  }

  /// Returns the block box whose block contains [lineIndex], or `null`.
  MarkdownBlockBox? blockBoxForLine(int lineIndex) {
    for (final MarkdownBlockBox box in blockBoxes) {
      if (box.block.containsLine(lineIndex)) {
        return box;
      }
    }
    return null;
  }

  /// The horizontal start of the text, respecting [textDirection].
  double get textLeft => textDirection == TextDirection.rtl ? size.width : 0;

  /// The horizontal end of the text, respecting [textDirection].
  double get textRight => textDirection == TextDirection.rtl ? 0 : size.width;
}

/// Paints decoration behind the text of the editing surface.
///
/// Decorators receive precise line and block geometry measured from the same
/// spans the editor renders, so decorations stay aligned while the document
/// scrolls or grows. They must not paint above the text contrast: they are
/// rendered behind the editable text.
///
/// ```dart
/// class ListGuideDecorator extends MarkdownLineDecorator {
///   const ListGuideDecorator();
///
///   @override
///   void paint(MarkdownDecorationContext context) {
///     final Paint paint = Paint()..color = const Color(0x14000000);
///     for (final MarkdownLineBox box in context.lineBoxes) {
///       if (box.line.kind == MarkdownLineKind.bulletList) {
///         final double x = box.rect.left + 6;
///         context.canvas.drawRect(
///           Rect.fromLTRB(x, box.rect.top, x + 2, box.rect.bottom),
///           paint,
///         );
///       }
///     }
///   }
/// }
/// ```
abstract class MarkdownLineDecorator {
  /// Const constructor for stateless decorators.
  const MarkdownLineDecorator();

  /// Paints this decoration.
  void paint(MarkdownDecorationContext context);
}
