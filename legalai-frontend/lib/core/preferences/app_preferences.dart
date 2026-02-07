import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/notifications/domain/models/notification_preferences.dart';

class AppPreferences {
  static const String boxName = 'app_prefs';

  final Box _box;

  AppPreferences(this._box);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  ThemeMode getThemeMode() {
    final raw = _box.get(AppConstants.themeModeKey) as String?;
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    _box.put(AppConstants.themeModeKey, _themeModeToString(mode));
  }

  String getLanguage() {
    final raw = _box.get(AppConstants.languageKey) as String?;
    if (raw == 'ur') return 'ur';
    return 'en';
  }

  void setLanguage(String language) {
    final value = language == 'ur' ? 'ur' : 'en';
    _box.put(AppConstants.languageKey, value);
  }

  bool getOnboardingComplete() {
    final raw = _box.get(AppConstants.onboardingCompleteKey);
    return raw is bool ? raw : false;
  }

  void setOnboardingComplete(bool value) {
    _box.put(AppConstants.onboardingCompleteKey, value);
  }

  bool getSafeMode() {
    final raw = _box.get(AppConstants.safeModeKey);
    return raw is bool ? raw : false;
  }

  void setSafeMode(bool value) {
    _box.put(AppConstants.safeModeKey, value);
  }

  String getVoiceProvider() {
    final raw = _box.get(AppConstants.voiceProviderKey) as String?;
    switch (raw) {
      case 'openai':
      case 'openrouter':
      case 'groq':
        return raw!;
      case 'auto':
      default:
        return 'openai';
    }
  }

  void setVoiceProvider(String value) {
    final provider = {'auto', 'openai', 'openrouter', 'groq'}.contains(value) ? value : 'openai';
    _box.put(AppConstants.voiceProviderKey, provider);
  }

  String getVoiceModel() {
    final raw = _box.get(AppConstants.voiceModelKey) as String?;
    return raw ?? '';
  }

  void setVoiceModel(String value) {
    _box.put(AppConstants.voiceModelKey, value);
  }

  String getChatProvider() {
    final raw = _box.get(AppConstants.chatProviderKey) as String?;
    switch (raw) {
      case 'openai':
      case 'openrouter':
      case 'groq':
      case 'deepseek':
      case 'grok':
      case 'anthropic':
        return raw!;
      default:
        return 'openai';
    }
  }

  void setChatProvider(String value) {
    final provider = {
      'openai',
      'openrouter',
      'groq',
      'deepseek',
      'grok',
      'anthropic',
    }.contains(value)
        ? value
        : 'openai';
    _box.put(AppConstants.chatProviderKey, provider);
  }

  String getChatModel() {
    final raw = _box.get(AppConstants.chatModelKey) as String?;
    return raw ?? '';
  }

  void setChatModel(String value) {
    _box.put(AppConstants.chatModelKey, value);
  }

  NotificationPreferences? getNotificationPreferences() {
    final raw = _box.get(AppConstants.notificationPreferencesKey);
    if (raw is! Map) {
      return null;
    }
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    return NotificationPreferences.fromApi(Map<String, dynamic>.from(map));
  }

  DateTime? getNotificationPreferencesUpdatedAt() {
    final raw = _box.get(AppConstants.notificationPreferencesUpdatedAtKey);
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return null;
  }

  bool isNotificationPreferencesStale(Duration maxAge) {
    final updatedAt = getNotificationPreferencesUpdatedAt();
    if (updatedAt == null) {
      return true;
    }
    return DateTime.now().difference(updatedAt) > maxAge;
  }

  void setNotificationPreferences(NotificationPreferences prefs) {
    _box.put(AppConstants.notificationPreferencesKey, prefs.toApi());
    _box.put(
      AppConstants.notificationPreferencesUpdatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  void clearNotificationPreferences() {
    _box.delete(AppConstants.notificationPreferencesKey);
    _box.delete(AppConstants.notificationPreferencesUpdatedAtKey);
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}
