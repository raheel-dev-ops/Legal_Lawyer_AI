import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminContactMessagesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getContactMessages();
});

class AdminContactMessagesScreen extends ConsumerWidget {
  const AdminContactMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(adminContactMessagesProvider);
    final l10n = AppLocalizations.of(context)!;

    return AdminPage(
      title: l10n.adminContactMessages,
      subtitle: l10n.adminContactSubtitle,
      body: messagesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoMessagesTitle,
                message: l10n.adminNoMessagesMessage,
                icon: Icons.support_agent_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final msg = items[index];
              final subject = (msg['subject'] ?? '').toString();
              final name = (msg['fullName'] ?? '').toString();
              final email = (msg['email'] ?? '').toString();
              return InkWell(
                onTap: () => context.go('/admin/contact/${msg['id']}'),
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
                        child: Icon(Icons.mail_outline, color: AdminColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Text(
                            subject.isEmpty ? l10n.adminNoSubject : subject,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$name - $email',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 16, color: AdminColors.textSecondary),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }
}

class AdminContactMessageDetailScreen extends ConsumerWidget {
  final int messageId;
  const AdminContactMessageDetailScreen({super.key, required this.messageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AdminPage(
      title: l10n.adminMessageDetailTitle,
      subtitle: l10n.adminMessageDetailSubtitle,
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(adminRepositoryProvider).getContactMessage(messageId),
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
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminInfoRow(label: l10n.name, value: data['fullName']?.toString() ?? ''),
                    AdminInfoRow(label: l10n.email, value: data['email']?.toString() ?? ''),
                    AdminInfoRow(label: l10n.phone, value: data['phone']?.toString() ?? ''),
                    AdminInfoRow(label: l10n.subject, value: data['subject']?.toString() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.message,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['description']?.toString() ?? '',
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
