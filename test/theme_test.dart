import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';

void main() {
  group('MarkdownEditorTheme', () {
    test('derives a full style sheet', () {
      const MarkdownEditorTheme theme = MarkdownEditorTheme(
        body: TextStyle(fontSize: 16),
        heading1: TextStyle(fontSize: 40),
      );
      final MarkdownStyleSheet sheet = theme.toMarkdownStyleSheet();

      expect(sheet.p?.fontSize, 16);
      expect(sheet.h1?.fontSize, 40);
      expect(sheet.h2?.fontSize, greaterThan(16));
      expect(sheet.code, isNotNull);
      expect(sheet.blockquoteDecoration, isNotNull);
      expect(sheet.codeblockDecoration, isNotNull);
      expect(sheet.horizontalRuleDecoration, isNotNull);
      expect(sheet.blockSpacing, 8);
    });

    test('scales heading sizes when no explicit style is given', () {
      const TextStyle base = TextStyle(fontSize: 16);
      const MarkdownEditorTheme theme = MarkdownEditorTheme();
      final double h1 = theme.headingStyle(1, base).fontSize!;
      final double h3 = theme.headingStyle(3, base).fontSize!;
      final double h6 = theme.headingStyle(6, base).fontSize!;
      expect(h1, greaterThan(h3));
      expect(h3, greaterThan(h6));
    });

    test('honors marker visibility', () {
      const TextStyle base = TextStyle(fontSize: 16, color: Color(0xFF000000));
      final Color visible = const MarkdownEditorTheme(
        markerVisibility: MarkdownMarkerVisibility.visible,
      ).markerStyle(base).color!;
      final Color dimmed = const MarkdownEditorTheme(
        markerVisibility: MarkdownMarkerVisibility.dimmed,
      ).markerStyle(base).color!;
      final Color hidden = const MarkdownEditorTheme(
        markerVisibility: MarkdownMarkerVisibility.hidden,
      ).markerStyle(base).color!;

      expect(visible.a, 1);
      expect(dimmed.a, lessThan(1));
      expect(hidden.a, 0);
    });

    test('resolves tokens to styles', () {
      const MarkdownEditorTheme theme = MarkdownEditorTheme();
      const TextStyle base = TextStyle(fontSize: 16);

      expect(theme.styleForToken(MarkdownTokenType.strong, base).fontWeight,
          FontWeight.w700);
      expect(theme.styleForToken(MarkdownTokenType.emphasis, base).fontStyle,
          FontStyle.italic);
      expect(
        theme.styleForToken(MarkdownTokenType.strikethrough, base).decoration,
        TextDecoration.lineThrough,
      );
      expect(
        theme.styleForToken(MarkdownTokenType.code, base).fontFamily,
        isNotNull,
      );
    });

    test('copyWith replaces single fields', () {
      const MarkdownEditorTheme theme = MarkdownEditorTheme(
        padding: EdgeInsets.all(8),
      );
      final MarkdownEditorTheme updated = theme.copyWith(
        padding: const EdgeInsets.all(20),
        quoteBarColor: const Color(0xFF123456),
        markerVisibility: MarkdownMarkerVisibility.hidden,
      );
      expect(updated.padding, const EdgeInsets.all(20));
      expect(updated.quoteBarColor, const Color(0xFF123456));
      expect(updated.markerVisibility, MarkdownMarkerVisibility.hidden);
      expect(theme.padding, const EdgeInsets.all(8));
    });

    test('compares by value', () {
      const MarkdownEditorTheme a = MarkdownEditorTheme(
        padding: EdgeInsets.all(8),
      );
      const MarkdownEditorTheme b = MarkdownEditorTheme(
        padding: EdgeInsets.all(8),
      );
      const MarkdownEditorTheme c = MarkdownEditorTheme(
        padding: EdgeInsets.all(4),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    testWidgets('fills unset fields from the ambient theme',
        (WidgetTester tester) async {
      MarkdownEditorTheme? resolved;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF116633),
          brightness: Brightness.dark,
        ),
        home: Builder(
          builder: (BuildContext context) {
            resolved =
                const MarkdownEditorTheme(padding: EdgeInsets.all(6))
                    .resolve(context);
            return const SizedBox();
          },
        ),
      ));

      expect(resolved, isNotNull);
      expect(resolved!.body, isNotNull);
      expect(resolved!.body!.color, isNotNull);
      expect(resolved!.codeBlockColor, isNotNull);
      expect(resolved!.quoteBarColor, isNotNull);
      expect(resolved!.padding, const EdgeInsets.all(6));
    });
  });
}
