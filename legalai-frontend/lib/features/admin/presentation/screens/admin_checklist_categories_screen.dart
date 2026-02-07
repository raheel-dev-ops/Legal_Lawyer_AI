import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../checklists/data/datasources/checklists_remote_data_source.dart';
import '../../../checklists/domain/models/checklist_models.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminChecklistCategoriesProvider = FutureProvider.autoDispose<List<ChecklistCategory>>((ref) async {
  return ref.watch(checklistsRepositoryProvider).getCategories();
});

class AdminChecklistCategoriesScreen extends ConsumerWidget {
  const AdminChecklistCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminChecklistCategoriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return AdminPage(
      title: l10n.adminNavChecklists,
      subtitle: l10n.adminChecklistsSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showCategoryForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminNewCategory),
        ),
      ],
      body: categoriesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoCategoriesTitle,
                message: l10n.adminNoCategoriesMessage,
                icon: Icons.checklist_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = items[index];
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
                      child: Icon(Icons.checklist_outlined, color: AdminColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.adminOrderValue(category.order),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showCategoryForm(context, ref, category);
                        } else if (value == 'delete') {
                          await _deleteCategory(context, ref, category.id);
                        } else if (value == 'items') {
                          context.go('/admin/checklists/${category.id}?title=${Uri.encodeComponent(category.title)}');
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'items', child: Text(l10n.adminManageItems)),
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

  Future<void> _showCategoryForm(BuildContext context, WidgetRef ref, ChecklistCategory? category) async {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: category?.title ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');
    final orderController = TextEditingController(text: category?.order.toString() ?? '0');

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(category == null ? l10n.adminCreateCategory : l10n.adminEditCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: l10n.title)),
              const SizedBox(height: 8),
              TextField(controller: iconController, decoration: InputDecoration(labelText: l10n.adminIconOptional)),
              const SizedBox(height: 8),
              TextField(
                controller: orderController,
                decoration: InputDecoration(labelText: l10n.adminOrderLabel),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
          ],
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
      final order = int.tryParse(orderController.text.trim()) ?? 0;
      if (category == null) {
        await ref.read(checklistsRepositoryProvider).createCategory(
              title: titleController.text.trim(),
              icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
              order: order,
            );
      } else {
        await ref.read(checklistsRepositoryProvider).updateCategory(
              category.id,
              title: titleController.text.trim(),
              icon: iconController.text.trim().isEmpty ? null : iconController.text.trim(),
              order: order,
            );
      }
      ref.invalidate(adminChecklistCategoriesProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    } finally {
      titleController.dispose();
      iconController.dispose();
      orderController.dispose();
    }
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteCategoryTitle),
        content: Text(l10n.adminDeleteCategoryConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(checklistsRepositoryProvider).deleteCategory(id);
      ref.invalidate(adminChecklistCategoriesProvider);
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    }
  }
}
