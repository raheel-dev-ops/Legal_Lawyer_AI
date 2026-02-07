import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../checklists/data/datasources/checklists_remote_data_source.dart';
import '../../../checklists/domain/models/checklist_models.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminChecklistItemsProvider = FutureProvider.autoDispose.family<List<ChecklistItem>, int>((ref, categoryId) async {
  return ref.watch(checklistsRepositoryProvider).getItems(categoryId);
});

class AdminChecklistItemsScreen extends ConsumerWidget {
  final int categoryId;
  final String? categoryTitle;

  const AdminChecklistItemsScreen({
    super.key,
    required this.categoryId,
    this.categoryTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId <= 0) {
      final l10n = AppLocalizations.of(context)!;
      return AdminPage(
        title: l10n.adminChecklistItemsTitle,
        subtitle: l10n.adminInvalidCategory,
        body: Center(
          child: AdminEmptyState(
            title: l10n.adminMissingCategory,
            message: l10n.adminSelectCategoryMessage,
            icon: Icons.checklist_outlined,
          ),
        ),
      );
    }

    final itemsAsync = ref.watch(adminChecklistItemsProvider(categoryId));
    final l10n = AppLocalizations.of(context)!;
    final title = categoryTitle?.isNotEmpty == true ? categoryTitle! : l10n.adminChecklistItemsTitle;

    return AdminPage(
      title: title,
      subtitle: l10n.adminItemsSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showItemForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminNewItem),
        ),
      ],
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoItemsTitle,
                message: l10n.adminNoItemsMessage,
                icon: Icons.checklist_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final requiredLabel = item.required ? l10n.yes : l10n.no;
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
                            item.text,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.adminOrderRequiredValue(item.order, requiredLabel),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showItemForm(context, ref, item);
                        } else if (value == 'delete') {
                          await _deleteItem(context, ref, item.id);
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

  Future<void> _showItemForm(BuildContext context, WidgetRef ref, ChecklistItem? item) async {
    final l10n = AppLocalizations.of(context)!;
    final textController = TextEditingController(text: item?.text ?? '');
    final orderController = TextEditingController(text: item?.order.toString() ?? '0');
    bool requiredFlag = item?.required ?? false;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(item == null ? l10n.adminCreateItem : l10n.adminEditItem),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: textController, decoration: InputDecoration(labelText: l10n.adminTextLabel)),
                const SizedBox(height: 8),
                TextField(
                  controller: orderController,
                  decoration: InputDecoration(labelText: l10n.adminOrderLabel),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  value: requiredFlag,
                  title: Text(l10n.required),
                  onChanged: (value) => setState(() => requiredFlag = value),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
            ],
          ),
        ),
      );

      if (result != true) return;

      if (textController.text.trim().isEmpty) {
        if (context.mounted) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.adminTextRequired)),
          );
        }
        return;
      }
      final order = int.tryParse(orderController.text.trim()) ?? 0;
      if (item == null) {
        await ref.read(checklistsRepositoryProvider).createItem(
              categoryId: categoryId,
              text: textController.text.trim(),
              required: requiredFlag,
              order: order,
            );
      } else {
        await ref.read(checklistsRepositoryProvider).updateItem(
              item.id,
              text: textController.text.trim(),
              required: requiredFlag,
              order: order,
              categoryId: categoryId,
            );
      }
      ref.invalidate(adminChecklistItemsProvider(categoryId));
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    } finally {
      textController.dispose();
      orderController.dispose();
    }
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteItemTitle),
        content: Text(l10n.adminDeleteItemConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(checklistsRepositoryProvider).deleteItem(id);
      ref.invalidate(adminChecklistItemsProvider(categoryId));
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    }
  }
}
