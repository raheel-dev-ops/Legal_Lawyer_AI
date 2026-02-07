import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/utils/media_url.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_button_tokens.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_layout.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  bool _updatingLanguage = false;

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
      await ref.read(userRepositoryProvider).uploadAvatar(platformFile);
      ref.invalidate(authControllerProvider);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.profilePhotoUpdated)),
        );
      }
    } catch (_) {
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

  Future<void> _updateLanguage(String value) async {
    if (_updatingLanguage) return;
    final current = ref.read(appLanguageProvider);
    if (current == value) return;
    setState(() => _updatingLanguage = true);
    ref.read(appLanguageProvider.notifier).setLanguage(value);
    var updatedRemote = false;
    try {
      final user = ref.read(authControllerProvider).value;
      if (user != null) {
        await ref.read(userRepositoryProvider).updateProfile({'language': value});
        updatedRemote = true;
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      if (mounted) {
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(err.userMessage)),
        );
      }
    } finally {
      if (updatedRemote) {
        ref.invalidate(authControllerProvider);
      }
      if (mounted) setState(() => _updatingLanguage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).value;
    final initials =
        (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim()[0] : l10n.userInitialFallback;
    final avatarProvider = resolveMediaImageProvider(
      context,
      user?.avatarPath,
      width: 124,
      height: 124,
    );
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(appLanguageProvider);
    final isCompact =
        MediaQuery.sizeOf(context).width < 360 || MediaQuery.textScaleFactorOf(context) > 1.1;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => context.go('/admin/overview'),
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
            Expanded(
              child: Center(
                child: Text(
                  l10n.adminConfiguration.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 2,
                        color: AdminColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Stack(
            children: [
              InkWell(
                onTap: _showPhotoSourceDialog,
                borderRadius: BorderRadius.circular(70),
                child: CircleAvatar(
                  radius: 62,
                  backgroundColor: AdminColors.surfaceAlt,
                  foregroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? Text(
                          initials,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AdminColors.primary,
                              ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: InkWell(
                  onTap: _showPhotoSourceDialog,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AdminColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Icon(Icons.edit, size: 18, color: AdminColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(
                user?.name ?? l10n.adminLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.adminRoleSeniorLegalAdministrator.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AdminColors.textSecondary,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: () => context.push('/admin/profile/edit'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AdminColors.border),
            minimumSize: const Size(0, AppButtonTokens.minHeight),
            padding: AppButtonTokens.padding,
            shape: AppButtonTokens.shape,
            textStyle: AppButtonTokens.textStyle,
          ),
          child: Text(l10n.editProfile),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () => context.push('/admin/change-password'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AdminColors.border),
            minimumSize: const Size(0, AppButtonTokens.minHeight),
            padding: AppButtonTokens.padding,
            shape: AppButtonTokens.shape,
            textStyle: AppButtonTokens.textStyle,
          ),
          child: Text(l10n.changePassword),
        ),
        const SizedBox(height: 28),
        Text(
          l10n.preferences.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AdminColors.textSecondary,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        AdminCard(
          padding: const EdgeInsets.all(14),
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminPreferenceSection(
                icon: Icons.palette_outlined,
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
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),
              _AdminPreferenceSection(
                icon: Icons.language_outlined,
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
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AdminColors.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            minimumSize: const Size(0, AppButtonTokens.minHeight),
            padding: AppButtonTokens.padding,
            shape: AppButtonTokens.shape,
            textStyle: AppButtonTokens.textStyle,
            elevation: 0,
          ),
          icon: const Icon(Icons.logout),
          label: Text(l10n.logout),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _AdminPreferenceSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _AdminPreferenceSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AdminColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Icon(icon, color: AdminColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
