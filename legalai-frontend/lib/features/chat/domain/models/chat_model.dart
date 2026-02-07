import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class ChatMessage {
  final int? id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? createdAt;
  final List<ChatLawyerSuggestion>? lawyerSuggestions;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.lawyerSuggestions,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class Conversation {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessageSnippet;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageSnippet,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}

@JsonSerializable()
class ChatLawyerSuggestion {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String category;
  final String? profilePicturePath;

  ChatLawyerSuggestion({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.category,
    this.profilePicturePath,
  });

  factory ChatLawyerSuggestion.fromJson(Map<String, dynamic> json) =>
      _$ChatLawyerSuggestionFromJson(json);
  Map<String, dynamic> toJson() => _$ChatLawyerSuggestionToJson(this);
}
