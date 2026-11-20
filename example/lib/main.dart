import 'package:flutter/material.dart';

import 'customization_page.dart';
import 'playground_page.dart';

void main() {
  runApp(const MarkdownEditorExampleApp());
}

/// The example application.
class MarkdownEditorExampleApp extends StatefulWidget {
  /// Creates the example application.
  const MarkdownEditorExampleApp({super.key});

  @override
  State<MarkdownEditorExampleApp> createState() =>
      _MarkdownEditorExampleAppState();
}

class _MarkdownEditorExampleAppState extends State<MarkdownEditorExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdown Editor',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      home: HomePage(
        themeMode: _themeMode,
        onToggleTheme: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.light
                ? ThemeMode.dark
                : ThemeMode.light;
          });
        },
      ),
    );
  }
}

/// The home page hosting the demos.
class HomePage extends StatefulWidget {
  /// Creates the home page.
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  /// The current theme mode.
  final ThemeMode themeMode;

  /// Toggles the theme mode.
  final VoidCallback onToggleTheme;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Editor'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          PlaygroundPage(),
          CustomizationPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) => setState(() => _index = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.edit_note),
            label: 'Playground',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            label: 'Customization',
          ),
        ],
      ),
    );
  }
}
