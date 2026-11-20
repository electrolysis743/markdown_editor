import '../model/markdown_block.dart';
import '../model/markdown_document_layout.dart';
import '../model/markdown_line_info.dart';

/// Parses Markdown source into a [MarkdownDocumentLayout].
///
/// The editor never edits an AST: it always edits the plain Markdown source
/// and derives styling from the layout. A custom analyzer can therefore change
/// how the source is interpreted (for example to support a dialect of
/// Markdown) without touching the editing surface.
///
/// See [DefaultMarkdownLineAnalyzer] for the built-in implementation, which
/// understands CommonMark and GitHub Flavored Markdown block constructs.
abstract class MarkdownLineAnalyzer {
  /// Parses [text] into a layout.
  MarkdownDocumentLayout analyze(String text);
}

/// The default line analyzer.
///
/// It recognizes:
///
/// * ATX headings (`#` through `######`),
/// * block quotes, including nested ones (`> >`),
/// * bullet lists (`-`, `*`, `+`), ordered lists (`1.`, `1)`) and task list
///   items (`- [ ]`, `- [x]`),
/// * fenced code blocks (backtick and tilde fences, with an info string),
/// * GitHub Flavored Markdown tables,
/// * thematic breaks (`---`, `***`, `___`).
class DefaultMarkdownLineAnalyzer implements MarkdownLineAnalyzer {
  /// Creates the default analyzer.
  const DefaultMarkdownLineAnalyzer();

  static final RegExp _fenceOpen = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
  static final RegExp _fenceClose = RegExp(r'^ {0,3}(`{3,}|~{3,})\s*$');
  static final RegExp _heading = RegExp(r'^(#{1,6})(?:[ \t]+|$)');
  static final RegExp _bulletList = RegExp(r'^([-*+])(?:[ \t]+|$)');
  static final RegExp _orderedList = RegExp(r'^(\d{1,9})([.)])(?:[ \t]+|$)');
  static final RegExp _taskBox = RegExp(r'^\[([ xX])\](?:[ \t]+|$)');
  static final RegExp _horizontalRule =
      RegExp(r'^(?:(?:-[ \t]*){3,}|(?:\*[ \t]*){3,}|(?:_[ \t]*){3,})$');
  static final RegExp _tableDelimiter = RegExp(
    r'^\s*\|?\s*:?-+:?\s*(?:\|\s*:?-+:?\s*)+\|?\s*$',
  );

