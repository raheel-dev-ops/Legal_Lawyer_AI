import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../controllers/admin_controller.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_layout.dart';

class AdminRagQueriesScreen extends ConsumerStatefulWidget {
  const AdminRagQueriesScreen({super.key});

  @override
  ConsumerState<AdminRagQueriesScreen> createState() => _AdminRagQueriesScreenState();
}

class _AdminRagQueriesScreenState extends ConsumerState<AdminRagQueriesScreen> {
  static const int _perPage = 10;

  final List<Map<String, dynamic>> _items = [];
  final Set<String> _seenQuestions = {};
  final TextEditingController _minTimeController = TextEditingController();

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasNext = true;
  String? _errorMessage;

  int _page = 1;
  String? _decision;
  bool? _inDomain;
  bool? _safeMode;
  bool? _errorOnly;
  int? _minTimeMs;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _minTimeController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (_loading || _loadingMore) return;
    if (!reset && !_hasNext) return;
    final days = ref.read(ragDaysProvider);
    setState(() {
      if (reset) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _errorMessage = null;
    });
    try {
      final targetPage = reset ? 1 : _page + 1;
      final data = await ref.read(adminRepositoryProvider).getRagQueriesPage(
            page: targetPage,
            days: days,
            perPage: _perPage,
            decision: _decision,
            inDomain: _inDomain,
            safeMode: _safeMode,
            errorOnly: _errorOnly,
            minTimeMs: _minTimeMs,
          );
      final items = data['items'];
      if (items is! List) {
        throw const FormatException('Invalid RAG payload');
      }
      final mapped = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final meta = data['meta'];
      final hasNext = meta is Map<String, dynamic> && meta['hasNext'] == true;
      final filtered = _dedupeLatest(mapped, reset: reset);
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(filtered);
        } else {
          _items.addAll(filtered);
        }
        _page = targetPage;
        _hasNext = hasNext;
      });
    } catch (err) {
      setState(() {
        _errorMessage = _errorMessageFrom(err);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  String _errorMessageFrom(Object err) {
    final mapped = ErrorMapper.from(err);
    if (mapped is AppException) {
      return mapped.userMessage;
    }
    return err.toString();
  }

  void _applyMinTime() {
    final raw = _minTimeController.text.trim();
    final parsed = raw.isEmpty ? null : int.tryParse(raw);
    setState(() {
      _minTimeMs = parsed;
    });
    _load(reset: true);
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return DateFormat.MMMd().add_jm().format(parsed);
  }

  List<Map<String, dynamic>> _dedupeLatest(List<Map<String, dynamic>> incoming, {required bool reset}) {
    if (reset) {
      _seenQuestions.clear();
    }
    final filtered = <Map<String, dynamic>>[];
    for (final item in incoming) {
      final question = (item['question'] as String? ?? '').trim();
      if (question.isEmpty) {
        filtered.add(item);
        continue;
      }
      final key = question.toLowerCase();
      if (_seenQuestions.contains(key)) {
        continue;
      }
      _seenQuestions.add(key);
      filtered.add(item);
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: AppLocalizations.of(context)!.adminRagLogsTitle,
      subtitle: AppLocalizations.of(context)!.adminRagLogsSubtitle,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: AdminEmptyState(
          title: l10n.adminUnableToLoadLogs,
          message: _errorMessage ?? l10n.unknown,
          icon: Icons.query_stats_outlined,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildFilters(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_items.isEmpty)
            SliverToBoxAdapter(
              child: AdminEmptyState(
                title: l10n.adminNoLogsTitle,
                message: l10n.adminNoLogsMessage,
                icon: Icons.query_stats_outlined,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final q = _items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildQueryCard(context, q),
                  );
                },
                childCount: _items.length,
              ),
            ),
          SliverToBoxAdapter(child: _buildLoadMore(context)),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final days = ref.watch(ragDaysProvider);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AdminColors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    final controlStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w600,
        );
    final applyButtonStyle = TextButton.styleFrom(
      foregroundColor: AdminColors.primary,
      minimumSize: const Size(0, 32),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: controlStyle,
    );
    return AdminCard(
      padding: const EdgeInsets.all(10),
      backgroundColor: AdminColors.surfaceAlt,
      borderColor: AdminColors.border.withOpacity(0.6),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _filterBox(
            context,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.adminDaysLabel, style: labelStyle),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: days,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.expand_more, color: AdminColors.textSecondary, size: 18),
                    isDense: true,
                    style: controlStyle,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7')),
                      DropdownMenuItem(value: 30, child: Text('30')),
                      DropdownMenuItem(value: 90, child: Text('90')),
                    ],
                    onChanged: (value) {
                      if (value == null || value == days) return;
                      ref.read(ragDaysProvider.notifier).state = value;
                      _load(reset: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          _filterBox(
            context,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.adminDecisionLabel, style: labelStyle),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _decision,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.expand_more, color: AdminColors.textSecondary, size: 18),
                    isDense: true,
                    style: controlStyle,
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      DropdownMenuItem(value: 'ANSWER', child: Text(l10n.adminDecisionAnswer)),
                      DropdownMenuItem(value: 'OUT_OF_DOMAIN', child: Text(l10n.adminDecisionOutOfDomain)),
                      DropdownMenuItem(value: 'NO_HITS', child: Text(l10n.adminDecisionNoHits)),
                    ],
                    onChanged: (value) {
                      if (value == _decision) return;
                      setState(() {
                        _decision = value;
                      });
                      _load(reset: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          _filterBox(
            context,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.adminInDomainLabel, style: labelStyle),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: _inDomain,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.expand_more, color: AdminColors.textSecondary, size: 18),
                    isDense: true,
                    style: controlStyle,
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      DropdownMenuItem(value: true, child: Text(l10n.yes)),
                      DropdownMenuItem(value: false, child: Text(l10n.no)),
                    ],
                    onChanged: (value) {
                      if (value == _inDomain) return;
                      setState(() {
                        _inDomain = value;
                      });
                      _load(reset: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          _filterBox(
            context,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.adminSafeModeLabel, style: labelStyle),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: _safeMode,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.expand_more, color: AdminColors.textSecondary, size: 18),
                    isDense: true,
                    style: controlStyle,
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      DropdownMenuItem(value: true, child: Text(l10n.adminOn)),
                      DropdownMenuItem(value: false, child: Text(l10n.adminOff)),
                    ],
                    onChanged: (value) {
                      if (value == _safeMode) return;
                      setState(() {
                        _safeMode = value;
                      });
                      _load(reset: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          _filterBox(
            context,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.adminErrorsLabel, style: labelStyle),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<bool?>(
                    value: _errorOnly,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.expand_more, color: AdminColors.textSecondary, size: 18),
                    isDense: true,
                    style: controlStyle,
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      DropdownMenuItem(value: true, child: Text(l10n.adminOnlyErrors)),
                    ],
                    onChanged: (value) {
                      if (value == _errorOnly) return;
                      setState(() {
                        _errorOnly = value;
                      });
                      _load(reset: true);
                    },
                  ),
                ),
              ],
            ),
          ),
          _filterBox(
            context,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.adminMinTimeLabel, style: labelStyle),
                const SizedBox(width: 8),
                SizedBox(
                  width: 78,
                  child: TextField(
                    controller: _minTimeController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _applyMinTime(),
                    decoration: const InputDecoration(
                      hintText: 'ms',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: controlStyle,
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _applyMinTime,
                  style: applyButtonStyle,
                  child: Text(l10n.apply),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBox(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border.withOpacity(0.7)),
      ),
      child: child,
    );
  }

  Widget _buildQueryCard(BuildContext context, Map<String, dynamic> q) {
    final l10n = AppLocalizations.of(context)!;
    final question = q['question']?.toString() ?? '';
    final decision = q['decision']?.toString() ?? l10n.notAvailable;
    final createdAt = _formatDateTime(q['createdAt']?.toString());
    final inDomain = q['inDomain'] == true;
    final safeMode = q['safeMode'] == true;
    final errorOccurred = q['errorOccurred'] == true;
    final contextsFound = q['contextsFound']?.toString();
    final contextsUsed = q['contextsUsed']?.toString();
    final totalTimeMs = q['totalTimeMs']?.toString();
    final totalTokens = q['totalTokens']?.toString();
    final bestDistance = q['bestDistance'];

    return InkWell(
      onTap: () {
        final rawId = q['id'];
        final id = rawId is int ? rawId : (rawId is String ? int.tryParse(rawId) : null);
        if (id != null) {
          context.go('/admin/rag-queries/$id');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AdminCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.isEmpty ? l10n.adminNoQuestionText : question,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                createdAt,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badge(
                  label: _decisionLabel(decision),
                  color: _decisionColor(decision),
                ),
                _badge(
                  label: inDomain ? l10n.adminInDomainLabel : l10n.adminOutOfDomainLabel,
                  color: inDomain ? AdminColors.success : AdminColors.warning,
                ),
                _badge(
                  label: safeMode ? l10n.adminSafeModeOn : l10n.adminSafeModeOff,
                  color: safeMode ? AdminColors.info : AdminColors.textSecondary,
                ),
                if (errorOccurred)
                  _badge(
                    label: l10n.adminErrorLabel,
                    color: AdminColors.error,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                if (contextsUsed != null && contextsFound != null)
                  _metricText(l10n.adminContextsLabel, '$contextsUsed/$contextsFound'),
                if (bestDistance != null) _metricText(l10n.adminDistance, bestDistance.toString()),
                if (totalTimeMs != null) _metricText(l10n.adminLatency, '${totalTimeMs}ms'),
                if (totalTokens != null) _metricText(l10n.adminTokensLabel, totalTokens),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _metricText(String label, String value) {
    return Text(
      '$label: $value',
      style: TextStyle(
        color: AdminColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _decisionLabel(String raw) {
    final l10n = AppLocalizations.of(context)!;
    switch (raw) {
      case 'ANSWER':
        return l10n.adminDecisionAnswer;
      case 'OUT_OF_DOMAIN':
        return l10n.adminDecisionOutOfDomain;
      case 'NO_HITS':
        return l10n.adminDecisionNoHits;
      default:
        return raw.isEmpty ? l10n.unknown : raw;
    }
  }

  Color _decisionColor(String raw) {
    switch (raw) {
      case 'ANSWER':
        return AdminColors.success;
      case 'OUT_OF_DOMAIN':
        return AdminColors.warning;
      case 'NO_HITS':
        return AdminColors.error;
      default:
        return AdminColors.textSecondary;
    }
  }

  Widget _buildLoadMore(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_hasNext && _items.isNotEmpty) {
      return const SizedBox(height: 12);
    }
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loadingMore || !_hasNext ? null : () => _load(reset: false),
          child: _loadingMore
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.adminLoadMoreLogs),
        ),
      ),
    );
  }
}

class AdminRagQueryDetailScreen extends ConsumerWidget {
  final int queryId;
  const AdminRagQueryDetailScreen({super.key, required this.queryId});

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return DateFormat.yMMMd().add_jm().format(parsed);
  }

  String _boolText(bool? value, AppLocalizations l10n) {
    if (value == null) return l10n.notAvailable;
    return value ? l10n.yes : l10n.no;
  }

  String _valueText(dynamic value, AppLocalizations l10n) {
    if (value == null) return l10n.notAvailable;
    final text = value.toString();
    return text.isEmpty ? l10n.notAvailable : text;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AdminPage(
      title: l10n.adminQueryDetailTitle,
      subtitle: l10n.adminQueryDetailSubtitle,
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(adminRepositoryProvider).getRagQueryDetail(queryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final err = ErrorMapper.from(snapshot.error!);
            final message = err is AppException ? err.userMessage : err.toString();
            return Center(child: Text(message));
          }
          final data = snapshot.data ?? {};
          final question = data['question'] as Map<String, dynamic>? ?? {};
          final answer = data['answer'] as Map<String, dynamic>? ?? {};
          final rag = data['rag'] as Map<String, dynamic>? ?? {};
          final sources = data['sources'] as Map<String, dynamic>? ?? {};
          final performance = data['performance'] as Map<String, dynamic>? ?? {};
          final tokens = data['tokens'] as Map<String, dynamic>? ?? {};
          final models = data['models'] as Map<String, dynamic>? ?? {};
          final error = data['error'] as Map<String, dynamic>?;

          final createdAt = _formatDateTime(data['createdAt']?.toString());
          final sourceTitles = sources['titles'] as List<dynamic>? ?? [];
          final chunkIds = sources['chunkIds'] as List<dynamic>? ?? [];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminInfoRow(label: l10n.adminDecisionLabel, value: _valueText(rag['decision'], l10n)),
                    AdminInfoRow(label: l10n.adminInDomainLabel, value: _boolText(rag['inDomain'] as bool?, l10n)),
                    AdminInfoRow(label: l10n.adminSafeModeLabel, value: _boolText(data['safeMode'] as bool?, l10n)),
                    AdminInfoRow(label: l10n.language, value: _valueText(data['language'], l10n)),
                    AdminInfoRow(label: l10n.adminCreatedAtLabel, value: createdAt.isEmpty ? l10n.notAvailable : createdAt),
                    AdminInfoRow(label: l10n.adminUserIdLabel, value: _valueText(data['userId'], l10n)),
                    AdminInfoRow(label: l10n.adminConversationIdLabel, value: _valueText(data['conversationId'], l10n)),
                    AdminInfoRow(label: l10n.adminNewConversationLabel, value: _boolText(data['isNewConversation'] as bool?, l10n)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminQuestionLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(question['text']?.toString() ?? ''),
                    const SizedBox(height: 10),
                    AdminInfoRow(label: l10n.adminLengthLabel, value: _valueText(question['length'], l10n)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminAnswerLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(answer['text']?.toString() ?? ''),
                    const SizedBox(height: 10),
                    AdminInfoRow(label: l10n.adminLengthLabel, value: _valueText(answer['length'], l10n)),
                    AdminInfoRow(label: l10n.adminUsedFallbackLabel, value: _boolText(answer['usedFallback'] as bool?, l10n)),
                    AdminInfoRow(label: l10n.adminDisclaimerAddedLabel, value: _boolText(answer['disclaimerAdded'] as bool?, l10n)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminRetrievalLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    AdminInfoRow(label: l10n.adminThresholdLabel, value: _valueText(rag['threshold'], l10n)),
                    AdminInfoRow(label: l10n.adminBestDistanceLabel, value: _valueText(rag['bestDistance'], l10n)),
                    AdminInfoRow(label: l10n.adminContextsFoundLabel, value: _valueText(rag['contextsFound'], l10n)),
                    AdminInfoRow(label: l10n.adminContextsUsedLabel, value: _valueText(rag['contextsUsed'], l10n)),
                    const SizedBox(height: 6),
                    Text(
                      l10n.adminSourcesLabel,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    if (sourceTitles.isEmpty)
                      Text(l10n.none, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sourceTitles.map((title) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AdminColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Text(
                              title.toString(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                          );
                        }).toList(),
                      ),
                    if (chunkIds.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      AdminInfoRow(label: l10n.adminChunkIdsLabel, value: chunkIds.join(', ')),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminPerformanceLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    AdminInfoRow(label: l10n.adminTotalTimeMsLabel, value: _valueText(performance['totalTimeMs'], l10n)),
                    AdminInfoRow(label: l10n.adminEmbeddingTimeMsLabel, value: _valueText(performance['embeddingTimeMs'], l10n)),
                    AdminInfoRow(label: l10n.adminLlmTimeMsLabel, value: _valueText(performance['llmTimeMs'], l10n)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminTokensLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    AdminInfoRow(label: l10n.adminPromptTokensLabel, value: _valueText(tokens['prompt'], l10n)),
                    AdminInfoRow(label: l10n.adminCompletionTokensLabel, value: _valueText(tokens['completion'], l10n)),
                    AdminInfoRow(label: l10n.adminTotalTokensLabel, value: _valueText(tokens['total'], l10n)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminModelsLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    AdminInfoRow(label: l10n.adminEmbeddingModelLabel, value: _valueText(models['embedding'], l10n)),
                    AdminInfoRow(label: l10n.adminEmbeddingDimensionLabel, value: _valueText(models['embeddingDimension'], l10n)),
                    AdminInfoRow(label: l10n.adminChatModelLabel, value: _valueText(models['chat'], l10n)),
                  ],
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                AdminCard(
                  borderColor: AdminColors.error.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminErrorLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AdminColors.error,
                            ),
                      ),
                      const SizedBox(height: 10),
                      AdminInfoRow(label: l10n.adminTypeLabel, value: _valueText(error['type'], l10n)),
                      Text(
                        _valueText(error['message'], l10n),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
