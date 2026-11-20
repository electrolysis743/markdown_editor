import 'package:flutter/material.dart';

import '../commands/markdown_commands.dart';
import '../controller/markdown_editor_controller.dart';
import '../theme/markdown_editor_theme.dart';

/// The state of a toolbar item, passed to custom item builders.
class MarkdownToolbarItemState {
  /// Creates an item state.
  const MarkdownToolbarItemState({
    required this.item,
    required this.context,
    required this.active,
    required this.enabled,
    required this.onPressed,
  });

  /// The item being built.
  final MarkdownToolbarItem item;

  /// The command context.
  final MarkdownCommandContext context;

  /// Whether the command reports itself active.
  final bool active;

  /// Whether the command can currently run.
  final bool enabled;

  /// Executes the command, or `null` when the item has no command.
  final VoidCallback? onPressed;
}

/// Builds a custom widget for a toolbar item.
typedef MarkdownToolbarItemBuilder = Widget Function(
  BuildContext context,
  MarkdownToolbarItemState state,
);

/// One button in a [MarkdownToolbar].
///
/// Either reference a [MarkdownCommand] (the common case) or provide a
/// [builder] for fully custom UI such as a heading menu or a color picker.
@immutable
class MarkdownToolbarItem {
  /// Creates a toolbar item, with a command or a custom [builder].
  const MarkdownToolbarItem({
    this.command,
    this.icon,
    this.tooltip,
    this.builder,
    this.enabled = true,
    this.id,
  });

  /// Creates a separator between groups of buttons.
  const MarkdownToolbarItem.separator({
    this.id,
  })  : command = null,
        icon = null,
        tooltip = null,
        builder = null,
        enabled = true;

  /// The command executed when the button is pressed.
  final MarkdownCommand? command;

  /// Overrides the command icon.
  final IconData? icon;

  /// Overrides the command label used as a tooltip.
  final String? tooltip;

  /// Builds a fully custom widget instead of the default icon button.
  final MarkdownToolbarItemBuilder? builder;

  /// Whether the button is enabled regardless of the command state.
  final bool enabled;

  /// An optional identifier, useful when filtering or reordering items.
  final String? id;

  /// Whether this item is a separator.
  bool get isSeparator => command == null && builder == null;

  /// The effective identifier.
  String get effectiveId => id ?? command?.id ?? 'separator';
}

/// Visual configuration of a [MarkdownToolbar].
@immutable
class MarkdownToolbarTheme {
  /// Creates a toolbar theme.
  const MarkdownToolbarTheme({
    this.backgroundColor,
    this.foregroundColor,
    this.activeColor,
    this.disabledColor,
    this.separatorColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.spacing = 2,
    this.iconSize = 20,
    this.borderRadius = 6,
    this.height,
  });

  /// The background of the toolbar.
  final Color? backgroundColor;

  /// The color of idle icons.
  final Color? foregroundColor;

  /// The color of active icons and of the active background.
  final Color? activeColor;

  /// The color of disabled icons.
  final Color? disabledColor;

  /// The color of separators.
  final Color? separatorColor;

  /// Padding around the buttons.
  final EdgeInsets padding;

  /// Gap between buttons.
  final double spacing;

  /// Icon size.
  final double iconSize;

  /// Corner radius of the button highlight.
  final double borderRadius;

  /// Fixed height of the toolbar; when `null` the buttons define it.
  final double? height;

  /// Returns a copy with the given fields replaced.
  MarkdownToolbarTheme copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? activeColor,
    Color? disabledColor,
    Color? separatorColor,
    EdgeInsets? padding,
    double? spacing,
    double? iconSize,
    double? borderRadius,
    double? height,
  }) {
    return MarkdownToolbarTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      activeColor: activeColor ?? this.activeColor,
      disabledColor: disabledColor ?? this.disabledColor,
      separatorColor: separatorColor ?? this.separatorColor,
      padding: padding ?? this.padding,
      spacing: spacing ?? this.spacing,
      iconSize: iconSize ?? this.iconSize,
      borderRadius: borderRadius ?? this.borderRadius,
      height: height ?? this.height,
    );
  }
}

/// The context passed to a `MarkdownToolbarBuilder`.
class MarkdownToolbarContext {
  /// Creates a toolbar context.
  const MarkdownToolbarContext({
    required this.controller,
    required this.items,
    required this.theme,
    required this.toolbarTheme,
    required this.axis,
  });

  /// The editor controller.
  final MarkdownEditorController controller;

  /// The items the toolbar would render.
  final List<MarkdownToolbarItem> items;

  /// The editor theme.
  final MarkdownEditorTheme theme;

  /// The toolbar theme.
  final MarkdownToolbarTheme toolbarTheme;

