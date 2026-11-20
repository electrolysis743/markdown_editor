# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-11-21

### Changed

- **Renamed the package to `wysiwyg_markdown_editor`.** pub.dev rejects names
  that are too similar to an existing package (`markdowneditor`), so the import
  path is now `package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart`.
  The public API (widget, controller, theme, builders, commands and helpers) is
  unchanged; only the package name, the barrel file name and the example package
  name changed.
- The example application's window and app bar title is now "Markdown Editor"
  instead of the package name.

## [0.1.0] - 2026-11-21

Initial release.

### Added

- `MarkdownEditor` widget with `wysiwyg`, `source`, `preview` and `split`
  modes.
- `MarkdownEditorController` built on `TextEditingController`, with undo/redo
  history, command helpers and access to the parsed layout.
- A line analyzer for CommonMark and GitHub Flavored Markdown block constructs
  (headings, quotes, bullet/ordered/task lists, fenced code blocks, tables and
  thematic breaks).
- An inline rule pipeline for emphasis, strong emphasis, strikethrough,
  highlight, inline code, links, images, autolinks, escapes and hard breaks,
  extensible with application rules.
- A span engine that renders styled spans over the unchanged Markdown source,
  including nested styles and configurable marker visibility.
- A decoration layer that paints fenced code backgrounds, block quote bars and
  rules behind the text, extensible with application decorators.
- Built-in commands and a configurable toolbar: undo/redo, headings, bold,
  italic, strikethrough, highlight, inline code, link, image, quote, bullet,
  ordered and task lists, code block, table, indent, outdent and divider.
- Remappable keyboard shortcuts.
- `MarkdownEditorTheme` covering every token, plus derivation of a
  `flutter_markdown_plus` `MarkdownStyleSheet` for the preview.
- `MarkdownEditorBuilders` replacing the toolbar, editing surface, preview,
  status bar, empty state, code blocks, images, checkboxes and bullets.
- `MarkdownEditorExtensions` replacing the analyzer, span engine, inline rules
  and line decorators.
- Example application demonstrating every extension point.
- A Simplified Chinese translation of the README (`README.zh-CN.md`).