  @override
  MarkdownDocumentLayout analyze(String text) {
    if (text.isEmpty) {
      return MarkdownDocumentLayout.empty();
    }

    final List<_LineDraft> drafts = _splitLines(text);
    _FenceState? fence;

    for (int i = 0; i < drafts.length; i++) {
      final _LineDraft draft = drafts[i];
      if (fence != null) {
        _parseFenceBody(draft, fence);
        if (_closesFence(draft.text, fence)) {
          draft.isFenceEnd = true;
          fence = null;
        }
        continue;
      }

      final _Prefix prefix = _scanQuotePrefix(draft.text);
      draft.quoteDepth = prefix.quoteDepth;
      final String body = draft.text.substring(prefix.end);

      final Match? fenceMatch = prefix.quoteDepth == 0 ? _fenceOpen.firstMatch(body) : null;
      if (fenceMatch != null && !_isThematicBreak(body)) {
        final String marker = fenceMatch.group(1)!;
        final String info = fenceMatch.group(2)!.trim();
        fence = _FenceState(
          character: marker[0],
          length: marker.length,
          fenceDepth: 1,
          language: info.isEmpty ? null : info.split(RegExp(r'\s+')).first,
          startLine: i,
        );
        draft
          ..kind = MarkdownLineKind.fencedCode
          ..isFenceStart = true
          ..fenceLanguage = fence.language
          ..fenceDepth = 1
          ..listIndent = prefix.end
          ..contentStart = prefix.end + body.length;
        continue;
      }

      if (_isThematicBreak(body)) {
        draft
          ..kind = MarkdownLineKind.horizontalRule
          ..listIndent = prefix.end
          ..contentStart = prefix.end + body.length;
        continue;
      }

      final Match? headingMatch = _heading.firstMatch(body);
      if (headingMatch != null) {
        draft
          ..kind = MarkdownLineKind.heading
          ..headingLevel = headingMatch.group(1)!.length
          ..listIndent = prefix.end
          ..contentStart = prefix.end + headingMatch.end;
        continue;
      }

      final Match? bulletMatch = _bulletList.firstMatch(body);
      if (bulletMatch != null) {
        _parseList(
          draft,
          prefix.end,
          bulletMatch: bulletMatch,
          ordered: false,
        );
        continue;
      }

      final Match? orderedMatch = _orderedList.firstMatch(body);
      if (orderedMatch != null) {
        _parseList(
          draft,
          prefix.end,
          bulletMatch: null,
          orderedMatch: orderedMatch,
          ordered: true,
        );
        continue;
      }

      if (body.trim().isEmpty) {
        draft
          ..kind = prefix.quoteDepth > 0 || prefix.end > 0
              ? MarkdownLineKind.blockquote
              : MarkdownLineKind.blank
          ..listIndent = prefix.end
          ..contentStart = prefix.end;
        continue;
      }

      draft
        ..kind = prefix.quoteDepth > 0
            ? MarkdownLineKind.blockquote
            : MarkdownLineKind.paragraph
        ..listIndent = prefix.end
        ..contentStart = prefix.end;
    }

    _detectTables(drafts);

    final List<MarkdownBlock> blocks = <MarkdownBlock>[];
    int index = 0;
    while (index < drafts.length) {
      final MarkdownLineKind kind = drafts[index].kind;
      if (kind == MarkdownLineKind.blank) {
        index++;
        continue;
      }
      int last = index;
      switch (kind) {
        case MarkdownLineKind.heading:
        case MarkdownLineKind.horizontalRule:
          last = index;
          break;
        case MarkdownLineKind.fencedCode:
          while (last + 1 < drafts.length &&
              drafts[last + 1].kind == MarkdownLineKind.fencedCode &&
              !drafts[last].isFenceEnd) {
            last++;
          }
          break;
        case MarkdownLineKind.blockquote:
          while (last + 1 < drafts.length &&
              drafts[last + 1].kind == MarkdownLineKind.blockquote) {
            last++;
          }
          break;
        case MarkdownLineKind.bulletList:
        case MarkdownLineKind.orderedList:
        case MarkdownLineKind.taskList:
          while (last + 1 < drafts.length && _isListKind(drafts[last + 1].kind)) {
            last++;
          }
          break;
        case MarkdownLineKind.table:
          while (last + 1 < drafts.length &&
              drafts[last + 1].kind == MarkdownLineKind.table) {
            last++;
          }
          break;
        case MarkdownLineKind.paragraph:
        case MarkdownLineKind.blank:
          while (last + 1 < drafts.length &&
              drafts[last + 1].kind == MarkdownLineKind.paragraph) {
            last++;
          }
          break;
      }

      int quoteDepth = 0;
      int listDepth = 0;
      int headingLevel = 0;
      for (int i = index; i <= last; i++) {
        final _LineDraft draft = drafts[i];
        draft.blockIndex = blocks.length;
        if (draft.quoteDepth > quoteDepth) {
          quoteDepth = draft.quoteDepth;
        }
        final int depth = draft.listIndent ~/ 2;
        if (depth > listDepth) {
          listDepth = depth;
        }
        if (draft.headingLevel > headingLevel) {
          headingLevel = draft.headingLevel;
        }
      }

      blocks.add(
        MarkdownBlock(
          kind: _blockKindFor(kind),
          startLine: index,
          endLine: last,
          quoteDepth: quoteDepth,
          language: drafts[index].fenceLanguage,
          listDepth: listDepth,
          headingLevel: headingLevel,
        ),
      );
      index = last + 1;
    }

    final List<MarkdownLineInfo> lines = <MarkdownLineInfo>[
      for (final _LineDraft draft in drafts) draft.toLineInfo(text),
    ];

    return MarkdownDocumentLayout(
      text: text,
      lines: List<MarkdownLineInfo>.unmodifiable(lines),
      blocks: List<MarkdownBlock>.unmodifiable(blocks),
    );
  }

