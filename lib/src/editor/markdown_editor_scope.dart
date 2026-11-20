import 'package:flutter/widgets.dart';

import '../editor/markdown_editor_extensions.dart';
import '../theme/markdown_editor_theme.dart';

/// Makes the active [MarkdownEditorTheme] and [MarkdownEditorExtensions]
/// available to the editing surface.
///
/// The editor installs this scope automatically. It is public so that custom
/// editing surfaces, span engines and decorators can read the same theme the
/// editor was configured with:
///
/// ```dart
/// final MarkdownEditorTheme theme = MarkdownEditorScope.themeOf(context);
/// ```
class MarkdownEditorScope extends InheritedWidget {
  /// Creates a scope.
  const MarkdownEditorScope({
    super.key,
    required this.theme,
    required this.extensions,
    required super.child,
  });

  /// The active theme.
  final MarkdownEditorTheme theme;

  /// The active extension set.
  final MarkdownEditorExtensions extensions;

  /// Returns the nearest scope, or `null` when there is none.
  static MarkdownEditorScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MarkdownEditorScope>();
  }

  /// Returns the nearest theme, falling back to a theme derived from the
  /// ambient Material theme.
  static MarkdownEditorTheme themeOf(BuildContext context) {
    return maybeOf(context)?.theme ?? MarkdownEditorTheme.fallback(context);
  }

  /// Returns the nearest extension set, or the default one.
  static MarkdownEditorExtensions extensionsOf(BuildContext context) {
    return maybeOf(context)?.extensions ?? const MarkdownEditorExtensions();
  }

  @override
  bool updateShouldNotify(MarkdownEditorScope oldWidget) {
    return oldWidget.theme != theme || oldWidget.extensions != extensions;
  }
}
