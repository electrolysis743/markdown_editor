// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 900, height: 700, child: child),
    ),
  );
}

/// The font size of the span covering [offset], or `null` when it inherits.
double? fontSizeAt(TextSpan root, int offset) {
  int cursor = 0;
  double? result;
  root.visitChildren((InlineSpan child) {
    if (child is! TextSpan) {
      return true;
    }
    final String text = child.text ?? '';
    if (offset >= cursor && offset < cursor + text.length) {
      result = child.style?.fontSize;
      return false;
    }
    cursor += text.length;
    return true;
  });
  return result;
}

/// The decoration painter of the editing surface under test.
MarkdownDecorationPainter decorationPainter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((CustomPaint paint) => paint.painter)
      .whereType<MarkdownDecorationPainter>()
      .first;
}

void main() {
  testWidgets('renders the editing surface and the default toolbar',
      (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '# Hello');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(controller: controller)));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Bold'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paints block decorations behind the text',
      (WidgetTester tester) async {
    final MarkdownEditorController controller = MarkdownEditorController(
      text: '> quote\n\n```dart\ncode\n```\n\n---',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(controller: controller)));

    final Iterable<CustomPaint> painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((CustomPaint paint) => paint.painter is MarkdownDecorationPainter);
    expect(painters, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('bold toolbar button wraps the selection',
      (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: 'Hello');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(controller: controller)));
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    await tester.tap(find.byTooltip('Bold'));
    await tester.pump();

    expect(controller.text, '**Hello**');
  });

  testWidgets('the toolbar reflects the active command state',
      (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '**Bold**');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(controller: controller)));
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 6);
    await tester.pump();

    const BoldCommand command = BoldCommand();
    expect(
      command.isActive(
        MarkdownCommandContext(
          controller: controller,
          theme: const MarkdownEditorTheme(),
        ),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview mode renders MarkdownBody instead of a text field',
      (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '# Hello\n\nWorld');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      mode: MarkdownEditorMode.preview,
    )));

    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Hello', findRichText: true), findsWidgets);
    expect(find.byTooltip('Bold'), findsNothing);
  });

  testWidgets('split mode shows both surfaces', (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '# Hello');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      mode: MarkdownEditorMode.split,
    )));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(MarkdownBody), findsOneWidget);
  });

  testWidgets('source mode disables syntax styling',
      (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '**bold**');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      mode: MarkdownEditorMode.source,
    )));

    expect(controller.syntaxHighlighting, isFalse);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('reveals syntax on the line being edited only',
      (WidgetTester tester) async {
    const String text = '# Title\n\n**bold** text';
    final MarkdownEditorController controller =
        MarkdownEditorController(text: text);
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      theme: const MarkdownEditorTheme(
        markerVisibility: MarkdownMarkerVisibility.hiddenExceptActiveLine,
      ),
    )));

    final BuildContext context = tester.element(find.byType(TextField));
    TextSpan currentSpan() =>
        controller.buildTextSpan(context: context, withComposing: false);

    final int boldMarker = text.indexOf('**');
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    expect(controller.selectionLineRange, const TextRange(start: 0, end: 7));
    expect(fontSizeAt(currentSpan(), 0), isNot(0));
    expect(fontSizeAt(currentSpan(), boldMarker), 0);

    controller.selection = TextSelection.collapsed(offset: boldMarker + 1);
    await tester.pump();
    expect(fontSizeAt(currentSpan(), 0), 0);
    expect(fontSizeAt(currentSpan(), boldMarker), isNot(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed markers take no width', (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '**bold**');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      theme: const MarkdownEditorTheme(
        body: TextStyle(fontSize: 16),
        markerVisibility: MarkdownMarkerVisibility.hiddenExceptActiveLine,
      ),
    )));

    final BuildContext context = tester.element(find.byType(TextField));
    double measure(TextSpan span) {
      final TextPainter painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout();
      final double width = painter.width;
      painter.dispose();
      return width;
    }

    // A freshly created controller has no selection, so no line is being
    // edited and every marker collapses.
    expect(controller.selectionLineRange, isNull);
    final double collapsed =
        measure(controller.buildTextSpan(context: context, withComposing: false));
    final double plain = measure(
      const TextSpan(text: 'bold', style: TextStyle(fontSize: 16)),
    );
    expect(collapsed, plain);

    controller.selection = const TextSelection.collapsed(offset: 4);
    final double revealed =
        measure(controller.buildTextSpan(context: context, withComposing: false));
    expect(revealed, greaterThan(collapsed));
  });

  testWidgets('paints block decorations in the formatted mode',
      (WidgetTester tester) async {
    final MarkdownEditorController controller = MarkdownEditorController(
      text: '> quote\n\n```dart\ncode\n```\n\n- item\n\n| a | b |\n| --- | --- |',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      theme: const MarkdownEditorTheme(
        markerVisibility: MarkdownMarkerVisibility.hiddenExceptActiveLine,
      ),
    )));
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();

    final Iterable<MarkdownDecorationPainter> painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((CustomPaint paint) => paint.painter is MarkdownDecorationPainter)
        .map((CustomPaint paint) => paint.painter! as MarkdownDecorationPainter);
    expect(painters, isNotEmpty);
    expect(painters.first.activeLineRange, controller.selectionLineRange);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the rendered caret line collapses when the caret leaves it',
      (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '**bold**\ntext');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      theme: const MarkdownEditorTheme(
        body: TextStyle(fontSize: 16),
        markerVisibility: MarkdownMarkerVisibility.hiddenExceptActiveLine,
      ),
    )));

    final Finder editable = find.byElementPredicate(
      (Element element) => element.renderObject is RenderEditable,
    );
    RenderEditable renderEditable() =>
        tester.renderObject<RenderEditable>(editable);

    controller.selection = const TextSelection.collapsed(offset: 8);
    await tester.pump();
    final double revealed =
        renderEditable().getLocalRectForCaret(const TextPosition(offset: 8)).left;

    controller.selection = const TextSelection.collapsed(offset: 10);
    await tester.pump();
    final double collapsed =
        renderEditable().getLocalRectForCaret(const TextPosition(offset: 8)).left;

    expect(collapsed, lessThan(revealed));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the caret line keeps its layout for list and quote lines',
      (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '- item\n> quote\nplain');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      theme: const MarkdownEditorTheme(
        body: TextStyle(fontSize: 16),
        markerVisibility: MarkdownMarkerVisibility.hiddenExceptActiveLine,
      ),
    )));

    final Finder editable = find.byElementPredicate(
      (Element element) => element.renderObject is RenderEditable,
    );
    Future<double> caretXAt(int offset, int caretOffset) async {
      controller.selection = TextSelection.collapsed(offset: caretOffset);
      await tester.pump();
      return tester
          .renderObject<RenderEditable>(editable)
          .getLocalRectForCaret(TextPosition(offset: offset))
          .left;
    }

    // `- item` keeps the marker width, so entering the line moves nothing.
    final double listInactive = await caretXAt(6, 10);
    final double listActive = await caretXAt(6, 6);
    expect(listActive, listInactive);

    // Same for the block quote marker.
    final double quoteInactive = await caretXAt(14, 17);
    final double quoteActive = await caretXAt(14, 10);
    expect(quoteActive, quoteInactive);
  });

  testWidgets('source mode lays decorations out from plain text',
      (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: '> quote');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      mode: MarkdownEditorMode.source,
    )));

    expect(decorationPainter(tester).showSyntax, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports changes through onChanged', (WidgetTester tester) async {
    final MarkdownEditorController controller = MarkdownEditorController();
    addTearDown(controller.dispose);
    String? changed;

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      onChanged: (String value) => changed = value,
    )));
    await tester.enterText(find.byType(TextField), 'abc');

    expect(changed, 'abc');
    expect(controller.text, 'abc');
  });

  testWidgets('installs keyboard shortcuts', (WidgetTester tester) async {
    final MarkdownEditorController controller = MarkdownEditorController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(controller: controller)));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(controller.text, '**bold text**');
  });

  testWidgets('supports a custom empty state', (WidgetTester tester) async {
    final MarkdownEditorController controller = MarkdownEditorController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      builders: MarkdownEditorBuilders(
        emptyStateBuilder: (BuildContext context) => const Center(
          child: Text('Nothing here yet'),
        ),
      ),
    )));

    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('supports a custom toolbar builder', (WidgetTester tester) async {
    final MarkdownEditorController controller = MarkdownEditorController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      builders: MarkdownEditorBuilders(
        toolbarBuilder: (BuildContext context, MarkdownToolbarContext toolbar) {
          return SizedBox(
            height: 48,
            child: Center(child: Text('${toolbar.items.length} items')),
          );
        },
      ),
    )));

    expect(find.textContaining('items'), findsOneWidget);
    expect(find.byTooltip('Bold'), findsNothing);
  });

  testWidgets('hides the toolbar when configured to', (WidgetTester tester) async {
    final MarkdownEditorController controller = MarkdownEditorController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      toolbar: const MarkdownToolbarConfig(visible: false),
    )));

    expect(find.byTooltip('Bold'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('read-only mode disables shortcuts', (WidgetTester tester) async {
    final MarkdownEditorController controller =
        MarkdownEditorController(text: 'text');
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(MarkdownEditor(
      controller: controller,
      readOnly: true,
    )));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(controller.text, 'text');
  });

  testWidgets('exposes the resolved theme through the scope',
      (WidgetTester tester) async {
    MarkdownEditorTheme? resolved;
    await tester.pumpWidget(wrap(
      Builder(
        builder: (BuildContext context) {
          return MarkdownEditor(
            theme: const MarkdownEditorTheme(
              padding: EdgeInsets.all(4),
            ),
            builders: MarkdownEditorBuilders(
              statusBarBuilder: (BuildContext context) {
                resolved = MarkdownEditorScope.themeOf(context);
                return const SizedBox(height: 1);
              },
            ),
          );
        },
      ),
    ));

    expect(resolved, isNotNull);
    expect(resolved!.body, isNotNull);
    expect(resolved!.padding, const EdgeInsets.all(4));
  });
}
