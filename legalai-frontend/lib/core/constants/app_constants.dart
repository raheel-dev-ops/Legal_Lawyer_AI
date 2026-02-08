import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Legal AI Lawyer';
  // static const String apiBaseUrlDev =
  //     'http://127.0.0.1:5000/api/v1'; // Android Emulator
  // static const String apiBaseUrlProd =
  //     'http://127.0.0.1:5000/api/v1'; // Placeholder
  static const String apiBaseUrlDev =
      'https://gowaned-beckham-unlawful.ngrok-free.dev/api/v1'; // Android Emulator
  static const String apiBaseUrlProd =
      'https://gowaned-beckham-unlawful.ngrok-free.dev/api/v1'; // Placeholder

  static const String apiBaseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String googleWebClientId =
      String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
        defaultValue:
            '117657837032-702q43qu0v2vveaskgamsoj8rbss6tui.apps.googleusercontent.com',
      );
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

  static String get apiBaseUrl {
    final override = apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return override;
    }
    return kReleaseMode ? apiBaseUrlProd : apiBaseUrlDev;
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String safeModeKey = 'safe_mode';
  static const String rememberMeKey = 'remember_me';
  static const String rememberEmailKey = 'remember_email';
  static const String rememberPasswordKey = 'remember_password';
  static const String rememberAccountsKey = 'remember_accounts';
  static const String rememberLastEmailKey = 'remember_last_email';

  // Voice / API Keys
  static const String openaiApiKey = 'openai_api_key';
  static const String openrouterApiKey = 'openrouter_api_key';
  static const String groqApiKey = 'groq_api_key';
  static const String deepseekApiKey = 'deepseek_api_key';
  static const String grokApiKey = 'grok_api_key';
  static const String anthropicApiKey = 'anthropic_api_key';
  static const String voiceProviderKey = 'voice_provider';
  static const String voiceModelKey = 'voice_model';
  static const String chatProviderKey = 'chat_provider';
  static const String chatModelKey = 'chat_model';
  static const String notificationPreferencesKey = 'notification_preferences';
  static const String notificationPreferencesUpdatedAtKey = 'notification_preferences_updated_at';
}
