import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../theme/admin_theme.dart';

class AdminShellScreen extends ConsumerWidget {
  final Widget child;
  final String location;

  const AdminShellScreen({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomItems = _bottomNavItems(l10n);
    final hideTopBar =
        location.startsWith('/admin/overview') ||
        location.startsWith('/admin/settings') ||
        location.startsWith('/admin/profile') ||
        location.startsWith('/admin/change-password');
    final showBottomNav = location.startsWith('/admin');
    final themeMode = ref.watch(themeModeProvider);
    final brightness = themeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : (themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);
    final themeData = AdminTheme.forBrightness(brightness);

    return Theme(
      data: themeData,
      child: PopScope(
        canPop: location.startsWith('/admin/overview'),
        onPopInvoked: (didPop) {
          if (didPop) return;
          if (location.startsWith('/admin/contact/')) {
            context.go('/admin/contact');
            return;
          }
          if (location.startsWith('/admin/feedback/')) {
            context.go('/admin/feedback');
            return;
          }
          if (location.startsWith('/admin/rag-queries/')) {
            context.go('/admin/rag-queries');
            return;
          }
          if (location.startsWith('/admin/checklists/')) {
            context.go('/admin/checklists');
            return;
          }
          if (location.startsWith('/admin/profile')) {
            context.go('/admin/overview');
            return;
          }
          if (location.startsWith('/admin/change-password')) {
            context.go('/admin/settings');
            return;
          }
          if (!location.startsWith('/admin/overview')) {
            context.go('/admin/overview');
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: showBottomNav
              ? _AdminBottomNav(
                  items: bottomItems,
                  selectedIndex: _bottomIndexForLocation(location),
                  onSelect: (index) => context.go(bottomItems[index].route),
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                if (!hideTopBar)
                  const _AdminTopBar(),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width >= 900 ? 28 : 18,
                          vertical: 20,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final bool expandBody;
  final Widget? header;

  const AdminPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.body,
    this.expandBody = true,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AdminColors.textSecondary,
        );

    final headerWidget = header ??
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle!, style: subtitleStyle),
                  ],
                ],
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: actions!,
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerWidget,
        const SizedBox(height: 18),
        if (expandBody) Expanded(child: body) else body,
      ],
    );
  }
}

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.elevated = false,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedShadows = shadows ??
        (elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: isDark ? 24 : 18,
                  offset: Offset(0, isDark ? 16 : 10),
                ),
              ]
            : []);
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AdminColors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AdminColors.border),
        boxShadow: resolvedShadows,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
        );
    return AdminCard(
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
                const SizedBox(height: 6),
                Text(value, style: valueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const AdminInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AdminColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const AdminEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AdminColors.textSecondary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.adminConsoleTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;

  const _AdminNavItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });
}

List<_AdminNavItem> _bottomNavItems(AppLocalizations l10n) {
  return [
    _AdminNavItem(
      label: l10n.adminNavDashboard,
      route: '/admin/overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    _AdminNavItem(
      label: l10n.adminNavSettings,
      route: '/admin/settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];
}

int _bottomIndexForLocation(String location) {
  if (location.startsWith('/admin/settings')) return 1;
  if (location.startsWith('/admin/profile')) return 1;
  if (location.startsWith('/admin/change-password')) return 1;
  return 0;
}

class _AdminBottomNav extends StatelessWidget {
  final List<_AdminNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _AdminBottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.background,
        border: Border(top: BorderSide(color: AdminColors.border.withOpacity(0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: isDark ? 18 : 12,
            offset: Offset(0, isDark ? -8 : -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == selectedIndex;
              final color = selected ? AdminColors.primary : AdminColors.textSecondary;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelect(index),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(selected ? item.selectedIcon : item.icon, color: color),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
