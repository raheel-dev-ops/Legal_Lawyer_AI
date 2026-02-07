class NotificationPreferences {
  final bool contentUpdates;
  final bool lawyerUpdates;
  final bool reminderNotifications;

  const NotificationPreferences({
    required this.contentUpdates,
    required this.lawyerUpdates,
    required this.reminderNotifications,
  });

  factory NotificationPreferences.fromApi(Map<String, dynamic> json) {
    return NotificationPreferences(
      contentUpdates: (json['contentUpdates'] as bool?) ?? true,
      lawyerUpdates: (json['lawyerUpdates'] as bool?) ?? true,
      reminderNotifications: (json['reminderNotifications'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toApi() {
    return {
      'contentUpdates': contentUpdates,
      'lawyerUpdates': lawyerUpdates,
      'reminderNotifications': reminderNotifications,
    };
  }

  NotificationPreferences copyWith({
    bool? contentUpdates,
    bool? lawyerUpdates,
    bool? reminderNotifications,
  }) {
    return NotificationPreferences(
      contentUpdates: contentUpdates ?? this.contentUpdates,
      lawyerUpdates: lawyerUpdates ?? this.lawyerUpdates,
      reminderNotifications: reminderNotifications ?? this.reminderNotifications,
    );
  }
}