  // ---------------------------------------------------------------------------
  // Line splitting
  // ---------------------------------------------------------------------------

  List<_LineDraft> _splitLines(String text) {
    final List<_LineDraft> drafts = <_LineDraft>[];
    int start = 0;
    int index = 0;
    while (true) {
      final int newline = text.indexOf('\n', start);
      if (newline < 0) {
        drafts.add(
          _LineDraft(
            index: index,
            start: start,
            end: text.length,
            text: text.substring(start, text.length),
            hasNewline: false,
          ),
        );
        break;
      }
      int end = newline;
      if (end > start && text.codeUnitAt(end - 1) == 0x0D) {
        end -= 1;
      }
      drafts.add(
        _LineDraft(
          index: index,
          start: start,
          end: end,
          text: text.substring(start, end),
          hasNewline: true,
        ),
      );
      index++;
      start = newline + 1;
      if (start > text.length) {
        break;
      }
      if (start == text.length) {
        drafts.add(
          _LineDraft(
            index: index,
            start: start,
            end: start,
            text: '',
            hasNewline: false,
          ),
        );
        break;
      }
    }
    return drafts;
  }

  _Prefix _scanQuotePrefix(String lineText) {
    int cursor = 0;
    int depth = 0;
    while (cursor < lineText.length) {
      int probe = cursor;
      int spaces = 0;
      while (probe < lineText.length && lineText[probe] == ' ' && spaces < 3) {
        probe++;
        spaces++;
      }
      if (probe < lineText.length && lineText[probe] == '>') {
        depth++;
        probe++;
        if (probe < lineText.length && lineText[probe] == ' ') {
          probe++;
        }
        cursor = probe;
        continue;
      }
      break;
    }
    return _Prefix(end: cursor, quoteDepth: depth);
  }

  void _parseList(
    _LineDraft draft,
    int bodyStart, {
    Match? bulletMatch,
    Match? orderedMatch,
    required bool ordered,
  }) {
    final Match match = ordered ? orderedMatch! : bulletMatch!;
    final String marker = ordered
        ? '${match.group(1)}${match.group(2)}'
        : match.group(1)!;
    int contentStart = bodyStart + match.end;
    bool isTask = false;
    bool taskChecked = false;

    final String rest = draft.text.substring(contentStart);
    final Match? taskMatch = _taskBox.firstMatch(rest);
    if (taskMatch != null) {
      isTask = true;
      taskChecked = taskMatch.group(1)!.toLowerCase() == 'x';
      contentStart += taskMatch.end;
    }

    draft
      ..kind = isTask
          ? MarkdownLineKind.taskList
          : (ordered ? MarkdownLineKind.orderedList : MarkdownLineKind.bulletList)
      ..listMarker = marker
      ..listIndent = bodyStart
      ..orderedNumber = ordered ? int.tryParse(match.group(1)!) : null
      ..isTask = isTask
      ..taskChecked = taskChecked
      ..contentStart = contentStart;
  }

  void _parseFenceBody(_LineDraft draft, _FenceState fence) {
    draft
      ..kind = MarkdownLineKind.fencedCode
      ..fenceDepth = fence.fenceDepth
      ..fenceLanguage = fence.language
      ..contentStart = draft.end;
  }

  bool _closesFence(String lineText, _FenceState fence) {
    final Match? match = _fenceClose.firstMatch(lineText);
    if (match == null) {
      return false;
    }
    final String marker = match.group(1)!;
    return marker[0] == fence.character && marker.length >= fence.length;
  }

  bool _isThematicBreak(String body) {
    return _horizontalRule.hasMatch(body);
  }

