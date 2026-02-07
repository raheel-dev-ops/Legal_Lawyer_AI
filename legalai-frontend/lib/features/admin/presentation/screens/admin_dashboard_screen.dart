import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_button_tokens.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../admin_notifications/presentation/controllers/admin_notifications_controller.dart';
import '../controllers/admin_controller.dart';
import '../../domain/models/admin_stats_model.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_layout.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Future<void> _refreshDashboard() async {
    final days = ref.read(ragDaysProvider);
    ref.read(adminDashboardRefreshProvider.notifier).state++;
    await Future.wait([
      ref.refresh(ragMetricsProvider(days: days).future),
      ref.refresh(knowledgeSourcesProvider.future),
      ref.refresh(usersTotalProvider.future),
      ref.refresh(lawyersTotalProvider.future),
      ref.refresh(feedbackTotalProvider.future),
      ref.refresh(contactMessagesTotalProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(adminNotificationsStreamControllerProvider);
    final ragDays = ref.watch(ragDaysProvider);
    final metricsAsync = ref.watch(ragMetricsProvider(days: ragDays));
    final knowledgeAsync = ref.watch(knowledgeSourcesProvider);
    final usersTotalAsync = ref.watch(usersTotalProvider);
    final lawyersTotalAsync = ref.watch(lawyersTotalProvider);
    final feedbackTotalAsync = ref.watch(feedbackTotalProvider);
    final contactTotalAsync = ref.watch(contactMessagesTotalProvider);
    final unreadAsync = ref.watch(adminNotificationsUnreadCountProvider);
    final showNotificationDot = unreadAsync.maybeWhen(
      data: (count) => count > 0,
      orElse: () => false,
    );
    final user = ref.watch(authControllerProvider).value;
    final avatarProvider = resolveMediaImageProvider(
      context,
      user?.avatarPath,
      width: 52,
      height: 52,
    );

    final knowledgeCount = knowledgeAsync.maybeWhen(
      data: (sources) => sources.length,
      orElse: () => null,
    );

    final usersTotal = _valueOrNull(usersTotalAsync);
    final lawyersTotal = _valueOrNull(lawyersTotalAsync);
    final feedbackTotal = _valueOrNull(feedbackTotalAsync);
    final contactTotal = _valueOrNull(contactTotalAsync);

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _DashboardHeader(
            name: user?.name ?? l10n.adminLabel,
            role: l10n.adminRoleSystemAdministrator,
            avatarProvider: avatarProvider,
            onProfileTap: () => context.push('/admin/profile/edit'),
            showNotificationBell: true,
            showNotificationDot: showNotificationDot,
            onNotifications: () => context.go('/admin/notifications'),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1100 ? 4 : 2;
              final ratio = width >= 1100 ? 1.45 : 1.35;
              final isCompact = width <= 380;
              final cards = [
                _MetricCard(
                  label: l10n.adminTotalUsers,
                  value: _formatMetric(usersTotal),
                  icon: Icons.people_outline,
                  iconColor: AdminColors.primary,
                ),
                _MetricCard(
                  label: l10n.adminTotalLawyers,
                  value: _formatMetric(lawyersTotal),
                  icon: Icons.gavel_outlined,
                  iconColor: AdminColors.primary,
                ),
                _MetricCard(
                  label: l10n.adminTotalFeedbacks,
                  value: _formatMetric(feedbackTotal),
                  icon: Icons.thumb_up_alt_outlined,
                  iconColor: AdminColors.success,
                ),
                _MetricCard(
                  label: l10n.adminContactMessages,
                  value: _formatMetric(contactTotal),
                  icon: Icons.mail_outline,
                  iconColor: AdminColors.warning,
                ),
              ];
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: ratio,
                  mainAxisExtent: isCompact ? 132 : null,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) => cards[index],
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              );
            },
          ),
          const SizedBox(height: 16),
          _MetricWideCard(
            label: l10n.adminKnowledgeBase,
            value: _formatMetric(knowledgeCount),
            icon: Icons.folder_open,
            iconColor: AdminColors.accent,
          ),
          const SizedBox(height: 28),
          _SectionHeader(title: l10n.adminManagementHub),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1100 ? 4 : 3;
              final ratio = width >= 1100 ? 1.25 : 1.15;
              final isCompact = width <= 380;
              final tiles = [
                _HubTile(
                  title: l10n.adminNavUsers,
                  icon: Icons.people_outline,
                  onTap: () => context.go('/admin/users'),
                ),
                _HubTile(
                  title: l10n.adminNavKnowledge,
                  icon: Icons.auto_awesome_outlined,
                  onTap: () => context.go('/admin/knowledge'),
                ),
                _HubTile(
                  title: l10n.adminNavLawyers,
                  icon: Icons.gavel_outlined,
                  onTap: () => context.go('/admin/lawyers'),
                ),
                _HubTile(
                  title: l10n.adminNavFeedback,
                  icon: Icons.thumb_up_alt_outlined,
                  onTap: () => context.go('/admin/feedback'),
                ),
                _HubTile(
                  title: l10n.adminContactMessages,
                  icon: Icons.mail_outline,
                  onTap: () => context.go('/admin/contact'),
                ),
                _HubTile(
                  title: l10n.adminNavRights,
                  icon: Icons.shield_outlined,
                  onTap: () => context.go('/admin/rights'),
                ),
                _HubTile(
                  title: l10n.adminNavTemplates,
                  icon: Icons.description_outlined,
                  onTap: () => context.go('/admin/templates'),
                ),
                _HubTile(
                  title: l10n.adminNavPathways,
                  icon: Icons.account_tree_outlined,
                  onTap: () => context.go('/admin/pathways'),
                ),
                _HubTile(
                  title: l10n.adminNavChecklists,
                  icon: Icons.fact_check_outlined,
                  onTap: () => context.go('/admin/checklists'),
                ),
              ];
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: ratio,
                  mainAxisExtent: isCompact ? 120 : null,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) => tiles[index],
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              );
            },
          ),
          const SizedBox(height: 28),
          _RagOverviewCard(
            metrics: metricsAsync.asData?.value,
            days: ragDays,
            onDaysChanged: (value) =>
                ref.read(ragDaysProvider.notifier).state = value,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String name;
  final String role;
  final ImageProvider? avatarProvider;
  final VoidCallback onProfileTap;
  final bool showNotificationBell;
  final bool showNotificationDot;
  final VoidCallback onNotifications;

  const _DashboardHeader({
    required this.name,
    required this.role,
    required this.avatarProvider,
    required this.onProfileTap,
    required this.showNotificationBell,
    required this.showNotificationDot,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initials = name.trim().isNotEmpty
        ? name.trim()[0]
        : l10n.userInitialFallback;
    return Row(
      children: [
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(30),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AdminColors.surfaceAlt,
                foregroundImage: avatarProvider,
                child: avatarProvider == null
                    ? Text(
                        initials,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AdminColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AdminColors.accent,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        if (showNotificationBell)
          IconButton(
            onPressed: onNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),
                if (showNotificationDot)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AdminColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            color: AdminColors.textSecondary,
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      elevated: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const Spacer(),
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetricWideCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricWideCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      elevated: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdminColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AdminColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AdminColors.border.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HubTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AdminCard(
        elevated: true,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AdminColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Icon(icon, color: AdminColors.primary, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RagOverviewCard extends StatelessWidget {
  final RagMetrics? metrics;
  final int days;
  final ValueChanged<int> onDaysChanged;

  const _RagOverviewCard({
    required this.metrics,
    required this.days,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalDecisions = metrics == null
        ? 0
        : metrics!.decisions.answer +
              metrics!.decisions.outOfDomain +
              metrics!.decisions.noHits;
    final answerPct = totalDecisions == 0
        ? 0.0
        : metrics!.decisions.answer / totalDecisions * 100;
    final domainPct = totalDecisions == 0
        ? 0.0
        : metrics!.decisions.outOfDomain / totalDecisions * 100;
    final noHitsPct = totalDecisions == 0
        ? 0.0
        : metrics!.decisions.noHits / totalDecisions * 100;

    final latency = metrics?.performance.avgTotalTimeMs ?? 0;
    final accuracy = metrics?.quality.inDomainRate ?? 0;
    final distance = metrics?.quality.avgDistance ?? 0;
    final tokensUsed = metrics?.tokens.totalUsed ?? 0;
    final avgQuery = metrics?.tokens.avgPerQuery ?? 0;

    return AdminCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth <= 380;
              final title = Text(
                l10n.adminRagQualityOverview,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              );
              final daysDropdown = _RagDaysDropdown(
                value: days,
                onChanged: onDaysChanged,
              );
              final button = TextButton(
                onPressed: () => context.go('/admin/rag-queries'),
                style: TextButton.styleFrom(
                  foregroundColor: AdminColors.textSecondary,
                  minimumSize: const Size(0, AppButtonTokens.minHeight),
                  padding: AppButtonTokens.padding,
                  shape: AppButtonTokens.shape,
                  textStyle: AppButtonTokens.textStyle,
                  backgroundColor: AdminColors.surfaceAlt,
                ),
                child: Text(l10n.adminRagEvaluationLog),
              );
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: daysDropdown),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: button),
                  ],
                );
              }
              return Row(
                children: [
                  title,
                  const SizedBox(width: 12),
                  daysDropdown,
                  const Spacer(),
                  button,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            l10n.adminDecisionBreakdown,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AdminColors.textSecondary,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _DecisionBreakdownBar(
            answerCount: metrics?.decisions.answer ?? 0,
            domainCount: metrics?.decisions.outOfDomain ?? 0,
            noHitsCount: metrics?.decisions.noHits ?? 0,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DecisionStat(
                label: l10n.adminDecisionAnswer,
                value: _formatPercent(answerPct),
              ),
              _DecisionStat(
                label: l10n.adminDecisionDomain,
                value: _formatPercent(domainPct),
              ),
              _DecisionStat(
                label: l10n.adminDecisionNoHits,
                value: _formatPercent(noHitsPct),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AdminColors.border.withOpacity(0.6)),
          const SizedBox(height: 16),
          Row(
            children: [
              _RagStat(
                label: l10n.adminLatency,
                value: '${_formatNumber(latency.round())} ms',
              ),
              _VerticalDivider(),
              _RagStat(
                label: l10n.adminAccuracy,
                value: '${_formatPercent(accuracy)}%',
              ),
              _VerticalDivider(),
              _RagStat(
                label: l10n.adminDistance,
                value: _formatDecimal(distance, digits: 2),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                l10n.adminTokenUsage,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AdminColors.textSecondary,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                l10n.adminLiveStats,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AdminColors.primary,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TokenStatCard(
                  label: l10n.adminTotalUsed,
                  value: _formatCompact(tokensUsed),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TokenStatCard(
                  label: l10n.adminAvgQuery,
                  value: _formatNumber(avgQuery.round()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionBreakdownBar extends StatelessWidget {
  final int answerCount;
  final int domainCount;
  final int noHitsCount;

  const _DecisionBreakdownBar({
    required this.answerCount,
    required this.domainCount,
    required this.noHitsCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = answerCount + domainCount + noHitsCount;
    if (total == 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: AdminColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    final answerFlex = _segmentFlex(answerCount, total);
    final domainFlex = _segmentFlex(domainCount, total);
    final noHitsFlex = _segmentFlex(noHitsCount, total);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          if (answerFlex > 0)
            Expanded(
              flex: answerFlex,
              child: Container(height: 10, color: AdminColors.primary),
            ),
          if (domainFlex > 0)
            Expanded(
              flex: domainFlex,
              child: Container(height: 10, color: AdminColors.warning),
            ),
          if (noHitsFlex > 0)
            Expanded(
              flex: noHitsFlex,
              child: Container(height: 10, color: AdminColors.error),
            ),
        ],
      ),
    );
  }
}

class _DecisionStat extends StatelessWidget {
  final String label;
  final String value;

  const _DecisionStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AdminColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${value}%',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _RagDaysDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RagDaysDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AdminColors.textSecondary,
      fontWeight: FontWeight.w600,
    );
    final controlStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AdminColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.adminDaysLabel, style: style),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(
                Icons.expand_more,
                color: AdminColors.textSecondary,
                size: 18,
              ),
              isDense: true,
              style: controlStyle,
              items: const [
                DropdownMenuItem(value: 7, child: Text('7')),
                DropdownMenuItem(value: 30, child: Text('30')),
                DropdownMenuItem(value: 90, child: Text('90')),
              ],
              onChanged: (next) {
                if (next == null || next == value) return;
                onChanged(next);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RagStat extends StatelessWidget {
  final String label;
  final String value;

  const _RagStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AdminColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 46,
      color: AdminColors.border.withOpacity(0.6),
    );
  }
}

class _TokenStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _TokenStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

final NumberFormat _decimalFormatter = NumberFormat.decimalPattern();
final NumberFormat _compactFormatter = NumberFormat.compact();

String _formatMetric(int? value) {
  if (value == null) return '--';
  return _decimalFormatter.format(value);
}

String _formatNumber(int value) {
  return _decimalFormatter.format(value);
}

String _formatCompact(int value) {
  return _compactFormatter.format(value);
}

String _formatPercent(double value) {
  if (value.isNaN || value.isInfinite) {
    return '0.0';
  }
  return value.toStringAsFixed(1);
}

String _formatDecimal(double value, {int digits = 2}) {
  if (value.isNaN || value.isInfinite) {
    return '0.0';
  }
  return value.toStringAsFixed(digits);
}

int _segmentFlex(int count, int total) {
  if (count == 0 || total == 0) return 0;
  final value = (count / total * 1000).round();
  return value == 0 ? 1 : value;
}

int? _valueOrNull(AsyncValue<int> async) {
  return async.maybeWhen(data: (value) => value, orElse: () => null);
}
