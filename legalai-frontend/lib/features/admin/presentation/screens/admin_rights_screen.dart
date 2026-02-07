import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../content/data/datasources/content_remote_data_source.dart';
import '../../../../core/content/content_sync_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../content/domain/models/content_models.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminRightsProvider = FutureProvider.autoDispose((ref) async {
  final appLanguage = ref.watch(appLanguageProvider);
  final user = ref.watch(authControllerProvider).value;
  final language = appLanguage.isNotEmpty ? appLanguage : (user?.language ?? 'en');
  return ref.watch(contentRemoteDataSourceProvider).getRights(language: language);
});

class AdminRightsScreen extends ConsumerWidget {
  const AdminRightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rightsAsync = ref.watch(adminRightsProvider);
    final l10n = AppLocalizations.of(context)!;

    return AdminPage(
      title: l10n.adminNavRights,
      subtitle: l10n.adminRightsSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showRightForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminNewRight),
        ),
      ],
      body: rightsAsync.when(
        data: (rights) {
          if (rights.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoRightsTitle,
                message: l10n.adminNoRightsMessage,
                icon: Icons.policy_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: rights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final right = rights[index];
              return AdminCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.policy_outlined, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            right.topic,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${right.category} - ${right.language}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showRightForm(context, ref, right);
                        } else if (value == 'delete') {
                          await _deleteRight(context, ref, right.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                  ],
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

  Future<void> _showRightForm(BuildContext context, WidgetRef ref, LegalRight? right) async {
    final l10n = AppLocalizations.of(context)!;
    final topicController = TextEditingController(text: right?.topic ?? '');
    final bodyController = TextEditingController(text: right?.body ?? '');
    final categoryController = TextEditingController(text: right?.category ?? '');
    final tagsController = TextEditingController(text: (right?.tags ?? []).join(', '));
    String language = right?.language ?? 'en';

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(right == null ? l10n.adminCreateRight : l10n.adminEditRight),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: topicController, decoration: InputDecoration(labelText: l10n.adminTopic)),
                  const SizedBox(height: 8),
                  TextField(controller: bodyController, decoration: InputDecoration(labelText: l10n.adminBody), maxLines: 5),
                  const SizedBox(height: 8),
                  TextField(controller: categoryController, decoration: InputDecoration(labelText: l10n.category)),
                  const SizedBox(height: 8),
                  TextField(controller: tagsController, decoration: InputDecoration(labelText: l10n.adminTagsCommaSeparated)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: language,
                    decoration: InputDecoration(labelText: l10n.language),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                      DropdownMenuItem(value: 'ur', child: Text(l10n.languageUrdu)),
                    ],
                    onChanged: (value) => setState(() => language = value ?? 'en'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
            ],
          ),
        ),
      );

      if (result != true) return;

      if (topicController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
        if (context.mounted) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.adminTopicBodyRequired)),
          );
        }
        return;
      }
      final data = {
        'topic': topicController.text.trim(),
        'body': bodyController.text.trim(),
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'language': language,
        'tags': _parseTags(tagsController.text),
      };
      final remote = ref.read(contentRemoteDataSourceProvider);
      if (right == null) {
        await remote.createRight(data);
      } else {
        await remote.updateRight(right.id, data);
      }
      ref.invalidate(contentSyncProvider);
      ref.invalidate(adminRightsProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    } finally {
      topicController.dispose();
      bodyController.dispose();
      categoryController.dispose();
      tagsController.dispose();
    }
  }

  Future<void> _deleteRight(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteRightTitle),
        content: Text(l10n.adminDeleteRightConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contentRemoteDataSourceProvider).deleteRight(id);
      ref.invalidate(contentSyncProvider);
      ref.invalidate(adminRightsProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    }
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
