import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/errors/error_mapper.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  bool _updatingLanguage = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('preferences');
    });
  }

  Future<void> _updateLanguage(String value) async {
    if (_updatingLanguage) return;
    final current = ref.read(appLanguageProvider);
    if (current == value) return;

    final user = ref.read(authControllerProvider).value;
    final safeMode = ref.read(safeModeProvider);
    if (user != null && safeMode) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.safeModeDescription)),
        );
      }
      return;
    }

    setState(() => _updatingLanguage = true);
    try {
      if (user != null) {
        await ref.read(userRepositoryProvider).updateProfile({'language': value});
        ref.invalidate(authControllerProvider);
      }
      ref.read(appLanguageProvider.notifier).setLanguage(value);
    } catch (e) {
      final err = ErrorMapper.from(e);
      if (mounted) {
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(err.userMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingLanguage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);
    final isCompact =
        MediaQuery.sizeOf(context).width < 360 || MediaQuery.textScaleFactorOf(context) > 1.1;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.preferences)),
      body: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          const SafeModeBanner(),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _Section(
            title: l10n.appearance,
            child: isCompact
                ? DropdownButtonFormField<ThemeMode>(
                    value: themeMode,
                    decoration: InputDecoration(labelText: l10n.appearance),
                    items: [
                      DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
                      DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(themeModeProvider.notifier).setThemeMode(value);
                      }
                    },
                  )
                : SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(value: ThemeMode.system, label: Text(l10n.system)),
                      ButtonSegment(value: ThemeMode.light, label: Text(l10n.light)),
                      ButtonSegment(value: ThemeMode.dark, label: Text(l10n.dark)),
                    ],
                    selected: {themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) {
                      ref.read(themeModeProvider.notifier).setThemeMode(value.first);
                    },
                  ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _Section(
            title: l10n.language,
            child: isCompact
                ? DropdownButtonFormField<String>(
                    value: language,
                    decoration: InputDecoration(labelText: l10n.language),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                      DropdownMenuItem(value: 'ur', child: Text(l10n.languageUrdu)),
                    ],
                    onChanged: _updatingLanguage
                        ? null
                        : (value) {
                            if (value != null) {
                              _updateLanguage(value);
                            }
                          },
                  )
                : SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                      ButtonSegment(value: 'ur', label: Text(l10n.languageUrdu)),
                    ],
                    selected: {language},
                    showSelectedIcon: false,
                    onSelectionChanged: _updatingLanguage
                        ? null
                        : (value) {
                            _updateLanguage(value.first);
                          },
                  ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 20)),
          Text(
            l10n.preferencesNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppResponsive.spacing(context, 12)),
          child,
        ],
      ),
    );
  }
}
