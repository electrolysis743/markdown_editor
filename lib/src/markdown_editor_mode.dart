/// The layout modes of a `MarkdownEditor`.
enum MarkdownEditorMode {
  /// Edit the Markdown source through a rich, styled surface. Syntax markers
  /// are dimmed (or hidden, depending on the theme) and the text they surround
  /// is rendered with its final appearance.
  ///
  /// Set `MarkdownEditorTheme.markerVisibility` to
  /// `MarkdownMarkerVisibility.hiddenExceptActiveLine` to render every line as
  /// its formatted result and reveal the syntax only on the line being edited.
  wysiwyg,

  /// Edit the raw Markdown source with a plain monospace style.
  source,

  /// Show the rendered Markdown only.
  preview,

  /// Show the editing surface and the rendered preview side by side.
  split,
}
