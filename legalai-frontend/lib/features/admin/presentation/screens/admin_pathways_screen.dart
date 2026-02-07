import 'dart:convert';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../content/data/datasources/content_remote_data_source.dart';
import '../../../content/domain/models/content_models.dart';
import '../../../content/presentation/controllers/content_controller.dart';
import '../../../../core/content/content_sync_provider.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminPathwaysProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(pathwaysProvider().future);
});

class AdminPathwaysScreen extends ConsumerWidget {
  const AdminPathwaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathwaysAsync = ref.watch(adminPathwaysProvider);
    final l10n = AppLocalizations.of(context)!;

    return AdminPage(
      title: l10n.adminNavPathways,
      subtitle: l10n.adminPathwaysSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showPathwayForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminNewPathway),
        ),
      ],
      body: pathwaysAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoPathwaysTitle,
                message: l10n.adminNoPathwaysMessage,
                icon: Icons.account_tree_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pathway = items[index];
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
                      child: Icon(Icons.account_tree_outlined, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pathway.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pathway.category} - ${pathway.language}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showPathwayForm(context, ref, pathway);
                        } else if (value == 'delete') {
                          await _deletePathway(context, ref, pathway.id);
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

  Future<void> _showPathwayForm(BuildContext context, WidgetRef ref, LegalPathway? pathway) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: pathway?.title ?? '');
    final summaryController = TextEditingController(text: pathway?.summary ?? '');
    final stepsController = TextEditingController(
      text: pathway == null ? '' : jsonEncode(pathway.steps.map((s) => s.toJson()).toList()),
    );
    final categoryController = TextEditingController(text: pathway?.category ?? '');
    final tagsController = TextEditingController(text: (pathway?.tags ?? []).join(', '));
    String language = pathway?.language ?? 'en';

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(pathway == null ? l10n.adminCreatePathway : l10n.adminEditPathway),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: InputDecoration(labelText: l10n.title)),
                  const SizedBox(height: 8),
                  TextField(controller: summaryController, decoration: InputDecoration(labelText: l10n.adminSummary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: stepsController,
                    decoration: InputDecoration(labelText: l10n.adminStepsJson),
                    maxLines: 6,
                  ),
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

      if (titleController.text.trim().isEmpty) {
        if (context.mounted) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.titleRequired)),
          );
        }
        return;
      }

      List<dynamic> steps;
      try {
        final decoded = jsonDecode(stepsController.text.trim());
        if (decoded is! List) {
          throw FormatException(l10n.adminStepsMustBeList);
        }
        steps = decoded;
      } catch (e) {
        if (context.mounted) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.adminInvalidStepsJson)),
          );
        }
        return;
      }

      final data = {
        'title': titleController.text.trim(),
        'summary': summaryController.text.trim().isEmpty ? null : summaryController.text.trim(),
        'steps': steps,
        'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
        'language': language,
        'tags': _parseTags(tagsController.text),
      };
      final remote = ref.read(contentRemoteDataSourceProvider);
      if (pathway == null) {
        await remote.createPathway(data);
      } else {
        await remote.updatePathway(pathway.id, data);
      }
      await ref.read(contentSyncControllerProvider).refresh();
      ref.invalidate(pathwaysProvider());
      ref.invalidate(adminPathwaysProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    } finally {
      titleController.dispose();
      summaryController.dispose();
      stepsController.dispose();
      categoryController.dispose();
      tagsController.dispose();
    }
  }

  Future<void> _deletePathway(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeletePathwayTitle),
        content: Text(l10n.adminDeletePathwayConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contentRemoteDataSourceProvider).deletePathway(id);
      await ref.read(contentSyncControllerProvider).refresh();
      ref.invalidate(pathwaysProvider());
      ref.invalidate(adminPathwaysProvider);
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
