/// The sample document used by both example pages.
const String kSampleMarkdown = '''
# wysiwyg_markdown_editor

An **extensible** Markdown editor for Flutter, built on
[flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus).

## Highlights

- Rich, in-place styling while you edit the *plain Markdown source*
- Extensible : every syntax rule, command, builder and decoration is replaceable
- Built-in history with `undo` and `redo`
- Live preview rendered by `flutter_markdown_plus`

> The document you type is always valid Markdown.
> Nothing is stored in a proprietary format.

### Task list

- [x] Render headings, quotes and lists
- [x] Paint code block backgrounds
- [ ] Add syntax highlighting to the preview
- [ ] Publish to pub.dev

### Code

```dart
final MarkdownEditorController controller =
    MarkdownEditorController(text: '# Hello');

MarkdownEditor(controller: controller);
```

### Table

| Feature | Status | Notes |
| --- | --- | --- |
| Toolbar | stable | fully configurable |
| Preview | stable | shares the editor theme |
| Custom rules | stable | add your own syntax |

### Links and images

Visit [pub.dev](https://pub.dev) or write <https://flutter.dev> directly.

![Flutter logo](https://storage.flutter-io.cn/flutter/logomark/logo.png)

A hard break follows this line.  
This line is after the hard break.

---

### Text styles

Use ==highlight==, ~~strikethrough~~ and `inline code` freely.
''';
