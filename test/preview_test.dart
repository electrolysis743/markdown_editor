// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 700, height: 700, child: child),
    ),
  );
}

void main() {
  testWidgets('renders Markdown content', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const MarkdownPreview(
      data: '# Title\n\n**bold** and *italic*\n\n- one\n- two',
    )));

    expect(find.textContaining('Title', findRichText: true), findsWidgets);
    expect(find.textContaining('bold', findRichText: true), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a hint for empty data', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const MarkdownPreview(data: '')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the custom code block builder', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(MarkdownPreview(
      data: '```dart\nvoid main() {}\n```',
      builders: MarkdownEditorBuilders(
        codeBlockBuilder: (
          BuildContext context,
          MarkdownCodeBlockContext code,
        ) {
          return Text('CUSTOM ${code.language} ${code.code}');
        },
      ),
    )));

    expect(
      find.text('CUSTOM dart void main() {}'),
      findsOneWidget,
    );
  });

  testWidgets('uses the custom image builder', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(MarkdownPreview(
      data: '![alt](https://example.com/a.png)',
      builders: MarkdownEditorBuilders(
        imageBuilder: (BuildContext context, MarkdownImageContext image) {
          return Text('IMAGE ${image.alt} ${image.uri}');
        },
      ),
    )));

    expect(find.textContaining('IMAGE alt'), findsOneWidget);
  });

  testWidgets('supports custom inline syntaxes and element builders',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(MarkdownPreview(
      data: 'a ==marked== b',
      builders: MarkdownEditorBuilders(
        inlineSyntaxes: <md.InlineSyntax>[_MarkSyntax()],
        elementBuilders: <String, MarkdownElementBuilder>{
          'mark': _MarkBuilder(),
        },
      ),
    )));

    expect(find.text('MARK:marked'), findsOneWidget);
  });

  testWidgets('applies a custom style sheet', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(MarkdownPreview(
      data: '# Title',
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(fontSize: 42, color: Color(0xFF00AA00)),
      ),
    )));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Title', findRichText: true), findsWidgets);
  });

  testWidgets('renders every block type without errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const MarkdownPreview(data: '''
# Heading

> A quote with **bold** text.

- bullet
- [x] task
1. ordered

```dart
void main() {}
```

| a | b |
| --- | --- |
| 1 | 2 |

---

A [link](https://example.com) and an image ![alt](https://example.com/a.png).
''')));

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Heading', findRichText: true), findsWidgets);
  });

  testWidgets('can render without scrolling', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const SingleChildScrollView(
      child: MarkdownPreview(data: '# Title', scrollable: false),
    )));

    expect(find.textContaining('Title', findRichText: true), findsWidgets);
  });
}

class _MarkSyntax extends md.InlineSyntax {
  _MarkSyntax() : super(r'==(?=\S)([^=\n]*?\S)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match[1] ?? ''));
    return true;
  }
}

class _MarkBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Text('MARK:${element.textContent}');
  }
}
