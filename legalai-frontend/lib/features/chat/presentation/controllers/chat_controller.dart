import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../domain/models/chat_model.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/preferences/preferences_providers.dart';
import 'chat_conversations_refresh_provider.dart';

part 'chat_controller.g.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final int? conversationId;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.conversationId,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    int? conversationId,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      conversationId: conversationId ?? this.conversationId,
      error: error,
    );
  }
}

@riverpod
class ChatController extends _$ChatController {
  @override
  ChatState build() {
    return ChatState();
  }

  Future<void> askQuestion(String question) async {
    await _sendQuestion(question, alreadyLoading: false);
  }

  Future<void> transcribeAndAsk(Uint8List bytes, String filename) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final language = ref.read(appLanguageProvider);
      final transcript = await repo.transcribeAudio(bytes, filename, language: language);
      if (transcript.trim().isEmpty) {
        state = state.copyWith(isLoading: false, error: _voiceNoSpeechMessage(language));
        return;
      }
      await _sendQuestion(transcript, alreadyLoading: true);
    } catch (e) {
      final err = ErrorMapper.from(e);
      state = state.copyWith(isLoading: false, error: err.userMessage);
    }
  }

  String _voiceNoSpeechMessage(String language) {
    final lang = language == 'ur' ? 'ur' : 'en';
    return lookupAppLocalizations(Locale(lang)).voiceNoSpeechDetected;
  }

  Future<void> _sendQuestion(String question, {required bool alreadyLoading}) async {
    // Add user message immediately
    final userMsg = ChatMessage(role: 'user', content: question, createdAt: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: alreadyLoading ? state.isLoading : true,
      error: null,
    );

    try {
      final repo = ref.read(chatRepositoryProvider);
      final language = ref.read(appLanguageProvider);
      final response = await repo.askQuestion(
        question, 
        conversationId: state.conversationId,
        language: language,
      );
      
      final newConvId = response['conversationId'] as int?;
      final status = response['status'];
      final answerRaw = response['answer'];
      final answer = answerRaw is String ? answerRaw : '';

      if (status == 'processing' || answer.trim().isEmpty) {
        state = state.copyWith(
          isLoading: true,
          conversationId: newConvId ?? state.conversationId,
        );
        await _recoverAfterTimeout(question);
        return;
      }
      final rawLawyers = response['lawyers'];
      final suggestions = rawLawyers is List
          ? rawLawyers
              .whereType<Map<String, dynamic>>()
              .map(ChatLawyerSuggestion.fromJson)
              .toList()
          : null;

      final assistantMsg = ChatMessage(
        role: 'assistant', 
        content: answer, 
        createdAt: DateTime.now(),
        lawyerSuggestions: (suggestions == null || suggestions.isEmpty) ? null : suggestions,
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMsg],
        isLoading: false,
        conversationId: newConvId ?? state.conversationId,
      );
      ref.read(chatConversationsRefreshProvider.notifier).state++;
    } catch (e) {
      if (e is DioException && _shouldAttemptRecovery(e)) {
        await _recoverAfterTimeout(question);
        return;
      }
      final err = ErrorMapper.from(e);
      state = state.copyWith(isLoading: false, error: err.userMessage);
    }
  }

  bool _shouldAttemptRecovery(DioException error) {
    final status = error.response?.statusCode;
    if (status == null) {
      return true;
    }
    if (error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return true;
    }
    return false;
  }

  Future<void> _recoverAfterTimeout(String question) async {
    try {
      if (!state.isLoading) {
        state = state.copyWith(isLoading: true, error: null);
      }
      final repo = ref.read(chatRepositoryProvider);
      final normalizedQuestion = question.trim();
      for (var attempt = 0; attempt < 16; attempt++) {
        await Future.delayed(const Duration(seconds: 8));
        final conversations = await repo.getConversations(page: 1, limit: 1);
        if (conversations.isEmpty) {
          continue;
        }
        final latest = conversations.first;
        final messages = await repo.getMessages(latest.id);
        final hasQuestion = messages.any(
          (m) => m.role == 'user' && m.content.trim() == normalizedQuestion,
        );
        final hasAnswer = messages.any(
          (m) => m.role == 'assistant' && m.content.trim().isNotEmpty,
        );
        if (hasQuestion && hasAnswer) {
          state = state.copyWith(
            messages: messages,
            isLoading: false,
            conversationId: latest.id,
            error: null,
          );
          ref.read(chatConversationsRefreshProvider.notifier).state++;
          return;
        }
      }
      state = state.copyWith(isLoading: false, error: 'Request timed out. Please try again.');
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Request timed out. Please refresh.');
    }
  }

  void loadConversation(int id) async {
      state = state.copyWith(isLoading: true, conversationId: id, messages: []);
       try {
      final repo = ref.read(chatRepositoryProvider);
      final messages = await repo.getMessages(id);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      final err = ErrorMapper.from(e);
      state = state.copyWith(isLoading: false, error: err.userMessage);
    }
  }
}
