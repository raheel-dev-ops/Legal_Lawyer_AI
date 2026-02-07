import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/file_bytes.dart';
import '../../../../core/utils/media_url.dart';
import '../controllers/chat_controller.dart';
import '../../domain/models/chat_model.dart';
import '../../../../core/layout/app_responsive.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();
  final Map<String, List<_MarkdownSegment>> _segmentCache = <String, List<_MarkdownSegment>>{};
  bool _isRecording = false;
  static const String _brToken = '[[BR]]';

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatControllerProvider.notifier).askQuestion(text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final l10n = AppLocalizations.of(context)!;
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path == null) {
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.voiceRecordingFailed)),
        );
        return;
      }
      try {
        final bytes = await readBytes(path);
        if (bytes.isEmpty) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.voiceNoSpeechDetected)),
          );
          return;
        }
        final filename = 'voice_${DateTime.now().millisecondsSinceEpoch}.wav';
        await ref.read(chatControllerProvider.notifier).transcribeAndAsk(bytes, filename);
      } catch (_) {
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.voiceRecordingFailed)),
        );
      }
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      AppNotifications.showSnackBar(context,
        SnackBar(content: Text(l10n.voicePermissionDenied)),
      );
      return;
    }
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String path;
      if (kIsWeb) {
        path = 'voice_$timestamp.wav';
      } else {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_$timestamp.wav';
      }
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
        ),
        path: path,
      );
      setState(() => _isRecording = true);
    } catch (_) {
      AppNotifications.showSnackBar(context,
        SnackBar(content: Text(l10n.voiceRecordingFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chatState = ref.watch(chatControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final assistantMarkdownStyle = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(color: scheme.onSurface, height: 1.45),
      h1: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700),
      h2: TextStyle(color: scheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
      h3: TextStyle(color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
      strong: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
      em: TextStyle(color: scheme.onSurface, fontStyle: FontStyle.italic),
      blockquote: TextStyle(color: scheme.onSurface.withOpacity(0.9)),
      code: const TextStyle(
        color: Colors.white,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      listBullet: TextStyle(color: scheme.onSurface),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      tableBorder: TableBorder.all(color: scheme.outlineVariant),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tableHead: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700, fontSize: 12),
      tableBody: TextStyle(color: scheme.onSurface, fontSize: 12),
    );
    ref.listen(chatControllerProvider, (prev, next) {
      if (next.messages.length > (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
      if (next.error != null && next.error != (prev?.error)) {
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiLegalAssistant),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/chat/conversations'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.invalidate(chatControllerProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => context.push('/profile/voice-input'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? (chatState.isLoading
                    ? _ChatSkeleton()
                    : Center(child: Text(l10n.askLegalQuestion)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: AppResponsive.pagePadding(context),
                    cacheExtent: 800,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
                          ),
                        );
                      }

                      final msg = chatState.messages[index];
                      final isUser = msg.role == 'user';
                      final bubbleColor = isUser ? scheme.primary : scheme.surface;
                      final textColor = isUser ? scheme.onPrimary : scheme.onSurface;
                      final content = isUser ? msg.content : _sanitizeMarkdown(msg.content);
                      final hasTable = !isUser && _containsTable(content);
                      final maxBubbleWidth = hasTable ? screenWidth * 0.92 : screenWidth * 0.78;
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 6)),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppResponsive.spacing(context, 14),
                            vertical: AppResponsive.spacing(context, 12),
                          ),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            border: isUser ? null : Border.all(color: scheme.outlineVariant),
                          ),
                          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                          child: isUser
                              ? Text(
                                  content,
                                  style: TextStyle(color: textColor, height: 1.4),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildAssistantContent(
                                      context,
                                      content: content,
                                      textColor: textColor,
                                      scheme: scheme,
                                      maxBubbleWidth: maxBubbleWidth,
                                      markdownStyle: assistantMarkdownStyle,
                                    ),
                                    if (msg.lawyerSuggestions?.isNotEmpty ?? false) ...[
                                      const SizedBox(height: 12),
                                      _LawyerSuggestionsCard(
                                        suggestions: msg.lawyerSuggestions!,
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 8)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: l10n.typeYourQuestion,
                      border: const OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                SizedBox(width: AppResponsive.spacing(context, 8)),
                IconButton(
                  onPressed: chatState.isLoading ? null : _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic_none),
                ),
                IconButton.filled(
                  onPressed: chatState.isLoading || _isRecording ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sanitizeMarkdown(String input) {
    var text = input.replaceAll('\r\n', '\n');
    text = text.replaceAll(RegExp(r'^##\s*#\s*', multiLine: true), '## ');
    text = text.replaceAll(RegExp(r'^\s*-{3,}\s*$', multiLine: true), '---');
    text = _replaceHtmlLineBreaks(text);
    text = _normalizeDollarNumbers(text);
    final lines = text.split('\n');
    final filtered = <String>[];
    final headerLine = RegExp(
      r'^(step|issue|category|section|clause|rule|article|part|item)\s*[:\-–]?\s*$',
      caseSensitive: false,
    );
    final numberLine = RegExp(r'^\s*\$?(\d{1,2})\s*[.)-]?\s*$');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (RegExp(r'^\s*\$\d+\s*$').hasMatch(trimmed)) {
        continue;
      }
      if (numberLine.hasMatch(trimmed)) {
        continue;
      }
      final headerMatch = headerLine.firstMatch(trimmed);
      if (headerMatch != null && i + 1 < lines.length) {
        final nextTrimmed = lines[i + 1].trim();
        final numMatch = numberLine.firstMatch(nextTrimmed);
        if (numMatch != null) {
          final header = headerMatch.group(1) ?? trimmed;
          filtered.add('${_titleCase(header.toLowerCase())} ${numMatch.group(1)}');
        i += 1;
        continue;
        }
      }
      filtered.add(line);
    }
    text = filtered.join('\n');
    return text.trim();
  }

  String _replaceHtmlLineBreaks(String input) {
    var text = input;
    text = text.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), _brToken);
    text = text.replaceAll(RegExp(r'<\s*/\s*p\s*>', caseSensitive: false), _brToken);
    text = text.replaceAll(RegExp(r'<\s*p\s*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<\s*li\s*>', caseSensitive: false), '$_brToken- ');
    text = text.replaceAll(RegExp(r'<\s*/\s*li\s*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<\s*/?\s*ul\s*>', caseSensitive: false), _brToken);
    return text;
  }

  String _restoreLineBreaks(String input) {
    return input.replaceAll(_brToken, '\n');
  }

  bool _containsTable(String input) {
    return RegExp(r'^\s*\|.*\|\s*$', multiLine: true).hasMatch(input);
  }

  Widget _buildAssistantContent(
    BuildContext context, {
    required String content,
    required Color textColor,
    required ColorScheme scheme,
    required double maxBubbleWidth,
    required MarkdownStyleSheet markdownStyle,
  }) {
    final segments = _getSegments(content);
    if (segments.isEmpty) {
      return Text(_restoreLineBreaks(content), style: TextStyle(color: textColor, height: 1.45));
    }
    if (segments.length == 1 && segments.first.text != null) {
      return MarkdownBody(
        data: _restoreLineBreaks(segments.first.text!),
        selectable: true,
        extensionSet: md.ExtensionSet.gitHubWeb,
        styleSheet: markdownStyle,
      );
    }
    final children = <Widget>[];
    for (final segment in segments) {
      if (segment.text != null) {
        children.add(
          MarkdownBody(
            data: _restoreLineBreaks(segment.text!),
            selectable: true,
            extensionSet: md.ExtensionSet.gitHubWeb,
            styleSheet: markdownStyle,
          ),
        );
      } else if (segment.table != null) {
        children.add(
          _buildTableBlock(
            context,
            table: segment.table!,
            textColor: textColor,
            scheme: scheme,
            maxBubbleWidth: maxBubbleWidth,
          ),
        );
      }
      children.add(const SizedBox(height: 12));
    }
    if (children.isNotEmpty) {
      children.removeLast();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<_MarkdownSegment> _splitMarkdownSegments(String input) {
    final lines = input.split('\n');
    final segments = <_MarkdownSegment>[];
    final buffer = <String>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.contains('|') && i + 1 < lines.length && _isSeparatorRow(lines[i + 1])) {
        final headers = _splitTableRow(line);
        if (headers.isEmpty) {
          buffer.add(line);
          i++;
          continue;
        }
        i += 2;
        final rows = <List<String>>[];
        while (i < lines.length) {
          final rowLine = lines[i];
          if (!rowLine.contains('|') || rowLine.trim().isEmpty) {
            break;
          }
          final row = _splitTableRow(rowLine);
          if (row.isNotEmpty) {
            rows.add(row);
          }
          i += 1;
        }
        if (rows.isEmpty) {
          buffer.add(line);
          buffer.add(lines[i - 1]);
          continue;
        }
        if (buffer.isNotEmpty) {
          final text = buffer.join('\n').trim();
          if (text.isNotEmpty) {
            segments.add(_MarkdownSegment.text(text));
          }
          buffer.clear();
        }
        segments.add(_MarkdownSegment.table(_TableData(headers: headers, rows: rows)));
        continue;
      }
      buffer.add(line);
      i += 1;
    }

    if (buffer.isNotEmpty) {
      final text = buffer.join('\n').trim();
      if (text.isNotEmpty) {
        segments.add(_MarkdownSegment.text(text));
      }
    }
    return segments;
  }

  List<_MarkdownSegment> _getSegments(String content) {
    final cached = _segmentCache[content];
    if (cached != null) {
      return cached;
    }
    final segments = _splitMarkdownSegments(content);
    if (_segmentCache.length >= 120) {
      _segmentCache.remove(_segmentCache.keys.first);
    }
    _segmentCache[content] = segments;
    return segments;
  }

  String _stripInlineMarkdown(String input) {
    var text = input;
    text = _replaceHtmlLineBreaks(text);
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = _normalizeDollarNumbers(text);
    text = text.replaceAll(RegExp(r'\\([\\`*_{}\[\]()#+\-.!])'), r'$1');
    text = text.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'__(.*?)__'), r'$1');
    text = text.replaceAll(RegExp(r'\*(.*?)\*'), r'$1');
    text = text.replaceAll(RegExp(r'_(.*?)_'), r'$1');
    text = text.replaceAll(RegExp(r'`([^`]+)`'), r'$1');
    text = text.replaceAll(RegExp(r'\[(.*?)\]\([^)]+\)'), r'$1');
    text = _restoreLineBreaks(text);
    return _normalizeSectionMarker(text);
  }

  String _normalizeDollarNumbers(String input) {
    var text = input;
    text = text.replaceAllMapped(
      RegExp(r'(^|\n|\[\[BR\]\])\s*\$(\d+)\b'),
      (m) => '${m.group(1)}Section ${m.group(2)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'\b(section|sec\.?|s\.?)\s*\$?(\d+)\b', caseSensitive: false),
      (m) => 'Section ${m.group(2)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'\$(\d+)\b'),
      (m) => m.group(1) ?? '',
    );
    return text;
  }

  String _normalizeSectionMarker(String input) {
    final trimmed = input.trim();
    final match = RegExp(r'^\$(\d+)$').firstMatch(trimmed);
    if (match != null) {
      return match.group(1) ?? input;
    }
    return input;
  }

  String _titleCase(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  bool _isSeparatorRow(String line) {
    final pattern = RegExp(r'^\s*\|?\s*:?[-]{3,}:?\s*(\|\s*:?[-]{3,}:?\s*)+\|?\s*$');
    return pattern.hasMatch(line);
  }

  List<String> _splitTableRow(String line) {
    final raw = line.trim();
    if (!raw.contains('|')) return [];
    return raw
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .toList();
  }

  Widget _buildTableBlock(
    BuildContext context, {
    required _TableData table,
    required Color textColor,
    required ColorScheme scheme,
    required double maxBubbleWidth,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final useCards = screenWidth < 520 || table.headers.length > 3;
    if (useCards) {
      return _buildTableCards(table, textColor, scheme);
    }
    return _buildScrollableTable(table, textColor, scheme, maxBubbleWidth);
  }

  Widget _buildTableCards(_TableData table, Color textColor, ColorScheme scheme) {
    final rows = table.rows;
    final headers = table.headers;
    return Column(
      children: List.generate(rows.length, (rowIndex) {
        final row = rows[rowIndex];
        final values = List<String>.from(row);
        while (values.length < headers.length) {
          values.add('');
        }
        return Container(
          margin: EdgeInsets.only(bottom: rowIndex == rows.length - 1 ? 0 : 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(headers.length, (colIndex) {
              final header = _stripInlineMarkdown(headers[colIndex]);
              var value = _stripInlineMarkdown(values[colIndex]);
              final headerKey = header.trim().toLowerCase();
              final valueTrimmed = value.trim();
              final isPlainNumber = RegExp(r'^\d+$').hasMatch(valueTrimmed);
              final mergeKeywords = [
                'category',
                'step',
                'issue',
                'section',
                'clause',
                'rule',
                'article',
                'part',
                'item',
              ];
              final isMergeColumn = mergeKeywords.any(headerKey.contains);
              final shouldMerge = isPlainNumber && isMergeColumn;
              final displayHeader = shouldMerge ? '${header.trim()} ${valueTrimmed}' : header;
              if (shouldMerge) {
                value = '';
              }
              return Padding(
                padding: EdgeInsets.only(bottom: colIndex == headers.length - 1 ? 0 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayHeader.toUpperCase(),
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (value.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildScrollableTable(
    _TableData table,
    Color textColor,
    ColorScheme scheme,
    double maxBubbleWidth,
  ) {
    final columnCount = table.headers.length;
    final minWidth = maxBubbleWidth < columnCount * 160 ? columnCount * 160.0 : maxBubbleWidth;
    final columnWidths = <int, TableColumnWidth>{};
    for (var i = 0; i < columnCount; i++) {
      columnWidths[i] = const FlexColumnWidth();
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            border: TableBorder.all(color: scheme.outlineVariant),
            children: [
              TableRow(
                decoration: BoxDecoration(color: scheme.surfaceVariant),
                  children: table.headers.map((header) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text(
                        _stripInlineMarkdown(header),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              ...table.rows.map((row) {
                final values = List<String>.from(row);
                while (values.length < columnCount) {
                  values.add('');
                }
                return TableRow(
                  children: values.take(columnCount).map((value) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Text(
                        _stripInlineMarkdown(value),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarkdownSegment {
  final String? text;
  final _TableData? table;
  const _MarkdownSegment.text(this.text) : table = null;
  const _MarkdownSegment.table(this.table) : text = null;
}

class _TableData {
  final List<String> headers;
  final List<List<String>> rows;
  const _TableData({required this.headers, required this.rows});
}

class _ChatSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final padding = AppResponsive.pagePadding(context);
    final bubbleColor = scheme.surfaceVariant;
    final borderColor = scheme.outlineVariant;
    final widths = [0.62, 0.78, 0.55, 0.7, 0.6];
    return ListView.builder(
      padding: padding,
      itemCount: widths.length,
      itemBuilder: (context, index) {
        final isUser = index.isOdd;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 6)),
            width: MediaQuery.of(context).size.width * widths[index],
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.spacing(context, 14),
              vertical: AppResponsive.spacing(context, 12),
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  width: MediaQuery.of(context).size.width * 0.35,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: AppResponsive.spacing(context, 8)),
                Container(
                  height: 10,
                  width: MediaQuery.of(context).size.width * 0.45,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LawyerSuggestionsCard extends StatelessWidget {
  final List<ChatLawyerSuggestion> suggestions;

  const _LawyerSuggestionsCard({required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.suggestedLawyers,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...suggestions.map((lawyer) => _LawyerSuggestionTile(lawyer: lawyer)),
        ],
      ),
    );
  }
}

class _LawyerSuggestionTile extends StatelessWidget {
  final ChatLawyerSuggestion lawyer;

  const _LawyerSuggestionTile({required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatarProvider = resolveMediaImageProvider(
      context,
      lawyer.profilePicturePath,
      width: 36,
      height: 36,
    );
    final initials = lawyer.name.isNotEmpty ? lawyer.name[0] : 'L';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.primary.withOpacity(0.12),
            foregroundImage: avatarProvider,
            child: avatarProvider == null
                ? Text(initials, style: TextStyle(color: scheme.primary))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lawyer.name,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  lawyer.category,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if ((lawyer.phone ?? '').isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_outlined),
              onPressed: () => _launchLink('tel:${lawyer.phone}'),
            ),
          if ((lawyer.email ?? '').isNotEmpty)
            IconButton(
              icon: const Icon(Icons.email_outlined),
              onPressed: () => _launchLink('mailto:${lawyer.email}'),
            ),
        ],
      ),
    );
  }

  void _launchLink(String url) {
    final uri = Uri.parse(url);
    launchUrl(uri);
  }
}
