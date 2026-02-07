import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_button_tokens.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/content/content_sync_provider.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../user_features/presentation/controllers/user_controller.dart';
import '../../../../core/utils/media_url.dart';
import '../../../user_features/presentation/utils/activity_formatters.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('dashboard');
      ref.read(contentSyncProvider.future);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).value;
    final activityAsync = ref.watch(userActivityProvider);
    final padding = AppResponsive.pagePadding(context);
    final maxWidth = AppResponsive.maxContentWidth(context);
    final name = user?.name ?? l10n.guestUser;
    final avatarProvider = resolveMediaImageProvider(
      context,
      user?.avatarPath,
      width: AppResponsive.spacing(context, 52),
      height: AppResponsive.spacing(context, 52),
    );
    final toolboxItems = _toolboxItems(context, l10n);
    final scheme = Theme.of(context).colorScheme;
    final unreadCountAsync = ref.watch(notificationUnreadCountProvider);
    final hasUnreadNotifications = unreadCountAsync.maybeWhen(
      data: (count) => count > 0,
      orElse: () => false,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                padding.top,
                padding.right,
                AppResponsive.spacing(context, 28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderRow(
                    name: name,
                    greeting: l10n.dashboardGreeting,
                    avatarProvider: avatarProvider,
                    showNotificationDot: hasUnreadNotifications,
                    onNotifications: () => context.push('/notifications'),
                    onProfileTap: () => context.push('/profile/edit'),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 18)),
                  Row(
                    children: [
                      Expanded(
                        child: _SearchBar(
                          hint: l10n.dashboardSearchHint,
                          onTap: () => context.push('/search'),
                        ),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 12)),
                      _SosButton(
                        label: l10n.sosLabel,
                        onTap: () => context.push('/emergency'),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 14)),
                  const SafeModeBanner(),
                  SizedBox(height: AppResponsive.spacing(context, 18)),
                  _AiAssistantCard(
                    badge: l10n.aiPoweredBadge,
                    title: l10n.aiLegalAssistant,
                    subtitle: l10n.aiAssistantSubtitle,
                    ctaLabel: l10n.startNewChat,
                    onTap: () => context.go('/chat'),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 22)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.legalToolboxTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        l10n.dashboardItemsCount(toolboxItems.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 14)),
                  _ToolboxGrid(items: toolboxItems),
                  SizedBox(height: AppResponsive.spacing(context, 26)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.dashboardRecentActivity,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () => context.push('/activity'),
                        child: Text(l10n.dashboardHistory.toUpperCase()),
                      ),
                    ],
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 8)),
                  activityAsync.when(
                    data: (items) => _ActivityList(items: items.take(2).toList()),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Padding(
                      padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 12)),
                      child: Text(l10n.noActivity),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String name;
  final String greeting;
    final ImageProvider? avatarProvider;
  final bool showNotificationDot;
  final VoidCallback onNotifications;
  final VoidCallback onProfileTap;

  const _HeaderRow({
    required this.name,
    required this.greeting,
    required this.avatarProvider,
    required this.showNotificationDot,
    required this.onNotifications,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 26)),
          child: CircleAvatar(
            radius: AppResponsive.spacing(context, 26),
            backgroundColor: scheme.primary.withOpacity(0.12),
            backgroundImage: avatarProvider,
            child: avatarProvider == null
                ? Text(
                    initials,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  )
                : null,
          ),
        ),
        SizedBox(width: AppResponsive.spacing(context, 14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              SizedBox(height: AppResponsive.spacing(context, 2)),
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Container(
          width: AppResponsive.spacing(context, 44),
          height: AppResponsive.spacing(context, 44),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onNotifications,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),
                if (showNotificationDot)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: scheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;

  const _SearchBar({
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppResponsive.spacing(context, 16),
            vertical: AppResponsive.spacing(context, 14),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: scheme.onSurfaceVariant),
              SizedBox(width: AppResponsive.spacing(context, 10)),
              Expanded(
                child: Text(
                  hint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SosButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        minimumSize: const Size(0, AppButtonTokens.minHeight),
        padding: AppButtonTokens.padding,
        shape: AppButtonTokens.shape,
        elevation: 0,
        textStyle: AppButtonTokens.textStyle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18),
          SizedBox(width: AppResponsive.spacing(context, 6)),
          Text(label),
        ],
      ),
    );
  }
}

class _AiAssistantCard extends StatelessWidget {
  final String badge;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;

