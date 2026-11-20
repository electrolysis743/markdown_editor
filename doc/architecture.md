# Architecture

This document describes the internals of `wysiwyg_markdown_editor` and, more
importantly, which stage to replace when you need a behaviour the package does
not provide.

## Why the editor edits source, not an AST

A WYSIWYG Markdown editor can be built in two ways:

1. parse the document into a rich model, edit the model, serialize back to
   Markdown;
2. edit the Markdown source and *render it in place*, keeping the source as the
   single source of truth.

`wysiwyg_markdown_editor` takes the second approach. The document is a `String`
held by a `MarkdownEditorController` (a `TextEditingController`). Every
character the user types is the character saved to disk. That makes
round-tripping lossless, keeps diffs meaningful, and lets the editor reuse
Flutter's mature text editing stack for selection, IME, autofill, gestures and
accessibility.

The cost is that syntax markers cannot be removed from the layout: the span
text must stay byte-identical to the controller text, otherwise caret offsets
and selections would drift. The editor therefore styles markers instead of
deleting them (`MarkdownMarkerVisibility`).

## Pipeline

```
                    ┌──────────────────────────────┐
  source text ─────▶│ MarkdownLineAnalyzer         │
                    │ (DefaultMarkdownLineAnalyzer)│
                    └──────────────┬───────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │ MarkdownDocumentLayout       │
                    │ lines: MarkdownLineInfo[]    │
                    │ blocks: MarkdownBlock[]      │
                    └───────┬──────────────┬───────┘
                            │              │
          ┌─────────────────▼───┐      ┌───▼──────────────────┐
          │ MarkdownSpanEngine  │      │ MarkdownLineDecorator│
          │  + inline rules     │      │  (CustomPaint layer) │
          └─────────────────┬───┘      └──────────────────────┘
                            │
                            ▼
                    TextSpan rendered by the TextField
```

### Stage 1 — `MarkdownLineAnalyzer`

`DefaultMarkdownLineAnalyzer.analyze(text)` walks the source once and returns a
`MarkdownDocumentLayout`:

- `MarkdownLineInfo` for every line: absolute `start`/`end`, `contentStart`
  (where inline content begins after `#`, `>`, `- `, `1. `, `- [x] `), `kind`,
  heading level, quote depth, list marker/number, fence information, table
  delimiter flag and the index of the owning block;
- `MarkdownBlock` runs for decorations: paragraphs, headings, quotes, fenced
  code, lists, tables, rules.

Replace it through `MarkdownEditorExtensions.lineAnalyzer` to support a
different dialect. The editor only requires that offsets are absolute document
offsets and that `line.start <= line.end`.

### Stage 2 — `MarkdownInlineRule`s

Each rule scans the inline region of one line and appends
`MarkdownStyleRange`s. The default rules are:

| Rule | Priority | Masks lower rules |
| --- | --- | --- |
| `EscapeInlineRule` | 100 | yes |
| `InlineCodeInlineRule` | 90 | yes |
| `ImageInlineRule` | 85 | yes |
| `LinkInlineRule` | 80 | yes |
| `AutolinkInlineRule` | 75 | yes |
| `EmphasisInlineRule` | 60 | no |
| `StrikethroughInlineRule` | 50 | no |
| `HighlightInlineRule` | 45 | no |
| `HardBreakInlineRule` | 40 | no |

Rules run in descending priority. A rule that calls `scan.mask(...)` hides the
masked characters from every lower priority rule, which is how emphasis inside
inline code stays literal. Overlapping *styles* are merged instead, so
`**bold _and italic_**` composes bold and italic ranges on the same characters.

Custom rules get a `MarkdownInlineScan` that exposes the full document text
(absolute offsets), the current line, the layout, `isEscaped`, `isMasked`,
`matches(RegExp)` (region-clipped) and `add`/`mask`.

### Stage 3 — `MarkdownSpanEngine`

`DefaultMarkdownSpanEngine` turns the layout into a `TextSpan`:

1. compute the line base style from the line kind (body, heading level, quote,
   code block, transparent for painted rules);
