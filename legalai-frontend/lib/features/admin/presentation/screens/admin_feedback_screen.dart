import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../domain/models/admin_stats_model.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_layout.dart';

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  static const int _perPage = 10;

  final List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _errorMessage;
  int _page = 1;
  bool _hasNext = true;

  String _sort = 'newest';
  bool? _read;
  int? _rating;

  FeedbackSummary? _summary;
  bool _summaryLoading = false;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _load(reset: true);
  }

  Future<void> _loadSummary() async {
    if (_summaryLoading) return;
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });
    try {
      final data = await ref.read(adminRepositoryProvider).getFeedbackSummary();
      setState(() {
        _summary = FeedbackSummary.fromApi(data);
      });
    } catch (err) {
      setState(() {
        _summaryError = _errorMessageFrom(err);
      });
    } finally {
      if (mounted) {
        setState(() {
          _summaryLoading = false;
        });
      }
    }
  }

  Future<void> _load({required bool reset}) async {
    if (_loading || _loadingMore) return;
    if (!reset && !_hasNext) return;
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
      final data = await ref.read(adminRepositoryProvider).getFeedbackPage(
            page: targetPage,
            perPage: _perPage,
            sort: _sort,
            read: _read,
            rating: _rating,
          );
      final items = data['items'];
      if (items is! List) {
        throw const FormatException('Invalid feedback payload');
      }
      final mapped = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final meta = data['meta'];
      final hasNext = meta is Map<String, dynamic> && meta['hasNext'] == true;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(mapped);
        } else {
          _items.addAll(mapped);
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

  String _formatTimestamp(String? raw, AppLocalizations l10n) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return DateFormat.yMMMd().format(parsed);
  }

  Future<void> _markReadIfNeeded(Map<String, dynamic> item) async {
    if (item['isRead'] == true) return;
    final rawId = item['id'];
    final id = rawId is int ? rawId : (rawId is String ? int.tryParse(rawId) : null);
    if (id == null) return;
    try {
      await ref.read(adminRepositoryProvider).markFeedbackRead(id, isRead: true);
      final index = _items.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        setState(() {
          _items[index]['isRead'] = true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AdminColors.textSecondary,
        );

    return AdminPage(
      title: l10n.adminNavFeedback,
      subtitle: l10n.adminFeedbackSubtitle,
      header: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminFeedbackManagementTitle, style: titleStyle),
                const SizedBox(height: 6),
                Text(l10n.adminFeedbackManagementSubtitle, style: subtitleStyle),
              ],
            ),
          ),
        ],
      ),
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
          title: l10n.adminUnableToLoadFeedback,
          message: _errorMessage ?? l10n.unknown,
          icon: Icons.feedback_outlined,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildFilters(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildSummary(context)),
        if (_summaryError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _summaryError ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.error),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (_items.isEmpty)
          SliverToBoxAdapter(
            child: AdminEmptyState(
              title: l10n.adminNoFeedbackTitle,
              message: l10n.adminNoFeedbackMessage,
              icon: Icons.feedback_outlined,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final fb = _items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFeedbackCard(context, fb),
                );
              },
              childCount: _items.length,
            ),
          ),
        SliverToBoxAdapter(child: _buildLoadMore(context)),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AdminColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
    final controlStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterPill(
          context,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.adminSortLabel, style: labelStyle),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sort,
                  borderRadius: BorderRadius.circular(14),
                  icon: Icon(Icons.expand_more, color: AdminColors.textSecondary, size: 18),
                  isDense: true,
                  style: controlStyle,
                  items: [
                    DropdownMenuItem(value: 'newest', child: Text(l10n.adminNewest)),
                    DropdownMenuItem(value: 'oldest', child: Text(l10n.adminOldest)),
                  ],
                  onChanged: (value) {
                    if (value == null || value == _sort) return;
                    setState(() {
                      _sort = value;
                    });
                    _load(reset: true);
                  },
                ),
              ),
            ],
          ),
        ),
        _filterPill(
          context,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.adminRatingLabel, style: labelStyle),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _rating,
                  borderRadius: BorderRadius.circular(14),
                  icon: Icon(Icons.expand_more, color: AdminColors.textSecondary, size: 18),
                  isDense: true,
                  style: controlStyle,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.all)),
                    const DropdownMenuItem(value: 5, child: Text('5')),
                    const DropdownMenuItem(value: 4, child: Text('4')),
                    const DropdownMenuItem(value: 3, child: Text('3')),
                    const DropdownMenuItem(value: 2, child: Text('2')),
                    const DropdownMenuItem(value: 1, child: Text('1')),
                  ],
                  onChanged: (value) {
                    if (value == _rating) return;
                    setState(() {
                      _rating = value;
                    });
                    _load(reset: true);
                  },
                ),
              ),
            ],
          ),
        ),
        _filterPill(
          context,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.adminStatusLabel, style: labelStyle),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<bool?>(
                  value: _read,
                  borderRadius: BorderRadius.circular(14),
                  icon: Icon(Icons.expand_more, color: AdminColors.textSecondary, size: 18),
                  isDense: true,
                  style: controlStyle,
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.all)),
                    DropdownMenuItem(value: false, child: Text(l10n.adminUnread)),
                    DropdownMenuItem(value: true, child: Text(l10n.adminRead)),
                  ],
                  onChanged: (value) {
                    if (value == _read) return;
                    setState(() {
                      _read = value;
                    });
                    _load(reset: true);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterPill(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border.withOpacity(0.7)),
      ),
      child: child,
    );
  }

  Widget _buildSummary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final avg = _summary?.avgRating;
    final total = _summary?.totalFeedback;
    final avgText = avg == null ? l10n.notAvailable : avg.toStringAsFixed(1);
    final totalText = total == null ? l10n.notAvailable : total.toString();
    final cards = [
      _CompactStatCard(
        label: l10n.adminAvgRating,
        value: avgText,
        icon: Icons.star,
        color: AdminColors.warning,
      ),
      _CompactStatCard(
        label: l10n.adminTotalFeedback,
        value: totalText,
        icon: Icons.feedback_outlined,
        color: AdminColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 12),
              cards[1],
              if (_summaryLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.adminUpdatingSummary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                  ),
                ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackCard(BuildContext context, Map<String, dynamic> fb) {
    final l10n = AppLocalizations.of(context)!;
    final rating = (fb['rating'] as num?)?.toInt() ?? 0;
    final userId = fb['userId']?.toString() ?? '';
    final userEmail = fb['userEmail']?.toString() ?? '';
    final preview = fb['commentPreview']?.toString() ?? '';
    final createdAt = _formatTimestamp(fb['createdAt']?.toString(), l10n);
    final isRead = fb['isRead'] == true;

    return InkWell(
      onTap: () async {
        await _markReadIfNeeded(fb);
        final rawId = fb['id'];
        final id = rawId is int ? rawId : (rawId is String ? int.tryParse(rawId) : null);
        if (id != null) {
          context.go('/admin/feedback/$id');
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: AdminCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AdminColors.surfaceAlt,
              child: Text(
                l10n.adminUserBadge,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AdminColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.adminUserNumber(userId),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!isRead) _buildUnreadPill(context),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                  ),
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      createdAt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildRatingStars(context, rating),
                  const SizedBox(height: 6),
                  Text(
                    preview.isEmpty ? l10n.adminNoCommentProvided : preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, color: AdminColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildUnreadPill(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminColors.primary.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.primary.withOpacity(0.4)),
      ),
      child: Text(
        l10n.adminUnread,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AdminColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildRatingStars(BuildContext context, int rating) {
    final starColor = AdminColors.warning;
    return Row(
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            size: 18,
            color: starColor,
          ),
        );
      }),
    );
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
              : Text(l10n.adminLoadMoreFeedback),
        ),
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      elevated: false,
      padding: const EdgeInsets.all(14),
      backgroundColor: AdminColors.surfaceAlt,
      borderColor: AdminColors.border.withOpacity(0.6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminFeedbackDetailScreen extends ConsumerStatefulWidget {
  final int feedbackId;
  const AdminFeedbackDetailScreen({super.key, required this.feedbackId});

  @override
  ConsumerState<AdminFeedbackDetailScreen> createState() => _AdminFeedbackDetailScreenState();
}

class _AdminFeedbackDetailScreenState extends ConsumerState<AdminFeedbackDetailScreen> {
  late Future<Map<String, dynamic>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<Map<String, dynamic>> _loadDetail() async {
    final repo = ref.read(adminRepositoryProvider);
    final data = await repo.getFeedbackDetail(widget.feedbackId);
    if (data['isRead'] == false) {
      try {
        await repo.markFeedbackRead(widget.feedbackId, isRead: true);
      } catch (_) {}
    }
    return data;
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return DateFormat.yMMMd().format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminPage(
      title: l10n.adminFeedbackDetailTitle,
      subtitle: l10n.adminFeedbackDetailSubtitle,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
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
          final rating = (data['rating'] as num?)?.toInt() ?? 0;
          final createdAt = _formatDate(data['createdAt']?.toString());
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.adminRatingLabel,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AdminColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: List.generate(5, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      index < rating ? Icons.star : Icons.star_border,
                                      size: 20,
                                      color: AdminColors.warning,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        if (createdAt.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AdminColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Text(
                              createdAt,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AdminColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AdminInfoRow(label: l10n.adminUserIdLabel, value: data['userId']?.toString() ?? ''),
                    AdminInfoRow(label: l10n.email, value: data['userEmail']?.toString() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.adminCommentLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['comment']?.toString() ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
