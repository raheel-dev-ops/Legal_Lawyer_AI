import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:typed_data';
import '../../domain/models/chat_model.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

part 'chat_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
}

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, dynamic>> askQuestion(String question, {int? conversationId, String language = 'en'}) async {
    final response = await remoteDataSource.ask(
      question,
      conversationId: conversationId,
      language: language,
    );
    final newId = response['conversationId'];
    if (newId is int) {
      await remoteDataSource.invalidateMessagesCache(newId);
    }
    await remoteDataSource.invalidateConversationsCache();
    return response;
  }

  @override
  Future<List<Conversation>> getConversations({int page = 1, int limit = 20}) {
    return remoteDataSource.getConversations(page, limit);
  }

  @override
  Future<List<Conversation>?> getConversationsCached({int page = 1, int limit = 20}) {
    return remoteDataSource.getConversationsCached(page, limit);
  }

  @override
  Future<List<ChatMessage>> getMessages(int conversationId, {int page = 1, int limit = 30}) {
    return remoteDataSource.getMessages(conversationId, page, limit);
  }

  @override
  Future<void> deleteConversation(int conversationId) async {
    await remoteDataSource.deleteConversation(conversationId);
    await remoteDataSource.invalidateMessagesCache(conversationId);
    await remoteDataSource.invalidateConversationsCache();
  }

  @override
  Future<void> renameConversation(int conversationId, String title) async {
    await remoteDataSource.renameConversation(conversationId, title);
    await remoteDataSource.invalidateConversationsCache();
  }

  @override
  Future<void> invalidateConversationsCache() {
    return remoteDataSource.invalidateConversationsCache();
  }

  @override
  Future<void> invalidateMessagesCache(int conversationId) {
    return remoteDataSource.invalidateMessagesCache(conversationId);
  }

  @override
  Future<String> transcribeAudio(Uint8List bytes, String filename, {String? language}) {
    return remoteDataSource.transcribeAudio(bytes, filename, language: language);
  }
}
