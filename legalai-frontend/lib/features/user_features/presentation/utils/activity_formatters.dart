import 'package:flutter/material.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';

class ActivityDetails {
  final String title;
  final String badge;
  final IconData icon;
  final Color color;

  ActivityDetails({
    required this.title,
    required this.badge,
    required this.icon,
    required this.color,
  });
}

ActivityDetails activityDetails(AppLocalizations l10n, String type, Map<String, dynamic> payload) {
  final upper = type.toUpperCase();
  final screenName = payload['screen']?.toString().trim();
  final query = payload['query']?.toString().trim();
  final itemType = payload['itemType']?.toString().trim();
  final itemId = payload['itemId']?.toString().trim();

  String title = _titleFromPayload(l10n, type, payload);
  if (upper == 'SCREEN_VIEW' && screenName != null && screenName.isNotEmpty) {
    title = _humanize(screenName, l10n);
  } else if (title.trim().isEmpty && query != null && query.isNotEmpty) {
    title = '${_humanize(type, l10n)}: $query';
  } else if (title.trim().isNotEmpty && itemType != null && itemType.isNotEmpty && itemId != null && itemId.isNotEmpty) {
    title = '$title • ${_humanize(itemType, l10n)} #$itemId';
  }

  if (upper.contains('REMINDER')) {
    return ActivityDetails(
      title: title,
      badge: l10n.reminders.toUpperCase(),
      icon: Icons.calendar_today_outlined,
      color: AppPalette.warning,
    );
  }
  if (upper.contains('DRAFT')) {
    return ActivityDetails(
      title: title,
      badge: l10n.drafts.toUpperCase(),
      icon: Icons.description_outlined,
      color: AppPalette.tertiary,
    );
  }
  if (upper.contains('CHAT') || upper.contains('CONVERSATION')) {
    return ActivityDetails(
      title: title,
      badge: l10n.chat.toUpperCase(),
      icon: Icons.chat_bubble_outline,
      color: AppPalette.primary,
    );
  }
  if (upper.contains('BOOKMARK')) {
    return ActivityDetails(
      title: title,
      badge: l10n.bookmarks.toUpperCase(),
      icon: Icons.bookmark_border,
      color: AppPalette.secondary,
    );
  }

  return ActivityDetails(
    title: title,
    badge: l10n.activityLog.toUpperCase(),
    icon: Icons.history,
    color: AppPalette.info,
  );
}

String formatActivityTime(AppLocalizations l10n, DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _titleFromPayload(AppLocalizations l10n, String type, Map<String, dynamic> payload) {
  final title = payload['title']?.toString().trim();
  if (title != null && title.isNotEmpty) return title;
  final name = payload['name']?.toString().trim();
  if (name != null && name.isNotEmpty) return name;
  return _humanize(type, l10n);
}

String _humanize(String value, AppLocalizations l10n) {
  if (value.trim().isEmpty) return l10n.activityLog;
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
