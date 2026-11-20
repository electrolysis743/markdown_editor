// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../commands/markdown_commands.dart';
import '../controller/markdown_editor_controller.dart';
import '../theme/markdown_editor_theme.dart';

/// An [Intent] that runs a [MarkdownCommand].
class MarkdownCommandIntent extends Intent {
  /// Creates an intent for [command].
  const MarkdownCommandIntent(this.command);

  /// The command to run.
  final MarkdownCommand command;
}

/// Installs configurable keyboard shortcuts for Markdown commands.
///
/// The default bindings are platform neutral: every command is bound both to
/// the Control and to the Meta (Command) modifier, so the same widget works on
/// Windows, Linux, Android, iOS, macOS and the web. Pass [bindings] to replace
/// them entirely:
///
/// ```dart
/// MarkdownEditorShortcuts(
///   controller: controller,
///   bindings: <ShortcutActivator, MarkdownCommand>{
///     const SingleActivator(LogicalKeyboardKey.keyB, meta: true):
///         const BoldCommand(),
///   },
///   child: editor,
/// )
/// ```
class MarkdownEditorShortcuts extends StatelessWidget {
  /// Creates the shortcut layer.
  const MarkdownEditorShortcuts({
    super.key,
    required this.controller,
    required this.theme,
    required this.child,
    this.bindings,
    this.enabled = true,
    this.enableTabIndentation = false,
  });

  /// The controller commands operate on.
  final MarkdownEditorController controller;

  /// The active theme.
  final MarkdownEditorTheme theme;

  /// The widget below the shortcut layer.
  final Widget child;

  /// Overrides the default bindings.
  final Map<ShortcutActivator, MarkdownCommand>? bindings;

  /// Whether the layer is active.
  final bool enabled;

  /// Whether Tab / Shift+Tab indent and outdent instead of moving focus.
  final bool enableTabIndentation;

  /// The default keyboard bindings.
  static Map<ShortcutActivator, MarkdownCommand> defaultBindings({
    bool includeTabIndentation = false,
  }) {
    final List<bool> modifiers = <bool>[true, false];
    final Map<ShortcutActivator, MarkdownCommand> result =
        <ShortcutActivator, MarkdownCommand>{};

    void bind(
      MarkdownCommand command,
      LogicalKeyboardKey key, {
      bool shift = false,
      bool alt = false,
    }) {
      for (final bool control in modifiers) {
        for (final bool meta in modifiers) {
          if (control == meta) {
            continue;
          }
          result[SingleActivator(
            key,
            control: control,
            meta: meta,
            shift: shift,
            alt: alt,
          )] = command;
        }
      }
    }

    bind(const BoldCommand(), LogicalKeyboardKey.keyB);
    bind(const ItalicCommand(), LogicalKeyboardKey.keyI);
    bind(const StrikethroughCommand(), LogicalKeyboardKey.keyX, shift: true);
    bind(const InlineCodeCommand(), LogicalKeyboardKey.keyE);
    bind(const HighlightCommand(), LogicalKeyboardKey.keyH, shift: true);
    bind(const LinkCommand(), LogicalKeyboardKey.keyK);
    bind(const BlockquoteCommand(), LogicalKeyboardKey.keyQ, shift: true);
    bind(const BulletListCommand(), LogicalKeyboardKey.digit8, shift: true);
    bind(const OrderedListCommand(), LogicalKeyboardKey.digit7, shift: true);
    bind(const TaskListCommand(), LogicalKeyboardKey.digit9, shift: true);
    bind(const CodeBlockCommand(), LogicalKeyboardKey.keyC, shift: true, alt: true);
    bind(const HorizontalRuleCommand(), LogicalKeyboardKey.keyR, shift: true, alt: true);
    const List<LogicalKeyboardKey> headingKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
    ];
    for (int i = 0; i < headingKeys.length; i++) {
      bind(HeadingCommand(i + 1), headingKeys[i], alt: true);
    }
    if (includeTabIndentation) {
      result[const SingleActivator(LogicalKeyboardKey.tab)] =
          const IndentCommand();
      result[const SingleActivator(LogicalKeyboardKey.tab, shift: true)] =
          const OutdentCommand();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    final Map<ShortcutActivator, MarkdownCommand> resolved =
        bindings ?? defaultBindings(includeTabIndentation: enableTabIndentation);
    if (resolved.isEmpty) {
      return child;
    }
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        for (final MapEntry<ShortcutActivator, MarkdownCommand> entry
            in resolved.entries)
          entry.key: MarkdownCommandIntent(entry.value),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          MarkdownCommandIntent: CallbackAction<MarkdownCommandIntent>(
            onInvoke: (MarkdownCommandIntent intent) {
              intent.command.execute(
                MarkdownCommandContext(controller: controller, theme: theme),
              );
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
