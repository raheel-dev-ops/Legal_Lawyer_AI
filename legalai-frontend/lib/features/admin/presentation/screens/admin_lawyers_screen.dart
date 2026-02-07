import 'package:cached_network_image/cached_network_image.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/utils/media_url.dart';
import '../../../directory/domain/models/lawyer_model.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminLawyersProvider = FutureProvider.autoDispose<List<Lawyer>>((ref) async {
  return ref.watch(adminRepositoryProvider).getLawyers();
});

final lawyerCategoriesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return ref.watch(adminRepositoryProvider).getLawyerCategories();
});

class AdminLawyersScreen extends ConsumerWidget {
  const AdminLawyersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lawyersAsync = ref.watch(adminLawyersProvider);
    final l10n = AppLocalizations.of(context)!;

    return AdminPage(
      title: l10n.adminNavLawyers,
      subtitle: l10n.adminLawyersSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showLawyerForm(context, ref, null),
          icon: const Icon(Icons.add),
          label: Text(l10n.adminNewLawyer),
        ),
      ],
      body: lawyersAsync.when(
        data: (lawyers) {
          if (lawyers.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoLawyersTitle,
                message: l10n.adminNoLawyersMessage,
                icon: Icons.gavel_outlined,
              ),
            );
          }
          return ListView.separated(
            itemCount: lawyers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lawyer = lawyers[index];
              final statusLabel = lawyer.isVerified ? l10n.adminStatusActive : l10n.adminStatusInactive;
              final statusColor = lawyer.isVerified ? AdminColors.success : AdminColors.warning;
              const avatarRadius = 22.0;
              final avatarSize = avatarRadius * 2;
              final dpr = MediaQuery.devicePixelRatioOf(context);
              final cacheSize = (avatarSize * dpr).round();
              final initials = lawyer.name.isNotEmpty ? lawyer.name[0] : 'L';
              return AdminCard(
                key: ValueKey(lawyer.id),
                child: Row(
                  children: [
                    if (lawyer.imageUrl == null)
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: AdminColors.primary.withOpacity(0.12),
                        child: Text(initials, style: TextStyle(color: AdminColors.primary)),
                      )
                    else
                      CachedNetworkImage(
                        imageUrl: lawyer.imageUrl!,
                        httpHeaders: resolveMediaHeaders(lawyer.imageUrl),
                        cacheManager: mediaCacheManager(),
                        width: avatarSize,
                        height: avatarSize,
                        memCacheWidth: cacheSize,
                        memCacheHeight: cacheSize,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: avatarRadius,
                          backgroundImage: imageProvider,
                          backgroundColor: AdminColors.primary.withOpacity(0.12),
                        ),
                        placeholder: (context, url) => CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: AdminColors.primary.withOpacity(0.12),
                          child: Text(initials, style: TextStyle(color: AdminColors.primary)),
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: AdminColors.primary.withOpacity(0.12),
                          child: Text(initials, style: TextStyle(color: AdminColors.primary)),
                        ),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lawyer.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lawyer.specialization,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(statusLabel),
                      backgroundColor: statusColor.withOpacity(0.16),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(value: 'deactivate', child: Text(l10n.adminDeactivate)),
                      ],
                      onSelected: (val) async {
                        if (val == 'edit') {
                          await _showLawyerForm(context, ref, lawyer);
                        } else if (val == 'deactivate') {
                          await _deactivateLawyer(context, ref, lawyer.id);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(l10n.errorWithMessage(err.toString()))),
      ),
    );
  }

  Future<void> _showLawyerForm(BuildContext context, WidgetRef ref, Lawyer? lawyer) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: lawyer?.name ?? '');
    final emailController = TextEditingController(text: lawyer?.email ?? '');
    final phoneController = TextEditingController(text: lawyer?.phone ?? '');
    String? category = lawyer?.specialization;
    PlatformFile? imageFile;

    final categories = await ref.read(lawyerCategoriesProvider.future);

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(lawyer == null ? l10n.adminCreateLawyer : l10n.adminEditLawyer),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.fullName)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: l10n.email),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: l10n.phone),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      value: category,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l10n.category),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      selectedItemBuilder: (context) => categories
                          .map(
                            (c) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                c,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => category = value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: kIsWeb);
                      if (result == null || result.files.isEmpty) {
                        return;
                      }
                      final selected = result.files.single;
                      final error = _validateImageFile(selected, l10n);
                      if (error != null) {
                        if (context.mounted) {
                          AppNotifications.showSnackBar(context, SnackBar(content: Text(error)));
                        }
                        return;
                      }
                      setState(() => imageFile = selected);
                    },
                    child: Text(imageFile == null ? l10n.adminSelectImage : l10n.adminChangeImage),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
            ],
          ),
        ),
      );

      if (result != true) return;

      final name = nameController.text.trim();
      final email = emailController.text.trim().toLowerCase();
      final phone = phoneController.text.trim();

      if (name.isEmpty || email.isEmpty || phone.isEmpty || category == null || category!.trim().isEmpty) {
        if (context.mounted) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.adminAllFieldsRequired)),
          );
        }
        return;
      }
      if (!_isValidEmail(email)) {
        if (context.mounted) {
          AppNotifications.showSnackBar(context,
            SnackBar(content: Text(l10n.emailInvalid)),
          );
        }
        return;
      }
      if (imageFile != null) {
        final error = _validateImageFile(imageFile!, l10n);
        if (error != null) {
          if (context.mounted) {
            AppNotifications.showSnackBar(context, SnackBar(content: Text(error)));
          }
          return;
        }
      }

      if (lawyer == null) {
        if (imageFile == null) {
          if (context.mounted) {
            AppNotifications.showSnackBar(context,
              SnackBar(content: Text(l10n.adminProfilePictureRequired)),
            );
          }
          return;
        }
        await ref.read(adminRepositoryProvider).createLawyer({
          'fullName': name,
          'email': email,
          'phone': phone,
          'category': category,
        }, imageFile!);
      } else {
        await ref.read(adminRepositoryProvider).updateLawyer(
          lawyer.id,
          {
            'fullName': name,
            'email': email,
            'phone': phone,
            'category': category,
          },
          imageFile,
        );
      }
      ref.invalidate(adminLawyersProvider);
      ref.invalidate(lawyersTotalProvider);
      ref.read(adminDashboardRefreshProvider.notifier).state++;
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    } finally {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    }
  }

  Future<void> _deactivateLawyer(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeactivateLawyerTitle),
        content: Text(l10n.adminDeactivateLawyerConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.adminDeactivate)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).deactivateLawyer(id);
      ref.invalidate(adminLawyersProvider);
      ref.invalidate(lawyersTotalProvider);
      ref.read(adminDashboardRefreshProvider.notifier).state++;
    } catch (e) {
      final err = ErrorMapper.from(e);
      final message = err is AppException ? err.userMessage : err.toString();
      if (context.mounted) {
        AppNotifications.showSnackBar(context, SnackBar(content: Text(message)));
      }
    }
  }
}

const int _maxAvatarBytes = 5 * 1024 * 1024;

bool _isValidEmail(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  final at = trimmed.indexOf('@');
  if (at <= 0 || at >= trimmed.length - 3) return false;
  return trimmed.contains('.', at);
}

String _fileExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

String? _validateImageFile(PlatformFile file, AppLocalizations l10n) {
  final ext = _fileExtension(file.name);
  if (ext.isEmpty || !{'jpg', 'jpeg', 'png'}.contains(ext)) {
    return l10n.adminImageTypeNotAllowed;
  }
  if (file.size > _maxAvatarBytes) {
    return l10n.adminImageTooLarge;
  }
  if (file.bytes == null && (file.path == null || file.path!.isEmpty)) {
    return l10n.adminImageDataMissing;
  }
  return null;
}
