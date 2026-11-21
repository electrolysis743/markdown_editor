# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-11-21

### Added

- `MarkdownMarkerVisibility.hiddenExceptActiveLine`: a new display mode that
  renders every line as its formatted result and reveals the Markdown syntax
  only on the lines the caret or selection touches. Inline markers, heading
  prefixes, link and image destinations, fences and table delimiters collapse to
  zero width with `MarkdownEditorTheme.collapsedMarker`; block prefixes (list
  bullets, ordered numbers, task checkboxes, block quote markers) keep their
  width and are painted transparently with `MarkdownEditorTheme.hiddenMarker`.
  The span text stays identical to the document, so caret, selection, IME and
  accessibility offsets keep working.
- `ListMarkerDecorator` and `TaskListDecorator`, enabled by default: they paint
  the rendered `•`, `1.` and the same Material checkbox icons the preview uses
  for the hidden block markers.
  `MarkdownDecorationContext` gained `activeLineRange`, `baseStyle`,
  `textScaler`, `showSyntax` and `caretX(offset)` so custom decorators can place
  replacement glyphs exactly.
- `MarkdownTokenType.linkDestination`, used by the link and image rules for the
  part of the source that never appears in the rendered output, so marker
  policies can collapse it. It is styled like `linkUrl`.
- `MarkdownSpanBuildContext.activeLineRange`, so custom span engines can see
  which lines are being edited, and `MarkdownEditorController.selectionLineRange`
  for the same range as absolute offsets.
- `MarkdownDecorationPainter.activeLineRange` and `showSyntax`, so decorations
  are laid out from the same spans as the text, in every mode.
- `MarkdownEditingSurface` now publishes an explicitly passed `theme` or
  `extensions` to the text field, so the rendered spans and the decorations use
  the same pipeline when the surface is embedded without a `MarkdownEditor`.

### Fixed

- `MarkdownLineInfo.contentStart` (and therefore `contentOffset`) is now an
  absolute document offset as documented. It used to be relative to the line
  start, which left list, task list and block quote markers of every line after
  the first unstyled and made inline rules scan a region larger than the line.
- Decorations no longer drift from the text in source mode: the painter received
  styled spans while the field rendered plain text, so lines wrapped
  differently and code backgrounds or quote bars landed on the wrong lines.
- `MarkdownEditorTheme.resolveBody` now fills in the color and line height the
  text field would use, so a body style without them no longer lays out the
  decorations at a different height than the text.

## [0.2.2] - 2026-11-21

### Changed

- Shortened the `pubspec.yaml` description to fit the 60–180 character range
  pub.dev recommends.
- Silenced the `package:flutter/material.dart` deprecation on the import lines
  so the package analyzes cleanly on Flutter 3.47+. The deprecated library is
  still the only option that works with Flutter 3.27.1+, because its successor
  `package:material_ui` requires Flutter 3.47 and `flutter_markdown_plus` has
  not migrated yet.

## [0.2.1] - 2026-11-21

### Changed

- Added the `repository` field to `pubspec.yaml`, so pub.dev links to the
  source instead of warning about missing package metadata.
- The example page, sample document and API docs now use the new package name
  instead of the old `markdown_editor` label.

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
