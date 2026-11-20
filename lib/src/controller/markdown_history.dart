import 'package:flutter/services.dart';

/// Undo / redo history for a [TextEditingController].
///
/// The history stores whole [TextEditingValue] snapshots (text and selection),
/// so undo restores the caret as well as the text. Consecutive single character
/// edits within [coalesceWindow] collapse into one entry, which makes typing a
/// word a single undo step while still separating structural edits such as
/// toggling bold or changing a heading.
class MarkdownHistory {
  /// Creates a history.
  MarkdownHistory({
    this.limit = 200,
    this.coalesceWindow = const Duration(milliseconds: 600),
  });

  /// Maximum number of undo entries kept.
  final int limit;

  /// Time window in which single character edits are merged.
  final Duration coalesceWindow;

  final List<TextEditingValue> _undoEntries = <TextEditingValue>[];
  final List<TextEditingValue> _redoEntries = <TextEditingValue>[];
  DateTime? _lastRecordedAt;

  /// Whether there is an entry to undo.
  bool get canUndo => _undoEntries.isNotEmpty;

  /// Whether there is an entry to redo.
  bool get canRedo => _redoEntries.isNotEmpty;

  /// Number of undo entries.
  int get undoCount => _undoEntries.length;

  /// Number of redo entries.
  int get redoCount => _redoEntries.length;

  /// Records the transition from [before] to [after].
  void record(TextEditingValue before, TextEditingValue after) {
    final DateTime now = DateTime.now();
    final bool withinWindow = _lastRecordedAt != null &&
        now.difference(_lastRecordedAt!) <= coalesceWindow;
    final bool continuous = _isSingleCharacterEdit(before, after);
    if (withinWindow && continuous && _undoEntries.isNotEmpty) {
      _redoEntries.clear();
      _lastRecordedAt = now;
      return;
    }
    _undoEntries.add(before);
    if (_undoEntries.length > limit) {
      _undoEntries.removeAt(0);
    }
    _redoEntries.clear();
    _lastRecordedAt = now;
  }

  /// Returns the value to restore on undo, moving [current] to the redo stack.
  TextEditingValue? undo(TextEditingValue current) {
    if (_undoEntries.isEmpty) {
      return null;
    }
    final TextEditingValue target = _undoEntries.removeLast();
    _redoEntries.add(current);
    _lastRecordedAt = null;
    return target;
  }

  /// Returns the value to restore on redo, moving [current] to the undo stack.
  TextEditingValue? redo(TextEditingValue current) {
    if (_redoEntries.isEmpty) {
      return null;
    }
    final TextEditingValue target = _redoEntries.removeLast();
    _undoEntries.add(current);
    _lastRecordedAt = null;
    return target;
  }

  /// Clears both stacks.
  void clear() {
    _undoEntries.clear();
    _redoEntries.clear();
    _lastRecordedAt = null;
  }

  static bool _isSingleCharacterEdit(
    TextEditingValue before,
    TextEditingValue after,
  ) {
    final int difference = after.text.length - before.text.length;
    if (difference.abs() != 1) {
      return false;
    }
    if (!before.selection.isValid || !after.selection.isValid) {
      return false;
    }
    if (before.selection.start != before.selection.end) {
      return false;
    }
    final int cursor = after.selection.isCollapsed
        ? after.selection.start
        : after.text.length;
    return cursor >= 0 && cursor <= after.text.length;
  }
}
