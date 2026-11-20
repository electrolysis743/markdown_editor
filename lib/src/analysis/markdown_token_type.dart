/// The semantic token kinds that the span engine styles.
///
/// A token is produced by the block analyzers (for markers and headings) or by
/// inline rules (`**bold**`, `` `code` ``, links, and so on). The visual
/// appearance of every token is defined by `MarkdownEditorTheme`, so an
/// application can restyle syntax without writing a single rule.
enum MarkdownTokenType {
  /// Markdown syntax punctuation, for example the `**` of `**bold**` or the
  /// `#` of a heading.
  marker,

  /// Strong emphasis, `**text**`.
  strong,

  /// Emphasis, `*text*`.
  emphasis,

  /// Strikethrough, `~~text~~`.
  strikethrough,

  /// Inline code, `` `code` ``.
  code,

  /// A fenced code block line.
  codeBlock,

  /// The visible text of a link.
  link,

  /// The destination part of a link or image.
  linkUrl,

  /// The alt text of an image.
  imageAlt,

  /// Highlighted text, `==text==`.
  highlight,

  /// A block quote line.
  quote,

  /// A list bullet or ordered list number.
  listMarker,

  /// A task list checkbox, `[x]`.
  checkbox,

  /// A table delimiter row.
  tableDelimiter,

  /// A token produced by a custom rule, styled through
  /// `MarkdownInlineRule` ranges that carry an explicit style.
  custom,
}