  static bool _isListKind(MarkdownLineKind kind) {
    return kind == MarkdownLineKind.bulletList ||
        kind == MarkdownLineKind.orderedList ||
        kind == MarkdownLineKind.taskList;
  }

  static MarkdownBlockKind _blockKindFor(MarkdownLineKind kind) {
    switch (kind) {
      case MarkdownLineKind.heading:
        return MarkdownBlockKind.heading;
      case MarkdownLineKind.blockquote:
        return MarkdownBlockKind.quote;
      case MarkdownLineKind.fencedCode:
        return MarkdownBlockKind.fencedCode;
      case MarkdownLineKind.bulletList:
      case MarkdownLineKind.orderedList:
      case MarkdownLineKind.taskList:
        return MarkdownBlockKind.list;
      case MarkdownLineKind.table:
        return MarkdownBlockKind.table;
      case MarkdownLineKind.horizontalRule:
        return MarkdownBlockKind.horizontalRule;
      case MarkdownLineKind.paragraph:
      case MarkdownLineKind.blank:
        return MarkdownBlockKind.paragraph;
    }
  }

  // ---------------------------------------------------------------------------
  // Tables
  // ---------------------------------------------------------------------------

  void _detectTables(List<_LineDraft> drafts) {
    for (int i = 1; i < drafts.length; i++) {
      final _LineDraft delimiter = drafts[i];
      if (!_tableDelimiter.hasMatch(delimiter.text) ||
          !delimiter.text.contains('|')) {
        continue;
      }
      final _LineDraft header = drafts[i - 1];
      if (!header.text.contains('|') ||
          header.kind != MarkdownLineKind.paragraph) {
        continue;
      }
      header.kind = MarkdownLineKind.table;
      delimiter
        ..kind = MarkdownLineKind.table
        ..isTableDelimiter = true;
      for (int j = i + 1; j < drafts.length; j++) {
        final _LineDraft row = drafts[j];
        if (row.text.trim().isEmpty || !row.text.contains('|')) {
          break;
        }
        row.kind = MarkdownLineKind.table;
      }
    }
  }
}

/// The quote prefix of a line: `>`, `> >` and so on.
class _Prefix {
  const _Prefix({required this.end, required this.quoteDepth});

  final int end;
  final int quoteDepth;
}

/// Mutable state of an open fenced code block.
class _FenceState {
  _FenceState({
    required this.character,
    required this.length,
    required this.fenceDepth,
    required this.language,
    required this.startLine,
  });

  final String character;
  final int length;
  final int fenceDepth;
  final String? language;
  final int startLine;
}

/// A mutable line description used while analyzing.
class _LineDraft {
  _LineDraft({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
    required this.hasNewline,
  });

  final int index;
  final int start;
  final int end;
  final String text;
  final bool hasNewline;

  MarkdownLineKind kind = MarkdownLineKind.blank;
  int headingLevel = 0;
  int quoteDepth = 0;
  int listIndent = 0;
  String listMarker = '';
  int? orderedNumber;
  bool isTask = false;
  bool taskChecked = false;
  bool isFenceStart = false;
  bool isFenceEnd = false;
  String? fenceLanguage;
  int fenceDepth = 0;
  bool isTableDelimiter = false;
  int? contentStart;
  int blockIndex = -1;

  MarkdownLineInfo toLineInfo(String text) {
    return MarkdownLineInfo(
      index: index,
      start: start,
      end: end,
      text: this.text,
      kind: kind,
      headingLevel: headingLevel,
      quoteDepth: quoteDepth,
      listIndent: listIndent,
      listMarker: listMarker,
      orderedNumber: orderedNumber,
      isTask: isTask,
      taskChecked: taskChecked,
      isFenceStart: isFenceStart,
      isFenceEnd: isFenceEnd,
      fenceLanguage: fenceLanguage,
      fenceDepth: fenceDepth,
      isTableDelimiter: isTableDelimiter,
      contentStart: contentStart,
      blockIndex: blockIndex,
      hasNewline: hasNewline,
    );
  }
}
