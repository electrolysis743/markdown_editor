/// How the editor displays Markdown syntax markers.
///
/// The editor always edits plain Markdown source, so syntax markers occupy
/// characters in the text. This policy controls how visible those characters
/// are while editing.
enum MarkdownMarkerVisibility {
  /// Syntax markers are rendered with the normal text style.
  visible,

  /// Syntax markers are rendered in a faded color. This is the default: the
  /// document reads like rich text while the syntax stays discoverable.
  dimmed,

  /// Syntax markers are rendered transparently.
  ///
  /// The characters keep their width so the layout stays stable while the
  /// caret moves through them; only their paint is hidden.
  hidden,

  /// Syntax markers are collapsed to zero width everywhere except on the lines
  /// that contain the selection, where they are revealed like [dimmed].
  ///
  /// This is the "formatted until you edit it" display mode: a document reads
  /// like rendered Markdown, and the syntax you are editing appears on the
  /// caret line only.
  ///
  /// Markers are not removed from the document: they keep contributing
  /// characters to the text, so caret, selection, IME and accessibility offsets
  /// stay valid.
  ///
  /// Inline markers, heading prefixes and whole-line markers (fences, table
  /// delimiters) are collapsed to zero width. Block prefixes keep their width
  /// and are painted transparently; the decoration layer draws their rendered
  /// form in that space (`•` bullets, `1.` numbers, Material checkboxes and the
  /// block quote bar), so the text lines up exactly with the rendered output.
  hiddenExceptActiveLine,
}
