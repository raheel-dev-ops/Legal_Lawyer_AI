import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_conversations_refresh_provider.dart';

final conversationsControllerProvider =
    NotifierProvider.autoDispose<ConversationsController, AsyncValue<List<Conversation>>>(
  ConversationsController.new,
);

class PendingConversationDelete {
  final Conversation conversation;
  final int index;

  PendingConversationDelete({
    required this.conversation,
    required this.index,
  });
}

class DeleteOutcome {
  final String? message;
  final bool restore;

  const DeleteOutcome({this.message, required this.restore});
}

class ConversationsController extends Notifier<AsyncValue<List<Conversation>>> {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  AppLogger get _logger => ref.read(appLoggerProvider);

  @override
  AsyncValue<List<Conversation>> build() {
    ref.listen<int>(chatConversationsRefreshProvider, (_, __) {
      refresh();
    });
    Future.microtask(() => refresh(initialLoad: true));
    return const AsyncValue.loading();
  }

  Future<String?> refresh({bool initialLoad = false, bool preferCache = true, int? expectMissingId}) async {
    final previous = state.asData?.value;
    _logger.info(
      initialLoad ? 'chat.conversations.load.start' : 'chat.conversations.refresh.start',
    );
    List<Conversation>? cached;
    if (preferCache) {
      cached = await _repository.getConversationsCached();
      if (cached != null) {
        final filteredCached = _filterConversations(cached);
        _logger.info('chat.conversations.cache.hit', {'count': filteredCached.length});
        state = AsyncValue.data(filteredCached);
      } else {
        _logger.info('chat.conversations.cache.miss');
      }
    }
    if (initialLoad && cached == null) {
      state = const AsyncValue.loading();
    }
    try {
      final items = await _repository.getConversations();
      final filteredOriginal = _filterConversations(items);
      var filtered = filteredOriginal;
      if (expectMissingId != null && filteredOriginal.any((item) => item.id == expectMissingId)) {
        _logger.error('chat.conversation.delete.mismatch', {
          'conversationId': expectMissingId,
        });
        filtered = filteredOriginal.where((item) => item.id != expectMissingId).toList();
        state = AsyncValue.data(filtered);
        return 'Conversation deletion not synced yet. Please refresh.';
      }
      final current = state.asData?.value ?? previous ?? const <Conversation>[];
      if (!_areSame(current, filtered)) {
        state = AsyncValue.data(filtered);
      }
      _logger.info(
        initialLoad ? 'chat.conversations.load.success' : 'chat.conversations.refresh.success',
        {
          'count': filtered.length,
        },
      );
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      _logger.error(
        initialLoad ? 'chat.conversations.load.failed' : 'chat.conversations.refresh.failed',
        {
          'status': err.statusCode,
        },
      );
      final hasData = state.asData?.value != null;
      if (hasData) {
        return err.userMessage;
      }
      if (initialLoad || previous == null) {
        state = AsyncValue.error(err, st);
      } else {
        state = AsyncValue.data(previous);
      }
      return err.userMessage;
    }
    return null;
  }

  bool _hasMessages(Conversation conversation) {
    final snippet = conversation.lastMessageSnippet?.trim() ?? '';
    return snippet.isNotEmpty;
  }

  List<Conversation> _filterConversations(List<Conversation> items) {
    return items.where(_hasMessages).toList();
  }

  bool _areSame(List<Conversation> left, List<Conversation> right) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      final a = left[i];
      final b = right[i];
      if (a.id != b.id) return false;
      if (a.title != b.title) return false;
      if (a.updatedAt != b.updatedAt) return false;
      if (a.lastMessageSnippet != b.lastMessageSnippet) return false;
    }
    return true;
  }

  PendingConversationDelete? removeConversation(Conversation conversation) {
    final current = state.asData?.value;
    if (current == null) {
      _logger.warn('chat.conversation.delete.skipped', {
        'conversationId': conversation.id,
        'reason': 'state_not_ready',
      });
      return null;
    }
    final index = current.indexWhere((item) => item.id == conversation.id);
    if (index == -1) {
      _logger.warn('chat.conversation.delete.skipped', {
        'conversationId': conversation.id,
        'reason': 'not_found',
      });
      return null;
    }
    final updated = [...current]..removeAt(index);
    state = AsyncValue.data(updated);
    _logger.info('chat.conversation.delete.optimistic', {
      'conversationId': conversation.id,
    });
    return PendingConversationDelete(conversation: conversation, index: index);
  }

  void restoreConversation(PendingConversationDelete pending) {
    final current = state.asData?.value ?? [];
    if (current.any((item) => item.id == pending.conversation.id)) {
      _logger.warn('chat.conversation.delete.restore.skipped', {
        'conversationId': pending.conversation.id,
        'reason': 'already_present',
      });
      return;
    }
    final safeIndex = pending.index < 0
        ? 0
        : pending.index > current.length
            ? current.length
            : pending.index;
    final updated = [...current]..insert(safeIndex, pending.conversation);
    state = AsyncValue.data(updated);
    _logger.info('chat.conversation.delete.restored', {
      'conversationId': pending.conversation.id,
    });
  }

  Future<DeleteOutcome?> finalizeDelete(PendingConversationDelete pending) async {
    _logger.info('chat.conversation.delete.start', {
      'conversationId': pending.conversation.id,
    });
    try {
      await _repository.deleteConversation(pending.conversation.id);
      await _repository.invalidateMessagesCache(pending.conversation.id);
      await _repository.invalidateConversationsCache();
      ref.read(chatConversationsRefreshProvider.notifier).state++;
      _logger.info('chat.conversation.delete.success', {
        'conversationId': pending.conversation.id,
      });
      final refreshError = await refresh(expectMissingId: pending.conversation.id);
      if (refreshError != null) {
        return DeleteOutcome(message: refreshError, restore: false);
      }
      return null;
    } catch (e) {
      final err = ErrorMapper.from(e);
      _logger.error('chat.conversation.delete.failed', {
        'conversationId': pending.conversation.id,
        'status': err.statusCode,
      });
      return DeleteOutcome(message: err.userMessage, restore: true);
    }
  }

  Future<String?> renameConversation(Conversation conversation, String title) async {
    _logger.info('chat.conversation.rename.start', {
      'conversationId': conversation.id,
    });
    try {
      await _repository.renameConversation(conversation.id, title);
      _updateTitle(conversation.id, title);
      ref.read(chatConversationsRefreshProvider.notifier).state++;
      _logger.info('chat.conversation.rename.success', {
        'conversationId': conversation.id,
      });
      return null;
    } catch (e) {
      final err = ErrorMapper.from(e);
      _logger.error('chat.conversation.rename.failed', {
        'conversationId': conversation.id,
        'status': err.statusCode,
      });
      return err.userMessage;
    }
  }

  void _updateTitle(int conversationId, String title) {
    final current = state.asData?.value;
    if (current == null) return;
    final index = current.indexWhere((item) => item.id == conversationId);
    if (index == -1) return;
    final existing = current[index];
    final updated = [...current];
    updated[index] = Conversation(
      id: existing.id,
      title: title,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      lastMessageSnippet: existing.lastMessageSnippet,
    );
    state = AsyncValue.data(updated);
  }
}
