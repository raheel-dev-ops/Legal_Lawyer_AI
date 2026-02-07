import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/theme/app_button_tokens.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  late final AnimationController _introController;
  late final Animation<double> _introFade;
  late final Animation<Offset> _introSlide;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _introFade = CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic);
    _introSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_introFade);
    _introController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _complete() {
    ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    context.go('/login');
  }

  void _next(AppLocalizations l10n) {
    final pages = _pages(l10n);
    if (_index >= pages.length - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;

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
          child: FadeTransition(
            opacity: _introFade,
            child: SlideTransition(
              position: _introSlide,
              child: Column(
                children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppResponsive.spacing(context, 20),
                  AppResponsive.spacing(context, 12),
                  AppResponsive.spacing(context, 20),
                  0,
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurface.withOpacity(0.75),
                        textStyle: TextStyle(
                          fontSize: AppResponsive.font(context, 14),
                          fontWeight: FontWeight.w600,
                        ),
                        minimumSize: Size(
                          AppResponsive.spacing(context, 64),
                          AppButtonTokens.minHeight,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppResponsive.spacing(context, 10),
                          vertical: AppResponsive.spacing(context, 6),
                        ),
                        shape: AppButtonTokens.shape,
                      ),
                      onPressed: _complete,
                      child: Text(l10n.skip),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    return AnimatedBuilder(
                      animation: _controller,
                      child: _OnboardingPage(data: page),
                      builder: (context, child) {
                        final pageValue = _controller.hasClients
                            ? (_controller.page ?? _controller.initialPage.toDouble())
                            : _controller.initialPage.toDouble();
                        final delta = (pageValue - index).abs().clamp(0.0, 1.0);
                        final opacity = (1 - (delta * 0.25)).clamp(0.0, 1.0);
                        final scale = 1 - (delta * 0.03);
                        return Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppResponsive.spacing(context, 24),
                  AppResponsive.spacing(context, 6),
                  AppResponsive.spacing(context, 24),
                  AppResponsive.spacing(context, 24),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: EdgeInsets.symmetric(horizontal: AppResponsive.spacing(context, 4)),
                          height: AppResponsive.spacing(context, 6),
                          width: i == _index ? AppResponsive.spacing(context, 34) : AppResponsive.spacing(context, 10),
                          decoration: BoxDecoration(
                            color: i == _index ? accent : scheme.onSurfaceVariant.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppResponsive.spacing(context, 18)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: scheme.onPrimary,
                          minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
                          padding: AppButtonTokens.padding,
                          shape: AppButtonTokens.shape,
                          textStyle: AppButtonTokens.textStyle,
                        ),
                        onPressed: () => _next(l10n),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_index == pages.length - 1 ? l10n.getStarted : l10n.next),
                            SizedBox(width: AppResponsive.spacing(context, 8)),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingPage({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final features = data.features;
    final hasFeatures = features != null && features.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthScale = AppResponsive.scale(context);
        final heightScale = _heightScale(constraints.maxHeight);
        final scale = widthScale < heightScale ? widthScale : heightScale;
        double s(double base) => base * scale;
        final baseHeroHeight = hasFeatures ? 220.0 : 250.0;
        final heroHeight = (constraints.maxHeight * (hasFeatures ? 0.32 : 0.36))
            .clamp(s(210), s(baseHeroHeight))
            .toDouble();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(s(20), s(8), s(20), s(12)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: s(6)),
                  _OnboardingHero(
                    data: data,
                    scale: scale,
                    height: heroHeight,
                  ),
                  SizedBox(height: s(16)),
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: s(24),
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: s(8)),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                      fontSize: s(14.2),
                    ),
                  ),
                  if (hasFeatures) ...[
                    SizedBox(height: s(16)),
                    Column(
                      children: features
                          .map(
                            (feature) => Padding(
                              padding: EdgeInsets.only(bottom: s(12)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: s(44),
                                    height: s(44),
                                    decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(s(14)),
                                      border: Border.all(
                                        color: accent.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(feature.icon, color: accent, size: s(20)),
                                  ),
                                  SizedBox(width: s(12)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          feature.title,
                                          style: TextStyle(
                                            color: scheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                            fontSize: s(14.5),
                                          ),
                                        ),
                                        SizedBox(height: s(4)),
                                        Text(
                                          feature.subtitle,
                                          style: TextStyle(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: s(12.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingFeature {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData heroIcon;
  final _OnboardingHeroStyle heroStyle;
  final String? heroTitle;
  final String? heroSubtitle;
  final List<_OnboardingFeature>? features;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.heroIcon,
    required this.heroStyle,
    this.heroTitle,
    this.heroSubtitle,
    this.features,
  });
}

List<_OnboardingPageData> _pages(AppLocalizations l10n) {
  return [
    _OnboardingPageData(
      title: l10n.onboardingTitle2,
      subtitle: l10n.onboardingSubtitle2,
      heroIcon: Icons.hub,
      heroStyle: _OnboardingHeroStyle.network,
      features: [
        _OnboardingFeature(
          icon: Icons.gavel,
          title: l10n.onboardingFeatureLawyersTitle,
          subtitle: l10n.onboardingFeatureLawyersSubtitle,
        ),
        _OnboardingFeature(
          icon: Icons.notifications_active,
          title: l10n.onboardingFeatureRemindersTitle,
          subtitle: l10n.onboardingFeatureRemindersSubtitle,
        ),
        _OnboardingFeature(
          icon: Icons.checklist,
          title: l10n.onboardingFeatureChecklistsTitle,
          subtitle: l10n.onboardingFeatureChecklistsSubtitle,
        ),
      ],
    ),
    _OnboardingPageData(
      title: l10n.onboardingTitle1,
      subtitle: l10n.onboardingSubtitle1,
      heroIcon: Icons.person_rounded,
      heroStyle: _OnboardingHeroStyle.avatar,
    ),
    _OnboardingPageData(
      title: l10n.onboardingTitle3,
      subtitle: l10n.onboardingSubtitle3,
      heroIcon: Icons.balance,
      heroStyle: _OnboardingHeroStyle.rights,
      heroTitle: l10n.onboardingCardRightsTitle,
      heroSubtitle: l10n.onboardingCardRightsSubtitle,
    ),
  ];
}

double _heightScale(double height) {
  if (height < 520) return 0.8;
  if (height < 600) return 0.88;
  if (height < 680) return 0.94;
  if (height < 760) return 0.98;
  return 1.0;
}

enum _OnboardingHeroStyle { avatar, network, rights }

class _OnboardingHero extends StatelessWidget {
  final _OnboardingPageData data;
  final double scale;
  final double height;

  const _OnboardingHero({
    required this.data,
    required this.scale,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    double s(double base) => base * scale;
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;
    final cardRadius = BorderRadius.circular(s(28));
    final shadow = BoxShadow(
      color: scheme.shadow.withOpacity(0.24),
      blurRadius: s(26),
      offset: Offset(0, s(16)),
    );

    Widget card(Widget child) {
      return Container(
        height: height,
        width: double.infinity,
        padding: EdgeInsets.all(s(18)),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.surface, scheme.surfaceVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: cardRadius,
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [shadow],
        ),
        child: child,
      );
    }

    switch (data.heroStyle) {
      case _OnboardingHeroStyle.avatar:
        return card(
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: s(6),
                right: s(12),
                child: _GlowCircle(size: s(120), color: scheme.onSurface.withOpacity(0.06)),
              ),
              Positioned(
                bottom: s(14),
                left: s(12),
                child: _GlowCircle(size: s(92), color: scheme.onSurface.withOpacity(0.05)),
              ),
              Container(
                width: s(130),
                height: s(130),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.onSurface.withOpacity(0.08),
                  border: Border.all(color: scheme.onSurface.withOpacity(0.16)),
                ),
              ),
              Container(
                width: s(92),
                height: s(92),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.onSurface.withOpacity(0.18),
                ),
                child: Icon(data.heroIcon, size: s(46), color: scheme.onSurface.withOpacity(0.7)),
              ),
            ],
          ),
        );
      case _OnboardingHeroStyle.network:
        return card(
          Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: s(18),
                left: s(22),
                child: _GlowCircle(size: s(90), color: accent.withOpacity(0.08)),
              ),
              Positioned(
                bottom: s(20),
                right: s(12),
                child: _GlowCircle(size: s(110), color: scheme.onSurface.withOpacity(0.05)),
              ),
              Container(
                width: s(110),
                height: s(110),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.15),
                  border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
                ),
                child: Icon(data.heroIcon, size: s(46), color: accent),
              ),
            ],
          ),
        );
      case _OnboardingHeroStyle.rights:
        return card(
          Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: cardRadius,
                    gradient: LinearGradient(
                      colors: [
                        scheme.onSurface.withOpacity(0.05),
                        Colors.transparent,
                        scheme.shadow.withOpacity(0.35),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: s(18)),
                  child: Container(
                    width: s(44),
                    height: s(44),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.16),
                      border: Border.all(color: accent.withOpacity(0.4)),
                    ),
                    child: Icon(data.heroIcon, color: accent, size: s(22)),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Icon(
                  data.heroIcon,
                  size: s(130),
                  color: scheme.onSurface.withOpacity(0.08),
                ),
              ),
              Positioned(
                left: s(16),
                right: s(16),
                bottom: s(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.heroTitle ?? '',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: s(18),
                      ),
                    ),
                    SizedBox(height: s(6)),
                    Text(
                      data.heroSubtitle ?? '',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: s(12.5),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
