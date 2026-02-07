import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:legalai_frontend/core/preferences/app_preferences.dart';
import 'package:legalai_frontend/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    PackageInfo.setMockInitialValues(
      appName: 'LegalAI',
      packageName: 'legalai_frontend',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test',
    );
    final dir = await Directory.systemTemp.createTemp('legalai_splash_test');
    Hive.init(dir.path);
    await Hive.openBox(AppPreferences.boxName);
    final prefs = AppPreferences(Hive.box(AppPreferences.boxName));
    prefs.setOnboardingComplete(false);
    prefs.setLanguage('en');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets(
    'navigates to onboarding after 1 second',
    (tester) async {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Onboarding')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 999));
    expect(find.text('Onboarding'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Onboarding'), findsOneWidget);
    },
    skip: true,
  );
}
