import 'dart:async';

import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_button_tokens.dart';
import '../../domain/models/chat_model.dart';
import '../controllers/chat_controller.dart';
import '../controllers/conversations_controller.dart';
import '../../../../core/layout/app_responsive.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final conversationsAsync = ref.watch(conversationsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.conversations)),
      body: conversationsAsync.when(
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.noConversations))
            : ListView.separated(
                padding: AppResponsive.pagePadding(context),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: AppResponsive.spacing(context, 12)),
                itemBuilder: (context, index) {
                  final conversation = items[index];
                  return _ConversationTile(
                    conversation: conversation,
                    onOpen: () {
                      ref.read(appLoggerProvider).info('chat.conversation.open', {
                        'conversationId': conversation.id,
                      });
                      ref.read(chatControllerProvider.notifier).loadConversation(conversation.id);
                      if (context.mounted) context.pop();
                    },
                    onRename: () => _renameConversation(context, ref, conversation),
                    onDelete: () => _deleteConversation(context, ref, conversation),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }

  Future<void> _renameConversation(BuildContext context, WidgetRef ref, Conversation conversation) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: conversation.title);
    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          final padding = AppResponsive.pagePadding(context);
          final viewInsets = MediaQuery.viewInsetsOf(context);

          return Padding(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    0,
                    padding.right,
                    AppResponsive.spacing(context, 12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.renameConversation,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            tooltip: l10n.cancel,
                          ),
                        ],
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 10)),
                      Text(
                        l10n.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) => Navigator.pop(context, value.trim()),
                        decoration: InputDecoration(
                          hintText: conversation.title,
                          filled: true,
                          fillColor: scheme.surfaceVariant.withOpacity(0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: scheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.8)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: scheme.primary, width: 1.4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(top: BorderSide(color: scheme.outlineVariant.withOpacity(0.6))),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    AppResponsive.spacing(context, 12),
                    padding.right,
                    AppResponsive.spacing(context, 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.onSurfaceVariant,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        child: Text(l10n.cancel),
                      ),
                      SizedBox(width: AppResponsive.spacing(context, 12)),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, AppButtonTokens.minHeight),
                          padding: AppButtonTokens.padding,
                          shape: AppButtonTokens.shape,
                          textStyle: AppButtonTokens.textStyle,
                        ),
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (result == null || result.isEmpty) return;
      final errorMessage = await ref
          .read(conversationsControllerProvider.notifier)
          .renameConversation(conversation, result);
      if (errorMessage != null && context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(errorMessage)));
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteConversation(BuildContext context, WidgetRef ref, Conversation conversation) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(conversationsControllerProvider.notifier);
    final pending = controller.removeConversation(conversation);
    if (pending == null) return;
    if (!context.mounted) return;

    var undoPressed = false;
    final snackbar = AppNotifications.showSnackBar(
      context,
      SnackBar(
        content: Text(l10n.conversationDeleted),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            undoPressed = true;
            controller.restoreConversation(pending);
          },
        ),
      ),
      duration: const Duration(seconds: 1),
    );
    await (snackbar?.closed ?? Future.value());

    if (undoPressed) return;

    final outcome = await controller.finalizeDelete(pending);
    if (outcome != null) {
      if (outcome.restore) {
        controller.restoreConversation(pending);
      }
      if (outcome.message != null && context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(outcome.message!)));
      }
      return;
    }
  }
}

class _ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  static const Duration _renameHoldDuration = Duration(seconds: 1);
  Timer? _renameTimer;
  bool _renameTriggered = false;

  void _startRenameTimer() {
    _renameTimer?.cancel();
    _renameTriggered = false;
    _renameTimer = Timer(_renameHoldDuration, () {
      if (!mounted) return;
      _renameTriggered = true;
      widget.onRename();
    });
  }

  void _cancelRenameTimer() {
    _renameTimer?.cancel();
  }

  @override
  void dispose() {
    _renameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        padding: EdgeInsets.symmetric(horizontal: AppResponsive.spacing(context, 20)),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: scheme.onError),
      ),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _startRenameTimer(),
        onPointerUp: (_) => _cancelRenameTimer(),
        onPointerCancel: (_) => _cancelRenameTimer(),
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (_renameTriggered) {
                _renameTriggered = false;
                return;
              }
              widget.onOpen();
            },
            child: Padding(
              padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
              child: Row(
                children: [
                  Container(
                    width: AppResponsive.spacing(context, 44),
                    height: AppResponsive.spacing(context, 44),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.chat_bubble_outline, color: scheme.primary),
                  ),
                  SizedBox(width: AppResponsive.spacing(context, 14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
