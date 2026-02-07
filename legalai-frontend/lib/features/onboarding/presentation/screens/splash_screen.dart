import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/layout/app_responsive.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final int _splashDurationMs;
  late final AnimationController _progressController;
  late final Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _splashDurationMs = _splashDelayMs();
    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _splashDurationMs),
      animationBehavior: AnimationBehavior.preserve,
    );
    _progressValue = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    await _progressController.forward();
    if (!mounted) return;
    final onboardingComplete = ref.read(onboardingControllerProvider);
    if (!onboardingComplete) {
      context.go('/onboarding');
      return;
    }
    final authState = ref.read(authControllerProvider);
    final user = authState.asData?.value;
    if (user == null) {
      context.go('/login');
      return;
    }
    if (user.isAdmin == true) {
      context.go('/admin/overview');
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(appLanguageProvider);
    final title = l10n.splashTitle;
    final subtitle = l10n.splashSubtitle;
    final initializing = l10n.initializing;
    final secure = l10n.securePrivate;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.background, scheme.surfaceVariant],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: AppResponsive.spacing(context, 140),
                      height: AppResponsive.spacing(context, 140),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withOpacity(0.12),
                      ),
                    ),
                    Container(
                      width: AppResponsive.spacing(context, 92),
                      height: AppResponsive.spacing(context, 92),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface,
                        border: Border.all(color: scheme.primary.withOpacity(0.6), width: 1.5),
                      ),
                      child: Icon(
                        Icons.balance_outlined,
                        size: AppResponsive.font(context, 44),
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 28)),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 34)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppResponsive.spacing(context, 64)),
                child: AnimatedBuilder(
                  animation: _progressValue,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressValue.value,
                      minHeight: AppResponsive.spacing(context, 6),
                      backgroundColor: scheme.onSurface.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                      borderRadius: BorderRadius.circular(999),
                    );
                  },
                ),
              ),
              SizedBox(height: AppResponsive.spacing(context, 12)),
              AnimatedBuilder(
                animation: _progressValue,
                builder: (context, child) {
                  final percent = (_progressValue.value * 100).round();
                  return Text(
                    '$initializing $percent%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                        ),
                  );
                },
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 18, color: scheme.onSurfaceVariant),
                  SizedBox(width: AppResponsive.spacing(context, 8)),
                  Text(
                    secure,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                  ),
                ],
              ),
              SizedBox(height: AppResponsive.spacing(context, 8)),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.0.0';
                  return Text(
                    'v$version',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                  );
                },
              ),
              SizedBox(height: AppResponsive.spacing(context, 18)),
            ],
          ),
        ),
      ),
    );
  }

  int _splashDelayMs() {
    if (kIsWeb) {
      return 1500;
    }
    return defaultTargetPlatform == TargetPlatform.android ? 1000 : 1500;
  }
}
