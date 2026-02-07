class AdminNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.readAt,
  });

  factory AdminNotification.fromApi(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['id'] as int,
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      isRead: (json['isRead'] as bool?) ?? false,
      createdAt: _parseDate(json['createdAt'] as String?),
      readAt: _parseDate(json['readAt'] as String?),
    );
  }

  String? get route {
    final value = data['route'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  String? get fullName {
    final value = data['fullName'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  String? get subject {
    final value = data['subject'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  String? get kind {
    final value = data['kind'];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
