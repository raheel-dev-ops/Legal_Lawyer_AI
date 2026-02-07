import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../../core/content/content_sync_provider.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../user_features/presentation/controllers/activity_logger.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/theme/app_button_tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  bool _refreshingContent = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(userActivityLoggerProvider).logScreenView('profile');
    });
  }

  Future<void> _showPhotoSourceDialog() async {
    if (_uploading) return;
    final l10n = AppLocalizations.of(context)!;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAndUpload(source);
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final platformFile = PlatformFile(
        name: file.name,
        size: bytes.length,
        bytes: bytes,
      );
      setState(() => _uploading = true);
      final path = await ref.read(userRepositoryProvider).uploadAvatar(platformFile);
      ref.invalidate(authControllerProvider);
      await ref.read(userActivityLoggerProvider).logEvent(
        'PROFILE_IMAGE_UPDATED',
        payload: {
          'source': source.name,
          'path': path.isNotEmpty,
        },
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.profilePhotoUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.profilePhotoUpdateFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _toggleSafeMode(bool enabled) async {
    ref.read(safeModeProvider.notifier).setSafeMode(enabled);
    await ref.read(userActivityLoggerProvider).logEvent(
      'SAFE_MODE_TOGGLED',
      payload: {'enabled': enabled},
    );
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      final message = enabled ? l10n.safeModeEnabled : l10n.safeModeDisabled;
      AppNotifications.showSnackBar(context,
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _emergencyExit() async {
    await ref.read(userActivityLoggerProvider).logEvent('EMERGENCY_EXIT');
    await ref.read(authControllerProvider.notifier).logout();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemNavigator.pop();
    }
  }

  Future<void> _refreshContent() async {
    if (_refreshingContent) return;
    setState(() => _refreshingContent = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final online = await isOnline();
      if (!online) {
        if (mounted) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.refreshContentOffline)),
          );
        }
        return;
      }
      final ok = await ref.read(contentSyncControllerProvider).refresh();
      if (mounted) {
        final message = ok ? l10n.refreshContentSuccess : l10n.refreshContentFailed;
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshingContent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).value;
    final scheme = Theme.of(context).colorScheme;
    final initials = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim()[0] : l10n.userInitialFallback;
    final avatarSize = AppResponsive.spacing(context, 124);
    final avatarProvider = resolveMediaImageProvider(
      context,
      user?.avatarPath,
      width: avatarSize,
      height: avatarSize,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          const SafeModeBanner(),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _ProfileAccountCard(
            name: user?.name ?? l10n.guestUser,
            email: user?.email ?? '',
            roleLabel: l10n.profile,
            initials: initials,
            avatarProvider: avatarProvider,
            onAvatarTap: _uploading ? null : _showPhotoSourceDialog,
            onEditProfile: () => context.push('/profile/edit'),
            onChangePassword: () => context.push('/profile/change-password'),
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _SettingsSection(
            title: l10n.tools,
            children: [
              _SettingsTile(
                icon: Icons.language,
                title: l10n.appearanceLanguage,
                onTap: () => context.push('/profile/preferences'),
              ),
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                title: l10n.notifications,
                onTap: () => context.push('/notifications/preferences'),
              ),
              _SettingsTile(
                icon: Icons.alarm_outlined,
                title: l10n.reminders,
                onTap: () => context.push('/reminders'),
              ),
              _SettingsTile(
                icon: Icons.tune,
                title: l10n.voiceInputSettingsTitle,
                onTap: () => context.push('/profile/voice-input'),
              ),
              _SettingsTile(
                icon: Icons.bookmark_border,
                title: l10n.bookmarks,
                onTap: () => context.push('/bookmarks'),
              ),
              _SettingsTile(
                icon: Icons.history,
                title: l10n.activityLog,
                onTap: () => context.push('/activity'),
              ),
              _SettingsTile(
                icon: Icons.sync,
                title: l10n.refreshContent,
                subtitle: l10n.refreshContentSubtitle,
                onTap: _refreshingContent ? null : _refreshContent,
                trailing: _refreshingContent
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _SettingsSection(
            title: l10n.safety,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: ref.watch(safeModeProvider),
                onChanged: _toggleSafeMode,
                title: Text(l10n.safeMode),
                subtitle: Text(
                  l10n.safeModeDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _SettingsSection(
            title: l10n.emergencyExit,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
                  padding: AppButtonTokens.padding,
                  shape: AppButtonTokens.shape,
                  textStyle: AppButtonTokens.textStyle,
                ),
                onPressed: _emergencyExit,
                icon: const Icon(Icons.warning_amber_rounded),
                label: Text(l10n.emergencyExit),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          _SettingsSection(
            title: l10n.support,
            children: [
              _SettingsTile(
                icon: Icons.help_outline,
                title: l10n.helpSupport,
                onTap: () => context.push('/support'),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 24)),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
              padding: AppButtonTokens.padding,
              shape: AppButtonTokens.shape,
              textStyle: AppButtonTokens.textStyle,
            ),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
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
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppResponsive.spacing(context, 10)),
        child: Row(
          children: [
            Container(
              width: AppResponsive.spacing(context, 36),
              height: AppResponsive.spacing(context, 36),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.primary, size: 18),
            ),
            SizedBox(width: AppResponsive.spacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? Icon(Icons.arrow_forward_ios, size: 14, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ProfileAccountCard extends StatelessWidget {
  final String name;
  final String email;
  final String roleLabel;
  final String initials;
  final ImageProvider? avatarProvider;
  final VoidCallback? onAvatarTap;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;

  const _ProfileAccountCard({
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.initials,
    required this.avatarProvider,
    required this.onAvatarTap,
    required this.onEditProfile,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              InkWell(
                onTap: onAvatarTap,
                borderRadius: BorderRadius.circular(AppResponsive.spacing(context, 64)),
                child: CircleAvatar(
                  radius: AppResponsive.spacing(context, 60),
                  backgroundColor: scheme.primary.withOpacity(0.12),
                  foregroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? Text(
                          initials,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: InkWell(
                  onTap: onAvatarTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: AppResponsive.spacing(context, 36),
                    height: AppResponsive.spacing(context, 36),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: scheme.outlineVariant.withOpacity(0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.edit, size: 18, color: scheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppResponsive.spacing(context, 12)),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppResponsive.spacing(context, 6)),
          Text(
            email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(height: AppResponsive.spacing(context, 16)),
          OutlinedButton(
            onPressed: onEditProfile,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: scheme.outlineVariant.withOpacity(0.8)),
              minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
              padding: AppButtonTokens.padding,
              shape: AppButtonTokens.shape,
              textStyle: AppButtonTokens.textStyle,
            ),
            child: Text(
              AppLocalizations.of(context)!.editProfile,
              style: TextStyle(color: scheme.primary),
            ),
          ),
          SizedBox(height: AppResponsive.spacing(context, 12)),
          OutlinedButton(
            onPressed: onChangePassword,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: scheme.outlineVariant.withOpacity(0.8)),
              minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
              padding: AppButtonTokens.padding,
              shape: AppButtonTokens.shape,
              textStyle: AppButtonTokens.textStyle,
            ),
            child: Text(
              AppLocalizations.of(context)!.changePassword,
              style: TextStyle(color: scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