  /// The layout axis.
  final Axis axis;
}

/// Builds a replacement toolbar.
typedef MarkdownToolbarBuilder = Widget Function(
  BuildContext context,
  MarkdownToolbarContext toolbarContext,
);

/// A toolbar of [MarkdownCommand]s.
///
/// The default toolbar is built from [items]; pass your own items or replace
/// the whole widget through `MarkdownEditorBuilders.toolbarBuilder`.
class MarkdownToolbar extends StatelessWidget {
  /// Creates a toolbar.
  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.items,
    required this.theme,
    this.toolbarTheme = const MarkdownToolbarTheme(),
    this.axis = Axis.horizontal,
    this.wrap = false,
    this.itemBuilder,
  });

  /// The controller commands operate on.
  final MarkdownEditorController controller;

  /// The items to render.
  final List<MarkdownToolbarItem> items;

  /// The editor theme, used by command rendering.
  final MarkdownEditorTheme theme;

  /// The toolbar theme.
  final MarkdownToolbarTheme toolbarTheme;

  /// The layout axis.
  final Axis axis;

  /// Whether buttons wrap onto multiple lines instead of scrolling.
  final bool wrap;

  /// Overrides how items are built.
  final MarkdownToolbarItemBuilder? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color foreground =
        toolbarTheme.foregroundColor ?? colors.onSurfaceVariant;
    final Color active = toolbarTheme.activeColor ?? colors.primary;
    final Color disabled =
        toolbarTheme.disabledColor ?? colors.onSurface.withValues(alpha: 0.3);
    final Color separator = toolbarTheme.separatorColor ??
        colors.outlineVariant.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final MarkdownCommandContext commandContext = MarkdownCommandContext(
          controller: controller,
          theme: theme,
        );
        final List<Widget> children = <Widget>[];
        for (final MarkdownToolbarItem item in items) {
          if (item.isSeparator) {
            children.add(
              _Separator(
                color: separator,
                axis: axis,
                spacing: toolbarTheme.spacing,
              ),
            );
            continue;
          }
          final MarkdownCommand? command = item.command;
          final bool enabled = item.enabled &&
              (command?.isEnabled(commandContext) ?? true);
          final bool isActive = command?.isActive(commandContext) ?? false;
          final VoidCallback? onPressed = !enabled
              ? null
              : () {
                  command?.execute(commandContext);
                };
          final MarkdownToolbarItemState state = MarkdownToolbarItemState(
            item: item,
            context: commandContext,
            active: isActive,
            enabled: enabled,
            onPressed: onPressed,
          );
          children.add(
            _buildItem(
              context,
              state,
              foreground: foreground,
              active: active,
              disabled: disabled,
            ),
          );
        }

        final Widget content = wrap
            ? Wrap(
                spacing: toolbarTheme.spacing,
                runSpacing: toolbarTheme.spacing,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: children,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: children,
              );

        return Container(
          height: toolbarTheme.height,
          color: toolbarTheme.backgroundColor ?? colors.surface,
          padding: toolbarTheme.padding,
          child: toolbarTheme.height != null || wrap
              ? content
              : SingleChildScrollView(
                  scrollDirection: axis,
                  child: content,
                ),
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    MarkdownToolbarItemState state, {
    required Color foreground,
    required Color active,
    required Color disabled,
  }) {
    final MarkdownToolbarItemBuilder? builder = state.item.builder ?? itemBuilder;
    if (builder != null) {
      return builder(context, state);
    }
    final IconData? icon = state.item.icon ?? state.item.command?.icon;
    final String label = state.item.tooltip ?? state.item.command?.label ?? '';
    return IconButton(
      onPressed: state.onPressed,
      tooltip: label.isEmpty ? null : label,
      iconSize: toolbarTheme.iconSize,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: state.active ? active : foreground,
        disabledForegroundColor: disabled,
        backgroundColor:
            state.active ? active.withValues(alpha: 0.12) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(toolbarTheme.borderRadius),
        ),
      ),
      icon: Icon(icon ?? Icons.help_outline),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({
    required this.color,
    required this.axis,
    required this.spacing,
  });

  final Color color;
  final Axis axis;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: axis == Axis.horizontal ? 1 : null,
      height: axis == Axis.horizontal ? 18 : 1,
      color: color,
      margin: EdgeInsets.symmetric(horizontal: spacing + 2, vertical: 2),
    );
  }
}

/// A toolbar item that opens a heading level menu.
class MarkdownHeadingToolbarItem extends StatelessWidget {
  /// Creates the item builder widget.
  const MarkdownHeadingToolbarItem({
    super.key,
    required this.state,
    this.toolbarTheme = const MarkdownToolbarTheme(),
  });

