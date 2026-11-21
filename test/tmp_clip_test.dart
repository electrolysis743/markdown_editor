// ignore: deprecated_member_use
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wysiwyg_markdown_editor/wysiwyg_markdown_editor.dart';

void main() {
  testWidgets('decorations stay inside the editing surface',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final MarkdownEditorController controller = MarkdownEditorController(
      text: List<String>.generate(20, (int i) => '> quote line $i').join('\n'),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFFF00FF),
        body: RepaintBoundary(
          key: const ValueKey<String>('shot'),
          child: Column(
            children: <Widget>[
              Container(height: 60, color: const Color(0xFFFF00FF)),
              SizedBox(
                height: 120,
                child: MarkdownEditor(
                  controller: controller,
                  toolbar: const MarkdownToolbarConfig(visible: false),
                  theme: const MarkdownEditorTheme(
                    body: TextStyle(fontSize: 14),
                    markerVisibility:
                        MarkdownMarkerVisibility.hiddenExceptActiveLine,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    // Scroll the document so the quote block extends above the viewport.
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    await tester.pumpAndSettle();

    final RenderRepaintBoundary boundary =
        tester.renderObject(find.byKey(const ValueKey<String>('shot')));
    final ui.Image image = await boundary.toImage();
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(data, isNotNull);
    final int width = image.width;
    int tinted = 0;
    for (int y = 0; y < 50; y++) {
      for (int x = 0; x < width; x++) {
        final int i = (y * width + x) * 4;
        final int r = data!.getUint8(i);
        final int g = data.getUint8(i + 1);
        final int b = data.getUint8(i + 2);
        if (r != 0xFF || g != 0x00 || b != 0xFF) {
          tinted++;
        }
      }
    }
    image.dispose();
    expect(tinted, 0, reason: 'decorations painted above the editing surface');
  });
}
