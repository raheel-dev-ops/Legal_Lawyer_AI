import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../controllers/user_controller.dart';
import '../controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';
import '../utils/activity_formatters.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('activity_log');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activityAsync = ref.watch(userActivityProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activityLog)),
      body: activityAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return ListView(
              padding: AppResponsive.pagePadding(context),
              children: [
                const SafeModeBanner(),
                SizedBox(height: AppResponsive.spacing(context, 16)),
                Center(child: Text(l10n.noActivity)),
              ],
            );
          }
          return ListView.separated(
            padding: AppResponsive.pagePadding(context),
            itemCount: logs.length,
            separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    const SafeModeBanner(),
                    SizedBox(height: AppResponsive.spacing(context, 16)),
                    _ActivityTile(log: logs[index]),
                  ],
                );
              }
              return _ActivityTile(log: logs[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> log;

  const _ActivityTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final type = (log['type'] ?? '').toString();
    final payload = log['payload'] is Map<String, dynamic> ? log['payload'] as Map<String, dynamic> : <String, dynamic>{};
    final createdAt = DateTime.tryParse((log['createdAt'] ?? '').toString());
    final details = activityDetails(l10n, type, payload);
    final time = formatActivityTime(l10n, createdAt);
    return Card(
      child: ListTile(
        leading: Icon(details.icon, color: details.color),
        title: Text(details.title),
        subtitle: Text(
          time,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        trailing: Container(
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
      ),
    );
  }
}
