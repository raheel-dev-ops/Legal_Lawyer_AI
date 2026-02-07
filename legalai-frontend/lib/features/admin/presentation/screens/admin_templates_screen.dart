import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../content/data/datasources/content_remote_data_source.dart';
import '../../../content/domain/models/content_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/content/content_sync_provider.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminTemplatesProvider = FutureProvider.autoDispose((ref) async {
  final appLanguage = ref.watch(appLanguageProvider);
  final user = ref.watch(authControllerProvider).value;
  final language = appLanguage.isNotEmpty ? appLanguage : (user?.language ?? 'en');
  return ref.watch(contentRemoteDataSourceProvider).getTemplates(language: language);
});

class AdminTemplatesScreen extends ConsumerWidget {
  const AdminTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(adminTemplatesProvider);
    final l10n = AppLocalizations.of(context)!;

    return AdminPage(
      title: l10n.adminNavTemplates,
      subtitle: l10n.adminTemplatesSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showTemplateForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminNewTemplate),
        ),
      ],
      body: templatesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoTemplatesTitle,
                message: l10n.adminNoTemplatesMessage,
                icon: Icons.description_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final template = items[index];
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
                      child: Icon(Icons.description_outlined, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${template.category} - ${template.language}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showTemplateForm(context, ref, template);
                        } else if (value == 'delete') {
                          await _deleteTemplate(context, ref, template.id);
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

  Future<void> _showTemplateForm(BuildContext context, WidgetRef ref, LegalTemplate? template) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: template?.title ?? '');
    final descController = TextEditingController(text: template?.description ?? '');
    final bodyController = TextEditingController(text: template?.body ?? '');
    final categoryController = TextEditingController(text: template?.category ?? '');
    final tagsController = TextEditingController(text: (template?.tags ?? []).join(', '));
    String language = template?.language ?? 'en';

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(template == null ? l10n.adminCreateTemplate : l10n.adminEditTemplate),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: InputDecoration(labelText: l10n.title)),
                  const SizedBox(height: 8),
                  TextField(controller: descController, decoration: InputDecoration(labelText: l10n.adminDescription)),
                  const SizedBox(height: 8),
                  TextField(controller: bodyController, decoration: InputDecoration(labelText: l10n.adminBody), maxLines: 6),
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

      if (titleController.text.trim().isEmpty || bodyController.text.trim().isEmpty) {
        if (context.mounted) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.adminTitleBodyRequired)),
          );
        }
        return;
      }
      final data = {
        'title': titleController.text.trim(),
        'description': descController.text.trim().isEmpty ? null : descController.text.trim(),
        'body': bodyController.text.trim(),
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'language': language,
        'tags': _parseTags(tagsController.text),
      };
      final remote = ref.read(contentRemoteDataSourceProvider);
      if (template == null) {
        await remote.createTemplate(data);
      } else {
        await remote.updateTemplate(template.id, data);
      }
      ref.invalidate(contentSyncProvider);
      ref.invalidate(adminTemplatesProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    } finally {
      titleController.dispose();
      descController.dispose();
      bodyController.dispose();
      categoryController.dispose();
      tagsController.dispose();
    }
  }

  Future<void> _deleteTemplate(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteTemplateTitle),
        content: Text(l10n.adminDeleteTemplateConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contentRemoteDataSourceProvider).deleteTemplate(id);
      ref.invalidate(contentSyncProvider);
      ref.invalidate(adminTemplatesProvider);
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