2. add block marker ranges (`#`, `>`, `-`, fences, table delimiters);
3. run the inline rules over `[contentStart, end)`;
4. split the line at every range boundary, merge the active ranges into a style
   (ascending priority, so later ranges win), and emit `TextSpan`s;
5. append the exact line ending characters so the span text equals the source.

Because the engine is responsible for the whole span, replacing it lets you
render Markdown with inline widgets, custom `TextStyle` resolution or any other
strategy. `MarkdownSpanEngine` implementations must keep
`span.toPlainText() == source`.

### Stage 4 — `MarkdownLineDecorator`s

Block level visuals (code backgrounds, quote bars, rules) cannot be expressed
as text styles. `MarkdownDecorationPainter` lays out the same spans as the
editing surface and derives:

- `MarkdownLineBox`: the rectangle of each source line (including wrapped visual
  lines);
- `MarkdownBlockBox`: the union of a block's line boxes.

The painter caches geometry in unscrolled coordinates and translates by the
scroll offset at paint time, so scrolling repaints without rebuilding widgets.
Decorators receive a `MarkdownDecorationContext` with the canvas, theme,
layout, boxes and text direction.

## The editing surface

`MarkdownEditingSurface` composes:

- a `TextField` with `expands: true`, no decoration, and the theme's body style;
- behind it, a `CustomPaint` with `MarkdownDecorationPainter`;
- above it, an empty-state/hint layer.

All three share the same `MarkdownEditorController`, text style, text scaler,
text direction and width, which is what keeps decorations aligned.

## Commands, toolbar and shortcuts

`MarkdownCommand` objects are stateless actions over a
`MarkdownCommandContext`. The built-in commands are thin wrappers around
`MarkdownEditorController` editing helpers (`toggleInlineWrap`,
`setHeadingLevel`, `toggleBulletList`, `insertBlock`, …), so applications can
implement their own commands by calling the same helpers.

`MarkdownToolbar` renders a list of `MarkdownToolbarItem`s. An item either
references a command or provides a `MarkdownToolbarItemBuilder` for arbitrary
UI (the heading menu is implemented this way). The toolbar rebuilds whenever
the controller notifies, so `isActive`/`isEnabled` stay current.

`MarkdownEditorShortcuts` maps `ShortcutActivator`s to commands and executes
them through an `Intent`/`Action` pair. Because it sits above the editing
surface, it can override platform text editing shortcuts such as undo.

## Undo / redo

`MarkdownHistory` stores `TextEditingValue` snapshots (text *and* selection).
`MarkdownEditorController.value` is overridden to record the previous value
before every text change, with two rules:

- single character insertions/deletions within `historyCoalesceWindow`
  (default 600 ms) merge into one entry, so typing a word is one undo step;
- restores performed by `undo`/`redo` set a flag that suppresses recording.

## Theming and the preview

`MarkdownEditorTheme` holds every style and color. `resolve(context)` fills
unset fields from the ambient Material theme, so a partial theme is fine.
`toMarkdownStyleSheet()` maps the same values onto a
`flutter_markdown_plus` `MarkdownStyleSheet`; the preview merges any explicit
`previewStyleSheet` over it. That is why the editing and preview panes match.

## Extending checklist

| Need | Replace |
| --- | --- |
| Different Markdown dialect | `MarkdownEditorExtensions.lineAnalyzer` |
| New inline syntax | `MarkdownEditorExtensions.inlineRules` (add a `MarkdownInlineRule`) |
| Different span rendering | `MarkdownEditorExtensions.spanEngine` |
| New block decoration | `MarkdownEditorExtensions.lineDecorators` |
| New colors/typography | `MarkdownEditorTheme` |
| New action | a `MarkdownCommand` + `MarkdownToolbarItem`, or a shortcut binding |
| New toolbar UI | `MarkdownEditorBuilders.toolbarBuilder` |
| Different editing surface | `MarkdownEditorBuilders.editingSurfaceBuilder` |
| Different preview | `MarkdownEditorBuilders.previewBuilder` |
| Code block / image / checkbox widgets | `MarkdownEditorBuilders.codeBlockBuilder` / `imageBuilder` / `checkboxBuilder` |
| New preview element | `MarkdownEditorBuilders.elementBuilders` + `inlineSyntaxes` |