  const _AiAssistantCard({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkBase = Color.alphaBlend(scheme.tertiary.withOpacity(0.35), scheme.surface);
    final darkDeep = Color.alphaBlend(scheme.primary.withOpacity(0.2), scheme.surfaceVariant);
    final cardColor = isDark ? darkBase : scheme.primary;
    final onCard = isDark ? Colors.white : scheme.onPrimary;
    final badgeBg = isDark ? Colors.white.withOpacity(0.12) : scheme.onPrimary.withOpacity(0.12);
    final badgeText = isDark ? Colors.white.withOpacity(0.9) : scheme.onPrimary.withOpacity(0.9);
    final buttonBg = isDark ? Colors.white : scheme.onPrimary;
    final buttonFg = isDark ? scheme.tertiaryContainer : scheme.primary;
    return Container(
      padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: cardColor,
        gradient: isDark
            ? LinearGradient(
                colors: [darkBase, darkDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (isDark) ...[
            Positioned(
              right: -20,
              bottom: 10,
              child: Transform.rotate(
                angle: -0.6,
                child: Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: 36,
              child: Transform.rotate(
                angle: -0.6,
                child: Container(
                  width: 90,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ] else
            Positioned(
              right: -10,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.4,
                child: Icon(
                  Icons.gavel,
                  size: 140,
                  color: scheme.onPrimary.withOpacity(0.1),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppResponsive.spacing(context, 12),
                  vertical: AppResponsive.spacing(context, 6),
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  badge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: badgeText,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 12)),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: onCard,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 6)),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onCard.withOpacity(isDark ? 0.78 : 0.8),
                    ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 16)),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBg,
                  foregroundColor: buttonFg,
                  padding: AppButtonTokens.padding,
                  shape: AppButtonTokens.shape,
                  textStyle: AppButtonTokens.textStyle,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ctaLabel),
                    SizedBox(width: AppResponsive.spacing(context, 8)),
                    const Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolboxItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ToolboxItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

List<_ToolboxItem> _toolboxItems(BuildContext context, AppLocalizations l10n) {
  final scheme = Theme.of(context).colorScheme;
  return [
    _ToolboxItem(
      title: l10n.legalRights,
      icon: Icons.balance,
      color: scheme.secondary,
      onTap: () => context.push('/browse?tab=rights'),
    ),
    _ToolboxItem(
      title: l10n.templates,
      icon: Icons.description,
      color: scheme.tertiary,
      onTap: () => context.push('/browse?tab=templates'),
    ),
    _ToolboxItem(
      title: l10n.pathways,
      icon: Icons.map_outlined,
      color: scheme.primary,
      onTap: () => context.push('/browse?tab=pathways'),
    ),
    _ToolboxItem(
      title: l10n.lawyers,
      icon: Icons.people_alt_outlined,
      color: AppPalette.success,
      onTap: () => context.push('/directory'),
    ),
    _ToolboxItem(
      title: l10n.myDrafts,
      icon: Icons.article_outlined,
      color: AppPalette.success,
      onTap: () => context.push('/drafts'),
    ),
    _ToolboxItem(
      title: l10n.checklists,
      icon: Icons.check_circle_outline,
      color: scheme.error,
      onTap: () => context.push('/checklists'),
    ),
    _ToolboxItem(
      title: l10n.more,
      icon: Icons.grid_view,
      color: scheme.onSurfaceVariant,
      onTap: () => _showMore(context, l10n),
    ),
  ];
}

void _showMore(BuildContext context, AppLocalizations l10n) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: AppResponsive.pagePadding(context),
          child: ListView(
            shrinkWrap: true,
            children: [
              _MoreItem(title: l10n.notifications, icon: Icons.notifications_active_outlined, onTap: () => context.push('/notifications')),
              _MoreItem(title: l10n.bookmarks, icon: Icons.bookmark_border, onTap: () => context.push('/bookmarks')),
              _MoreItem(title: l10n.reminders, icon: Icons.notifications_outlined, onTap: () => context.push('/reminders')),
              _MoreItem(title: l10n.support, icon: Icons.support_agent_outlined, onTap: () => context.push('/support')),
              _MoreItem(title: l10n.activityHistory, icon: Icons.history, onTap: () => context.push('/activity')),
            ],
          ),
        ),
      );
    },
  );
}

class _MoreItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MoreItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: scheme.primary.withOpacity(0.1),
        child: Icon(icon, color: scheme.primary),
      ),
      title: Text(title),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

class _ToolboxGrid extends StatelessWidget {
  final List<_ToolboxItem> items;

  const _ToolboxGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 360 ? 2 : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppResponsive.spacing(context, 12),
        mainAxisSpacing: AppResponsive.spacing(context, 12),
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: item.onTap,
            child: Container(
              padding: EdgeInsets.all(AppResponsive.spacing(context, 12)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: AppResponsive.spacing(context, 46),
                    height: AppResponsive.spacing(context, 46),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 10)),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _ActivityList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 12)),
        child: Text(AppLocalizations.of(context)!.noActivity),
      );
    }

    return Column(
      children: items.map((item) => _ActivityCard(item: item)).toList(),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = (item['type'] ?? '').toString();
    final payload = item['payload'] is Map<String, dynamic> ? item['payload'] as Map<String, dynamic> : <String, dynamic>{};
    final createdAt = DateTime.tryParse((item['createdAt'] ?? '').toString());
    final details = activityDetails(l10n, type, payload);
    final time = formatActivityTime(l10n, createdAt);

    return Container(
      margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
      padding: EdgeInsets.all(AppResponsive.spacing(context, 14)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: AppResponsive.spacing(context, 44),
            height: AppResponsive.spacing(context, 44),
            decoration: BoxDecoration(
              color: details.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(details.icon, color: details.color),
          ),
          SizedBox(width: AppResponsive.spacing(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppResponsive.spacing(context, 4)),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppResponsive.spacing(context, 10),
              vertical: AppResponsive.spacing(context, 6),
            ),
            decoration: BoxDecoration(
              color: details.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              details.badge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: details.color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
