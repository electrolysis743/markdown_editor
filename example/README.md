# markdown_editor example

A runnable demonstration of every extension point in
[`markdown_editor`](../).

```bash
flutter pub get
flutter run -d windows   # or chrome, android, ios, macos, linux
```

Two pages are available:

- **Playground** — the complete editor with mode switching (WYSIWYG, source,
  preview, split), marker visibility, a custom status bar and a custom code
  block widget.
- **Customization** — a custom theme, custom inline rules (`@mentions`,
  `#tags`), a custom block decorator for `> [!NOTE]` callouts, custom toolbar
  commands, a custom editing surface wrapper and a custom preview element
  builder for `==highlight==`.
