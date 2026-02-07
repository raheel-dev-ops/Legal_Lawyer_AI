import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/notification_controller.dart';
import '../../domain/models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_markAllRead);
  }

  Future<void> _markAllRead() async {
    try {
      await ref.read(notificationControllerProvider.notifier).markAllRead();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(notificationsProvider());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(notificationUnreadCountProvider);
        },
        child: ListView(
          padding: AppResponsive.pagePadding(context),
          children: [
            notificationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 20)),
                    child: Text(l10n.noNotifications),
                  );
                }
                return Column(
                  children: items.map((item) => _NotificationTile(notification: item)).toList(),
                );
              },
              loading: () => Padding(
                padding: EdgeInsets.all(AppResponsive.spacing(context, 12)),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 12)),
                child: Text(ErrorMapper.from(e).userMessage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final createdAt = notification.createdAt;
    final dateLabel = createdAt == null
        ? ''
        : DateFormat('MMM d, h:mm a').format(createdAt.toLocal());
    return Card(
      margin: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!notification.isRead) {
            await ref.read(notificationControllerProvider.notifier).markRead(notification.id);
          }
          final route = notification.route;
          if (route != null && context.mounted) {
            context.push(route);
          }
        },
        child: Padding(
          padding: EdgeInsets.all(AppResponsive.spacing(context, 14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: notification.type, isRead: notification.isRead),
              SizedBox(width: AppResponsive.spacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 4)),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    if (dateLabel.isNotEmpty) ...[
                      SizedBox(height: AppResponsive.spacing(context, 6)),
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;
  final bool isRead;

  const _NotificationIcon({required this.type, required this.isRead});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = _iconForType(type);
    final color = isRead ? scheme.onSurfaceVariant : scheme.primary;
    return Container(
      width: AppResponsive.spacing(context, 40),
      height: AppResponsive.spacing(context, 40),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'RIGHT_CREATED':
      case 'RIGHT_UPDATED':
        return Icons.gavel_outlined;
      case 'TEMPLATE_CREATED':
      case 'TEMPLATE_UPDATED':
        return Icons.description_outlined;
      case 'LAWYER_CREATED':
      case 'LAWYER_UPDATED':
      case 'LAWYER_DEACTIVATED':
        return Icons.people_alt_outlined;
      case 'REMINDER_DUE':
        return Icons.alarm_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
