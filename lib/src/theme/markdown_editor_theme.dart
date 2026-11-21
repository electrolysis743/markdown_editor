// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../analysis/markdown_token_type.dart';
import 'marker_visibility.dart';

/// The complete visual definition of a `MarkdownEditor`.
///
/// Every field is optional. When a field is `null` the theme falls back to the
/// surrounding Material [Theme] and to computed defaults, so an application can
/// override a single element (for example only the heading colors) without
/// restating the rest.
///
/// ```dart
/// MarkdownEditor(
///   theme: const MarkdownEditorTheme(
///     heading1: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
///     quoteBarColor: Colors.deepPurple,
///   ),
/// )
/// ```
@immutable
class MarkdownEditorTheme {
  /// Creates an editor theme.
  const MarkdownEditorTheme({
    this.body,
    this.heading1,
    this.heading2,
    this.heading3,
    this.heading4,
    this.heading5,
    this.heading6,
    this.code,
    this.codeBlock,
    this.quote,
    this.link,
    this.linkUrl,
    this.strong,
    this.emphasis,
    this.strikethrough,
    this.highlight,
    this.marker,
    this.listMarker,
    this.checkbox,
    this.hint,
    this.codeBlockColor,
    this.quoteColor,
    this.quoteBarColor,
    this.horizontalRuleColor,
    this.selectionColor,
    this.cursorColor,
    this.hintColor,
    this.padding = const EdgeInsets.all(12),
    this.blockSpacing = 8,
    this.quoteBarWidth = 3,
    this.listIndent = 20,
    this.markerVisibility = MarkdownMarkerVisibility.dimmed,
    this.codeFontFamily = 'monospace',
    this.paintHorizontalRule = true,
    this.previewStyleSheet,
  });

