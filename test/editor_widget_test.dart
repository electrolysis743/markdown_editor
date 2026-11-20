import 'package:flutter/material.dart';
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
