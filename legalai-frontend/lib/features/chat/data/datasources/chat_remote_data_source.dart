import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/cache/http_cache.dart';
import '../../domain/models/chat_model.dart';

part 'chat_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
ChatRemoteDataSource chatRemoteDataSource(Ref ref) {
  return ChatRemoteDataSource(
    ref.watch(dioProvider),
  );
}

class ChatRemoteDataSource {
  final Dio _dio;

  ChatRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> ask(String question, {int? conversationId, String language = 'en'}) async {
    final response = await _dio.post(
      '/chat/ask',
      data: {
        'question': question,
        'language': language,
        if (conversationId != null) 'conversationId': conversationId,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 180),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    return response.data;
  }

  Future<List<Conversation>> getConversations(int page, int limit) async {
    final key = _conversationsKey(page, limit);
    return HttpCache.getOrFetchJson(
      key: key,
      fetcher: (etag) {
        return _dio.get(
          '/chat/conversations',
          queryParameters: {
            'page': page,
            'limit': limit,
          },
          options: Options(
            headers: {
              if (etag != null) 'If-None-Match': etag,
            },
            validateStatus: (status) => status != null && (status == 304 || (status >= 200 && status < 300)),
          ),
        );
      },
      decode: _decodeConversations,
    );
  }

  Future<List<Conversation>?> getConversationsCached(int page, int limit) async {
    final key = _conversationsKey(page, limit);
    final cached = await HttpCache.getEntry(key);
    if (cached == null) return null;
    return _decodeConversations(cached.data);
  }

  Future<List<ChatMessage>> getMessages(int conversationId, int page, int limit) async {
    final key = _messagesKey(conversationId, page, limit);
    return HttpCache.getOrFetchJson(
      key: key,
      fetcher: (etag) {
        return _dio.get(
          '/chat/conversations/$conversationId/messages',
          queryParameters: {
            'page': page,
            'limit': limit,
          },
          options: Options(
            headers: {
              if (etag != null) 'If-None-Match': etag,
            },
            validateStatus: (status) => status != null && (status == 304 || (status >= 200 && status < 300)),
          ),
        );
      },
      decode: (data) {
        final items = (data['items'] as List?) ?? [];
        return items
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }
  
  Future<void> deleteConversation(int id) async {
      await _dio.delete('/chat/conversations/$id');
  }

  Future<void> renameConversation(int id, String title) async {
    await _dio.put('/chat/conversations/$id', data: {'title': title});
  }

  Future<String> transcribeAudio(Uint8List bytes, String filename, {String? language}) async {
    final data = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      if (language != null) 'language': language,
    });

    final response = await _dio.post(
      '/chat/transcribe',
      data: data,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final text = payload['text'];
      if (text is String) return text;
    }
    return '';
  }

  Future<void> invalidateConversationsCache() async {
    await HttpCache.invalidatePrefix('chat.conversations:');
  }

  Future<void> invalidateMessagesCache(int conversationId) async {
    await HttpCache.invalidatePrefix('chat.messages:$conversationId:');
  }
}

String _conversationsKey(int page, int limit) => 'chat.conversations:$page:$limit';
String _messagesKey(int conversationId, int page, int limit) =>
    'chat.messages:$conversationId:$page:$limit';

List<Conversation> _decodeConversations(dynamic data) {
  final items = (data is Map ? data['items'] as List? : null) ?? [];
  return items
      .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}