  /// The item state provided by the toolbar.
  final MarkdownToolbarItemState state;

  /// The toolbar theme.
  final MarkdownToolbarTheme toolbarTheme;

  @override
  Widget build(BuildContext context) {
    final MarkdownCommandContext commandContext = state.context;
    final int level = commandContext.line.headingLevel;
    final List<MarkdownCommand> commands = <MarkdownCommand>[
      const ParagraphCommand(),
      const HeadingCommand(1),
      const HeadingCommand(2),
      const HeadingCommand(3),
      const HeadingCommand(4),
      const HeadingCommand(5),
      const HeadingCommand(6),
    ];
    return PopupMenuButton<MarkdownCommand>(
      tooltip: 'Heading',
      icon: Icon(
        Icons.title,
        size: toolbarTheme.iconSize,
        color: level > 0
            ? (toolbarTheme.activeColor ?? Theme.of(context).colorScheme.primary)
            : (toolbarTheme.foregroundColor ??
                Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      onSelected: (MarkdownCommand command) => command.execute(commandContext),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<MarkdownCommand>>[
        for (final MarkdownCommand command in commands)
          PopupMenuItem<MarkdownCommand>(
            value: command,
            child: Text(
              command is HeadingCommand
                  ? '${'#' * command.level}  ${command.label}'
                  : command.label,
            ),
          ),
      ],
    );
  }
}

/// Configuration of the toolbar used by `MarkdownEditor`.
@immutable
class MarkdownToolbarConfig {
  /// Creates a toolbar configuration.
  const MarkdownToolbarConfig({
    this.visible = true,
    this.items,
    this.wrap = false,
    this.axis = Axis.horizontal,
    this.theme = const MarkdownToolbarTheme(),
    this.itemBuilder,
  });

  /// Hides the toolbar when `false`.
  final bool visible;

  /// Replaces the default items. Pass an empty list to hide every button.
  final List<MarkdownToolbarItem>? items;

  /// Whether buttons wrap instead of scrolling horizontally.
  final bool wrap;

  /// The layout axis of the toolbar.
  final Axis axis;

  /// The visual configuration of the toolbar.
  final MarkdownToolbarTheme theme;

  /// Overrides how each item is built.
  final MarkdownToolbarItemBuilder? itemBuilder;
}

/// The toolbar items used by `MarkdownEditor` by default.
List<MarkdownToolbarItem> defaultMarkdownToolbarItems() {
  return <MarkdownToolbarItem>[
    const MarkdownToolbarItem(command: UndoCommand(), icon: Icons.undo),
    const MarkdownToolbarItem(command: RedoCommand(), icon: Icons.redo),
    const MarkdownToolbarItem.separator(),
    MarkdownToolbarItem(
      command: const HeadingCommand(1),
      id: 'heading-menu',
      builder: (BuildContext context, MarkdownToolbarItemState state) =>
          MarkdownHeadingToolbarItem(state: state),
    ),
    const MarkdownToolbarItem(command: BoldCommand(), icon: Icons.format_bold),
    const MarkdownToolbarItem(command: ItalicCommand(), icon: Icons.format_italic),
    const MarkdownToolbarItem(
      command: StrikethroughCommand(),
      icon: Icons.format_strikethrough,
    ),
    const MarkdownToolbarItem(command: InlineCodeCommand(), icon: Icons.code),
    const MarkdownToolbarItem(command: HighlightCommand(), icon: Icons.highlight_outlined),
    const MarkdownToolbarItem.separator(),
    const MarkdownToolbarItem(command: LinkCommand(), icon: Icons.link),
    const MarkdownToolbarItem(command: ImageCommand(), icon: Icons.image_outlined),
    const MarkdownToolbarItem.separator(),
    const MarkdownToolbarItem(command: BlockquoteCommand(), icon: Icons.format_quote),
    const MarkdownToolbarItem(
      command: BulletListCommand(),
      icon: Icons.format_list_bulleted,
    ),
    const MarkdownToolbarItem(
      command: OrderedListCommand(),
      icon: Icons.format_list_numbered,
    ),
    const MarkdownToolbarItem(command: TaskListCommand(), icon: Icons.checklist),
    const MarkdownToolbarItem.separator(),
    const MarkdownToolbarItem(command: CodeBlockCommand(), icon: Icons.data_object),
    const MarkdownToolbarItem(command: TableCommand(), icon: Icons.table_chart_outlined),
    const MarkdownToolbarItem(
      command: HorizontalRuleCommand(),
      icon: Icons.horizontal_rule,
    ),
  ];
}

/// Returns the active heading level of the current line, or `0`.
int currentHeadingLevel(MarkdownCommandContext context) =>
    context.line.headingLevel;
