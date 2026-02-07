import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/preferences/app_preferences.dart';
import 'core/preferences/preferences_providers.dart';
import 'core/layout/app_responsive.dart';
import 'core/widgets/app_blur_background.dart';
import 'core/content/content_sync_provider.dart';
import 'core/utils/app_notifications.dart';
import 'core/notifications/push_notifications_controller.dart';
import 'core/notifications/push_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Hive.initFlutter();
  await AppPreferences.init();
  runApp(const ProviderScope(child: LegalAiApp()));
}

class LegalAiApp extends ConsumerStatefulWidget {
  const LegalAiApp({super.key});

  @override
  ConsumerState<LegalAiApp> createState() => _LegalAiAppState();
}

class _LegalAiAppState extends ConsumerState<LegalAiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(contentSyncControllerProvider).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final languageCode = ref.watch(appLanguageProvider);
    ref.watch(contentSyncProvider);
    ref.watch(pushNotificationsControllerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppNotifications.messengerKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: Locale(languageCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scale = AppResponsive.clampTextScale(context);
        final adjusted = MediaQuery(
          data: media.copyWith(textScaleFactor: scale),
          child: child ?? const SizedBox.shrink(),
        );
        return AppBlurBackground(child: adjusted);
      },
      routerConfig: router,
    );
  }
}
