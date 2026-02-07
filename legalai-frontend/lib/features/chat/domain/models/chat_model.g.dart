// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: (json['id'] as num?)?.toInt(),
  role: json['role'] as String,
  content: json['content'] as String,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  lawyerSuggestions: (json['lawyerSuggestions'] as List<dynamic>?)
      ?.map((e) => ChatLawyerSuggestion.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'createdAt': instance.createdAt?.toIso8601String(),
      'lawyerSuggestions': instance.lawyerSuggestions,
    };

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  lastMessageSnippet: json['lastMessageSnippet'] as String?,
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'lastMessageSnippet': instance.lastMessageSnippet,
    };

ChatLawyerSuggestion _$ChatLawyerSuggestionFromJson(
  Map<String, dynamic> json,
) => ChatLawyerSuggestion(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  category: json['category'] as String,
  profilePicturePath: json['profilePicturePath'] as String?,
);

Map<String, dynamic> _$ChatLawyerSuggestionToJson(
  ChatLawyerSuggestion instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'category': instance.category,
  'profilePicturePath': instance.profilePicturePath,
};
