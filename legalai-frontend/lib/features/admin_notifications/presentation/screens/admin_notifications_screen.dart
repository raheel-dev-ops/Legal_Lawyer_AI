import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../admin/presentation/theme/admin_theme.dart';
import '../../../admin/presentation/widgets/admin_layout.dart';
import '../../domain/models/admin_notification_model.dart';
import '../controllers/admin_notifications_controller.dart';

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(adminNotificationsProvider);

    return AdminPage(
      title: l10n.adminNotificationsTitle,
      subtitle: l10n.adminNotificationsSubtitle,
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoNotificationsTitle,
                message: l10n.adminNoNotificationsMessage,
                icon: Icons.notifications_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = items[index];
              return _AdminNotificationTile(notification: notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          final mapped = ErrorMapper.from(err);
          final message = mapped is AppException ? mapped.userMessage : err.toString();
          return Center(child: Text(message));
        },
      ),
    );
  }
}

class _AdminNotificationTile extends ConsumerWidget {
  final AdminNotification notification;

  const _AdminNotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final name = notification.fullName ?? l10n.unknown;
    final subject = notification.subject ?? l10n.adminNoSubject;
    final timestamp = _formatTimestamp(notification.createdAt, l10n);
    final icon = _iconForKind(notification.kind);
    final isRead = notification.isRead;

    return InkWell(
      onTap: () async {
        if (!isRead) {
          await ref.read(adminNotificationsControllerProvider.notifier).markRead(notification.id);
        }
        final route = notification.route;
        if (route != null) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: AdminCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AdminColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AdminColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AdminColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timestamp,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AdminColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForKind(String? kind) {
    if (kind == 'feedback') return Icons.feedback_outlined;
    if (kind == 'contact') return Icons.mail_outline;
    return Icons.notifications_outlined;
  }

  String _formatTimestamp(DateTime? value, AppLocalizations l10n) {
    if (value == null) return '';
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return DateFormat.yMMMd().format(value);
  }
}
