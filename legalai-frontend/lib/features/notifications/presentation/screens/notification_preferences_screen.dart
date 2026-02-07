import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/utils/app_notifications.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/notification_preferences.dart';
import '../controllers/notification_controller.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final preferencesAsync = ref.watch(notificationPreferencesProvider);
    final cachedPrefs = ref.read(appPreferencesProvider).getNotificationPreferences();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationPreferences),
      ),
      body: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
              child: preferencesAsync.when(
                data: (prefs) => _buildPreferences(context, ref, prefs, enabled: true),
                loading: () => _buildPreferences(
                  context,
                  ref,
                  cachedPrefs ??
                      const NotificationPreferences(
                        contentUpdates: true,
                        lawyerUpdates: true,
                        reminderNotifications: true,
                      ),
                  enabled: cachedPrefs != null,
                ),
                error: (e, _) => Text(ErrorMapper.from(e).userMessage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePrefs(
    BuildContext context,
    WidgetRef ref, {
    bool? contentUpdates,
    bool? lawyerUpdates,
    bool? reminderNotifications,
  }) async {
    try {
      await ref.read(notificationControllerProvider.notifier).updatePreferences(
            contentUpdates: contentUpdates,
            lawyerUpdates: lawyerUpdates,
            reminderNotifications: reminderNotifications,
          );
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    }
  }

  Widget _buildPreferences(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences prefs, {
    required bool enabled,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notificationPreferences,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: AppResponsive.spacing(context, 12)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: prefs.contentUpdates,
          onChanged: enabled
              ? (value) => _updatePrefs(
                    context,
                    ref,
                    contentUpdates: value,
                  )
              : null,
          title: Text(l10n.contentUpdates),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: prefs.lawyerUpdates,
          onChanged: enabled
              ? (value) => _updatePrefs(
                    context,
                    ref,
                    lawyerUpdates: value,
                  )
              : null,
          title: Text(l10n.lawyerUpdates),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: prefs.reminderNotifications,
          onChanged: enabled
              ? (value) => _updatePrefs(
                    context,
                    ref,
                    reminderNotifications: value,
                  )
              : null,
          title: Text(l10n.reminderNotifications),
        ),
      ],
    );
  }
}