  /// Builds a theme from the ambient Material theme.
  ///
  /// This is what the editor uses when no theme is supplied. It never returns
  /// `null`, and it only reads the [Theme] so it rebuilds correctly when the
  /// surrounding theme changes.
  factory MarkdownEditorTheme.fallback(
    BuildContext context, {
    String codeFontFamily = 'monospace',
  }) {
    final ThemeData material = Theme.of(context);
    final ColorScheme colors = material.colorScheme;
    final TextTheme text = material.textTheme;
    final TextStyle body = (text.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      color: colors.onSurface,
      height: text.bodyMedium?.height ?? 1.5,
    );
    return MarkdownEditorTheme(
      body: body,
      code: TextStyle(
        fontFamily: codeFontFamily,
        fontSize: (body.fontSize ?? 14) * 0.92,
        backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.7),
        color: colors.onSurface,
      ),
      codeBlock: TextStyle(
        fontFamily: codeFontFamily,
        fontSize: (body.fontSize ?? 14) * 0.92,
        height: 1.45,
        color: colors.onSurface,
      ),
      quote: body.copyWith(color: colors.onSurfaceVariant),
      link: body.copyWith(
        color: colors.primary,
        decoration: TextDecoration.underline,
        decorationColor: colors.primary.withValues(alpha: 0.5),
      ),
      codeBlockColor: colors.surfaceContainerHighest.withValues(alpha: 0.6),
      quoteColor: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      quoteBarColor: colors.primary.withValues(alpha: 0.55),
      horizontalRuleColor: colors.outlineVariant,
      selectionColor: colors.primary.withValues(alpha: 0.25),
      cursorColor: colors.primary,
      hintColor: colors.onSurfaceVariant.withValues(alpha: 0.7),
      codeFontFamily: codeFontFamily,
    );
  }

  /// Resolves every `null` field against the ambient Material theme.
  ///
  /// The editor calls this on the theme it is given, so a partially specified
  /// theme keeps the default colors for everything it does not mention.
  MarkdownEditorTheme resolve(BuildContext context) {
    final MarkdownEditorTheme fallback = MarkdownEditorTheme.fallback(
      context,
      codeFontFamily: codeFontFamily,
    );
    return MarkdownEditorTheme(
      body: body ?? fallback.body,
      heading1: heading1,
      heading2: heading2,
      heading3: heading3,
      heading4: heading4,
      heading5: heading5,
      heading6: heading6,
      code: code ?? fallback.code,
      codeBlock: codeBlock ?? fallback.codeBlock,
      quote: quote ?? fallback.quote,
      link: link ?? fallback.link,
      linkUrl: linkUrl ?? fallback.linkUrl,
      strong: strong ?? fallback.strong,
      emphasis: emphasis ?? fallback.emphasis,
      strikethrough: strikethrough ?? fallback.strikethrough,
      highlight: highlight ?? fallback.highlight,
      marker: marker ?? fallback.marker,
      listMarker: listMarker ?? fallback.listMarker,
      checkbox: checkbox ?? fallback.checkbox,
      hint: hint ?? fallback.hint,
      codeBlockColor: codeBlockColor ?? fallback.codeBlockColor,
      quoteColor: quoteColor ?? fallback.quoteColor,
      quoteBarColor: quoteBarColor ?? fallback.quoteBarColor,
      horizontalRuleColor: horizontalRuleColor ?? fallback.horizontalRuleColor,
      selectionColor: selectionColor ?? fallback.selectionColor,
      cursorColor: cursorColor ?? fallback.cursorColor,
      hintColor: hintColor ?? fallback.hintColor,
      padding: padding,
      blockSpacing: blockSpacing,
      quoteBarWidth: quoteBarWidth,
      listIndent: listIndent,
      markerVisibility: markerVisibility,
      codeFontFamily: codeFontFamily,
      paintHorizontalRule: paintHorizontalRule,
      previewStyleSheet: previewStyleSheet,
    );
  }

  /// The base text style of the document, resolved against [context].
  ///
  /// The editor uses this for the editing surface, so a theme that only
  /// overrides colors still inherits the ambient typography.
  ///
  /// Color and line height are always filled in: `TextField` merges its style
  /// over the ambient body typography, and the decoration painter lays out the
  /// same text on its own. Both must agree on them, otherwise the decorations
  /// drift vertically from the text.
  TextStyle resolveBody(BuildContext context) {
    final ThemeData material = Theme.of(context);
    final TextStyle? explicit = body;
    final TextStyle resolved;
    if (explicit != null) {
      resolved = explicit.color != null
          ? explicit
          : explicit.copyWith(color: material.colorScheme.onSurface);
    } else {
      final TextStyle base =
          material.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
      resolved = base.copyWith(color: base.color ?? material.colorScheme.onSurface);
    }
    return resolved.height == null
        ? resolved.copyWith(height: material.textTheme.bodyLarge?.height ?? 1.5)
        : resolved;
  }

  /// The base text style of the document.
  final TextStyle? body;

  /// Style of `# Heading 1` lines.
  final TextStyle? heading1;

  /// Style of `## Heading 2` lines.
  final TextStyle? heading2;

  /// Style of `### Heading 3` lines.
  final TextStyle? heading3;

  /// Style of `#### Heading 4` lines.
  final TextStyle? heading4;

  /// Style of `##### Heading 5` lines.
  final TextStyle? heading5;

  /// Style of `###### Heading 6` lines.
  final TextStyle? heading6;

  /// Style of inline code spans.
  final TextStyle? code;

  /// Style of fenced code block lines.
  final TextStyle? codeBlock;

  /// Style of block quote lines.
  final TextStyle? quote;

  /// Style of link text.
  final TextStyle? link;

  /// Style of link and image destinations.
  final TextStyle? linkUrl;

  /// Style of strong emphasis text.
  final TextStyle? strong;

  /// Style of emphasis text.
  final TextStyle? emphasis;

  /// Style of strikethrough text.
  final TextStyle? strikethrough;

  /// Style of highlighted text, `==like this==`.
  final TextStyle? highlight;

  /// Style merged into Markdown syntax markers before
  /// [markerVisibility] is applied.
  final TextStyle? marker;

  /// Style merged into list bullets and ordered list numbers.
  final TextStyle? listMarker;

  /// Style of task list checkboxes.
  final TextStyle? checkbox;

  /// Style of the hint shown while the document is empty.
  final TextStyle? hint;

  /// Background color painted behind fenced code blocks.
  final Color? codeBlockColor;

  /// Background color painted behind block quotes.
  final Color? quoteColor;

  /// Color of the vertical bar painted next to block quotes.
  final Color? quoteBarColor;

  /// Color of the line painted for thematic breaks.
  final Color? horizontalRuleColor;

  /// Color of the text selection in the editing surface.
  final Color? selectionColor;

  /// Color of the caret in the editing surface.
  final Color? cursorColor;

  /// Color of the hint text.
  final Color? hintColor;

  /// Padding around the document text.
  final EdgeInsets padding;

  /// Vertical gap painted between blocks, in logical pixels.
  final double blockSpacing;

  /// Width of the block quote bar.
  final double quoteBarWidth;

  /// Indentation of one list level, in logical pixels.
  final double listIndent;

  /// How syntax markers are displayed.
  ///
  /// [MarkdownMarkerVisibility.hiddenExceptActiveLine] is the "formatted until
  /// edited" mode: markers collapse to zero width and reappear only on the
  /// lines that contain the selection.
  final MarkdownMarkerVisibility markerVisibility;

  /// Font family used by inline code and fenced code blocks.
  final String codeFontFamily;

  /// Whether thematic breaks (`---`) are painted as a rule.
  ///
  /// When `true` (the default) the dashes are rendered transparently and the
  /// `HorizontalRuleDecorator` paints a clean horizontal line. Set it to
  /// `false` to render the literal `---` syntax instead.
  final bool paintHorizontalRule;

  /// An explicit style sheet for the rendered preview.
  ///
  /// When `null`, the preview style sheet is derived from this theme through
  /// [toMarkdownStyleSheet].
  final MarkdownStyleSheet? previewStyleSheet;

  /// The style used for a heading of [level] (1-6), merged over [base].
  TextStyle headingStyle(int level, TextStyle base) {
    final TextStyle? explicit = switch (level) {
      1 => heading1,
      2 => heading2,
      3 => heading3,
      4 => heading4,
      5 => heading5,
      _ => heading6,
    };
    if (explicit != null) {
      return base.merge(explicit);
    }
    final double size = base.fontSize ?? 14;
    final double scale = switch (level) {
      1 => 1.85,
      2 => 1.55,
      3 => 1.3,
      4 => 1.15,
      5 => 1.05,
      _ => 1.0,
    };
    return base.copyWith(
      fontSize: size * scale,
      fontWeight: level <= 2 ? FontWeight.w700 : FontWeight.w600,
      height: 1.3,
      letterSpacing: level <= 2 ? -0.3 : 0,
    );
  }

  /// The style used for [token], merged over [base].
  ///
  /// Returning a merge-able [TextStyle] (rather than an absolute one) keeps
  /// inheritable properties such as color and font size from the line.
  TextStyle styleForToken(MarkdownTokenType token, TextStyle base) {
    switch (token) {
      case MarkdownTokenType.marker:
        return markerStyle(base);
      case MarkdownTokenType.strong:
        return strong ?? const TextStyle(fontWeight: FontWeight.w700);
      case MarkdownTokenType.emphasis:
        return emphasis ?? const TextStyle(fontStyle: FontStyle.italic);
      case MarkdownTokenType.strikethrough:
        return strikethrough ?? const TextStyle(decoration: TextDecoration.lineThrough);
      case MarkdownTokenType.code:
        return code ??
            TextStyle(
              fontFamily: codeFontFamily,
              fontSize: (base.fontSize ?? 14) * 0.92,
            );
      case MarkdownTokenType.codeBlock:
        return codeBlock ??
            TextStyle(
              fontFamily: codeFontFamily,
              fontSize: (base.fontSize ?? 14) * 0.92,
              height: 1.45,
            );
      case MarkdownTokenType.link:
        return link ??
            const TextStyle(
              color: Color(0xFF1E88E5),
              decoration: TextDecoration.underline,
            );
      case MarkdownTokenType.linkUrl:
      case MarkdownTokenType.linkDestination:
        return linkUrl ?? TextStyle(color: (base.color ?? const Color(0xFF000000)).withValues(alpha: 0.6));
      case MarkdownTokenType.imageAlt:
        return emphasis ?? const TextStyle(fontStyle: FontStyle.italic);
      case MarkdownTokenType.highlight:
        return highlight ??
            TextStyle(
              backgroundColor: const Color(0xFFFFF176).withValues(alpha: 0.6),
            );
      case MarkdownTokenType.quote:
        return quote ?? TextStyle(color: (base.color ?? const Color(0xFF000000)).withValues(alpha: 0.75));
      case MarkdownTokenType.listMarker:
        return listMarker ?? const TextStyle(fontWeight: FontWeight.w600);
      case MarkdownTokenType.checkbox:
        return checkbox ?? const TextStyle(fontFeatures: <FontFeature>[FontFeature.tabularFigures()]);
      case MarkdownTokenType.tableDelimiter:
        return markerStyle(base);
      case MarkdownTokenType.custom:
        return const TextStyle();
    }
  }

  /// The style applied to a syntax marker, honoring [markerVisibility].
  ///
  /// For [MarkdownMarkerVisibility.hiddenExceptActiveLine] this returns the
  /// *revealed* style used on the line being edited; markers on the other lines
  /// are collapsed with [collapsedMarker] by the span engine.
  TextStyle markerStyle(TextStyle base) {
    final Color baseColor = base.color ?? const Color(0xFF000000);
    final Color color = switch (markerVisibility) {
      MarkdownMarkerVisibility.visible => baseColor,
      MarkdownMarkerVisibility.dimmed ||
      MarkdownMarkerVisibility.hiddenExceptActiveLine =>
        baseColor.withValues(alpha: 0.32),
      MarkdownMarkerVisibility.hidden => const Color(0x00000000),
    };
    return const TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      decoration: TextDecoration.none,
    ).merge(TextStyle(color: color)).merge(marker);
  }

  /// The style that collapses a marker without removing its characters.
  ///
  /// A zero font size makes the glyphs take no space and paint nothing while
  /// the span text stays identical to the document source, which is what keeps
  /// caret and selection offsets valid. Used by
  /// [MarkdownMarkerVisibility.hiddenExceptActiveLine]; custom span engines can
  /// reuse it to implement the same behaviour.
  static const TextStyle collapsedMarker = TextStyle(
    fontSize: 0,
    height: 1,
    letterSpacing: 0,
    wordSpacing: 0,
    color: Color(0x00000000),
    backgroundColor: Color(0x00000000),
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
  );

  /// The style that hides a marker while keeping its width.
  ///
  /// Used by [MarkdownMarkerVisibility.hiddenExceptActiveLine] for the block
  /// prefixes (list bullets, ordered numbers, task checkboxes, block quote
  /// markers) that the decoration layer redraws in their rendered form: the
  /// characters stay transparent, so the text keeps exactly the position the
  /// rendered output gives it.
  static const TextStyle hiddenMarker = TextStyle(
    color: Color(0x00000000),
    backgroundColor: Color(0x00000000),
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
  );

  /// Derives a `flutter_markdown_plus` style sheet from this theme.
  ///
  /// The result is a full style sheet, so callers can merge their own
  /// overrides on top of it with [mergeMarkdownStyleSheets].
  MarkdownStyleSheet toMarkdownStyleSheet({BuildContext? context}) {
    final TextStyle base = body ?? const TextStyle(fontSize: 14, height: 1.5);
    final Color surface = codeBlockColor ?? const Color(0x14000000);
    final MarkdownStyleSheet derived = MarkdownStyleSheet(
      p: base,
      pPadding: EdgeInsets.zero,
      a: link ?? base.copyWith(color: const Color(0xFF1E88E5), decoration: TextDecoration.underline),
      em: emphasis ?? const TextStyle(fontStyle: FontStyle.italic),
      strong: strong ?? const TextStyle(fontWeight: FontWeight.w700),
      del: strikethrough ?? const TextStyle(decoration: TextDecoration.lineThrough),
      code: code ??
          TextStyle(
            fontFamily: codeFontFamily,
            fontSize: (base.fontSize ?? 14) * 0.92,
            backgroundColor: surface,
          ),
      h1: headingStyle(1, base),
      h1Padding: EdgeInsets.zero,
      h2: headingStyle(2, base),
      h2Padding: EdgeInsets.zero,
      h3: headingStyle(3, base),
      h3Padding: EdgeInsets.zero,
      h4: headingStyle(4, base),
      h4Padding: EdgeInsets.zero,
      h5: headingStyle(5, base),
      h5Padding: EdgeInsets.zero,
      h6: headingStyle(6, base),
      h6Padding: EdgeInsets.zero,
      blockquote: quote ?? base.copyWith(color: const Color(0xCC000000)),
      img: base,
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      blockquoteDecoration: BoxDecoration(
        color: quoteColor ?? const Color(0x0D000000),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: quoteBarColor ?? const Color(0x8C000000),
            width: quoteBarWidth,
          ),
        ),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(6),
      ),
      blockSpacing: blockSpacing,
      listIndent: listIndent,
      listBullet: listMarker ?? base,
      listBulletPadding: const EdgeInsets.only(right: 6),
      tableColumnWidth: const FlexColumnWidth(),
      tablePadding: const EdgeInsets.only(bottom: 6),
      tableCellsPadding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      tableHeadCellsPadding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: horizontalRuleColor ?? const Color(0x33000000)),
        ),
      ),
      tableBorder: TableBorder.all(color: horizontalRuleColor ?? const Color(0x33000000)),
      checkbox: checkbox ?? base,
      tableHead: base.copyWith(fontWeight: FontWeight.w600),
      tableBody: base,
    );
    return mergeMarkdownStyleSheets(derived, previewStyleSheet);
  }

  /// Returns a copy with the given fields replaced.
  MarkdownEditorTheme copyWith({
    TextStyle? body,
    TextStyle? heading1,
    TextStyle? heading2,
    TextStyle? heading3,
    TextStyle? heading4,
    TextStyle? heading5,
    TextStyle? heading6,
    TextStyle? code,
    TextStyle? codeBlock,
    TextStyle? quote,
    TextStyle? link,
    TextStyle? linkUrl,
    TextStyle? strong,
    TextStyle? emphasis,
    TextStyle? strikethrough,
    TextStyle? highlight,
    TextStyle? marker,
    TextStyle? listMarker,
    TextStyle? checkbox,
    TextStyle? hint,
    Color? codeBlockColor,
    Color? quoteColor,
    Color? quoteBarColor,
    Color? horizontalRuleColor,
    Color? selectionColor,
    Color? cursorColor,
    Color? hintColor,
    EdgeInsets? padding,
    double? blockSpacing,
    double? quoteBarWidth,
    double? listIndent,
    MarkdownMarkerVisibility? markerVisibility,
    String? codeFontFamily,
    bool? paintHorizontalRule,
    MarkdownStyleSheet? previewStyleSheet,
  }) {
    return MarkdownEditorTheme(
      body: body ?? this.body,
      heading1: heading1 ?? this.heading1,
      heading2: heading2 ?? this.heading2,
      heading3: heading3 ?? this.heading3,
      heading4: heading4 ?? this.heading4,
      heading5: heading5 ?? this.heading5,
      heading6: heading6 ?? this.heading6,
      code: code ?? this.code,
      codeBlock: codeBlock ?? this.codeBlock,
      quote: quote ?? this.quote,
      link: link ?? this.link,
      linkUrl: linkUrl ?? this.linkUrl,
      strong: strong ?? this.strong,
      emphasis: emphasis ?? this.emphasis,
      strikethrough: strikethrough ?? this.strikethrough,
      highlight: highlight ?? this.highlight,
      marker: marker ?? this.marker,
      listMarker: listMarker ?? this.listMarker,
      checkbox: checkbox ?? this.checkbox,
      hint: hint ?? this.hint,
      codeBlockColor: codeBlockColor ?? this.codeBlockColor,
      quoteColor: quoteColor ?? this.quoteColor,
      quoteBarColor: quoteBarColor ?? this.quoteBarColor,
      horizontalRuleColor: horizontalRuleColor ?? this.horizontalRuleColor,
      selectionColor: selectionColor ?? this.selectionColor,
      cursorColor: cursorColor ?? this.cursorColor,
      hintColor: hintColor ?? this.hintColor,
      padding: padding ?? this.padding,
      blockSpacing: blockSpacing ?? this.blockSpacing,
      quoteBarWidth: quoteBarWidth ?? this.quoteBarWidth,
      listIndent: listIndent ?? this.listIndent,
      markerVisibility: markerVisibility ?? this.markerVisibility,
      codeFontFamily: codeFontFamily ?? this.codeFontFamily,
      paintHorizontalRule: paintHorizontalRule ?? this.paintHorizontalRule,
      previewStyleSheet: previewStyleSheet ?? this.previewStyleSheet,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MarkdownEditorTheme &&
        other.body == body &&
        other.heading1 == heading1 &&
        other.heading2 == heading2 &&
        other.heading3 == heading3 &&
        other.heading4 == heading4 &&
        other.heading5 == heading5 &&
        other.heading6 == heading6 &&
        other.code == code &&
        other.codeBlock == codeBlock &&
        other.quote == quote &&
        other.link == link &&
        other.linkUrl == linkUrl &&
        other.strong == strong &&
        other.emphasis == emphasis &&
        other.strikethrough == strikethrough &&
        other.highlight == highlight &&
        other.marker == marker &&
        other.listMarker == listMarker &&
        other.checkbox == checkbox &&
        other.hint == hint &&
        other.codeBlockColor == codeBlockColor &&
        other.quoteColor == quoteColor &&
        other.quoteBarColor == quoteBarColor &&
        other.horizontalRuleColor == horizontalRuleColor &&
        other.selectionColor == selectionColor &&
        other.cursorColor == cursorColor &&
        other.hintColor == hintColor &&
        other.padding == padding &&
        other.blockSpacing == blockSpacing &&
        other.quoteBarWidth == quoteBarWidth &&
        other.listIndent == listIndent &&
        other.markerVisibility == markerVisibility &&
        other.codeFontFamily == codeFontFamily &&
        other.paintHorizontalRule == paintHorizontalRule;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        body,
        heading1,
        heading2,
        heading3,
        heading4,
        heading5,
        heading6,
        code,
        codeBlock,
        quote,
        link,
        linkUrl,
        strong,
        emphasis,
        strikethrough,
        highlight,
        marker,
        listMarker,
        checkbox,
        hint,
        codeBlockColor,
        quoteColor,
        quoteBarColor,
        horizontalRuleColor,
        selectionColor,
        cursorColor,
        hintColor,
        padding,
        blockSpacing,
        quoteBarWidth,
        listIndent,
        markerVisibility,
        codeFontFamily,
        paintHorizontalRule,
      ]);
}

