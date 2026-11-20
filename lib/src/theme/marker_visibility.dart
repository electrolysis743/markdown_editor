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
}