/// Merges [overrides] over [base], filling every field that [overrides] leaves
/// `null` from [base].
///
/// `MarkdownStyleSheet.merge` replaces unset fields with `null` and requires
/// the receiver to define every text style, which makes it unsuitable for
/// partial overrides. This helper keeps the base value for any field the
/// caller did not specify, so a preview can be customized with a few
/// properties:
///
/// ```dart
/// MarkdownPreview(
///   data: markdown,
///   styleSheet: MarkdownStyleSheet(
///     h1: const TextStyle(color: Colors.deepPurple),
///   ),
/// )
/// ```
MarkdownStyleSheet mergeMarkdownStyleSheets(
  MarkdownStyleSheet base,
  MarkdownStyleSheet? overrides,
) {
  if (overrides == null) {
    return base;
  }
  return MarkdownStyleSheet(
    a: overrides.a ?? base.a,
    p: overrides.p ?? base.p,
    pPadding: overrides.pPadding ?? base.pPadding,
    code: overrides.code ?? base.code,
    h1: overrides.h1 ?? base.h1,
    h1Padding: overrides.h1Padding ?? base.h1Padding,
    h2: overrides.h2 ?? base.h2,
    h2Padding: overrides.h2Padding ?? base.h2Padding,
    h3: overrides.h3 ?? base.h3,
    h3Padding: overrides.h3Padding ?? base.h3Padding,
    h4: overrides.h4 ?? base.h4,
    h4Padding: overrides.h4Padding ?? base.h4Padding,
    h5: overrides.h5 ?? base.h5,
    h5Padding: overrides.h5Padding ?? base.h5Padding,
    h6: overrides.h6 ?? base.h6,
    h6Padding: overrides.h6Padding ?? base.h6Padding,
    em: overrides.em ?? base.em,
    strong: overrides.strong ?? base.strong,
    del: overrides.del ?? base.del,
    blockquote: overrides.blockquote ?? base.blockquote,
    img: overrides.img ?? base.img,
    checkbox: overrides.checkbox ?? base.checkbox,
    blockSpacing: overrides.blockSpacing ?? base.blockSpacing,
    listIndent: overrides.listIndent ?? base.listIndent,
    listBullet: overrides.listBullet ?? base.listBullet,
    listBulletPadding: overrides.listBulletPadding ?? base.listBulletPadding,
    tableHead: overrides.tableHead ?? base.tableHead,
    tableBody: overrides.tableBody ?? base.tableBody,
    tableHeadAlign: overrides.tableHeadAlign ?? base.tableHeadAlign,
    tablePadding: overrides.tablePadding ?? base.tablePadding,
    tableBorder: overrides.tableBorder ?? base.tableBorder,
    tableColumnWidth: overrides.tableColumnWidth ?? base.tableColumnWidth,
    tableScrollbarThumbVisibility:
        overrides.tableScrollbarThumbVisibility ??
            base.tableScrollbarThumbVisibility,
    tableCellsPadding: overrides.tableCellsPadding ?? base.tableCellsPadding,
    tableCellsDecoration:
        overrides.tableCellsDecoration ?? base.tableCellsDecoration,
    tableHeadCellsPadding:
        overrides.tableHeadCellsPadding ?? base.tableHeadCellsPadding,
    tableHeadCellsDecoration:
        overrides.tableHeadCellsDecoration ?? base.tableHeadCellsDecoration,
    tableVerticalAlignment: overrides.tableVerticalAlignment,
    blockquotePadding: overrides.blockquotePadding ?? base.blockquotePadding,
    blockquoteDecoration:
        overrides.blockquoteDecoration ?? base.blockquoteDecoration,
    codeblockPadding: overrides.codeblockPadding ?? base.codeblockPadding,
    codeblockDecoration:
        overrides.codeblockDecoration ?? base.codeblockDecoration,
    horizontalRuleDecoration:
        overrides.horizontalRuleDecoration ?? base.horizontalRuleDecoration,
    textAlign: overrides.textAlign,
    h1Align: overrides.h1Align,
    h2Align: overrides.h2Align,
    h3Align: overrides.h3Align,
    h4Align: overrides.h4Align,
    h5Align: overrides.h5Align,
    h6Align: overrides.h6Align,
    unorderedListAlign: overrides.unorderedListAlign,
    orderedListAlign: overrides.orderedListAlign,
    blockquoteAlign: overrides.blockquoteAlign,
    codeblockAlign: overrides.codeblockAlign,
    superscriptFontFeatureTag:
        overrides.superscriptFontFeatureTag ?? base.superscriptFontFeatureTag,
    textScaler: overrides.textScaler ?? base.textScaler,
  );
}
