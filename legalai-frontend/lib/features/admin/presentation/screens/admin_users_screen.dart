import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../controllers/admin_controller.dart';
import '../widgets/admin_layout.dart';
import '../theme/admin_theme.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(adminRepositoryProvider).getUsers();
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final l10n = AppLocalizations.of(context)!;

    return AdminPage(
      title: l10n.adminNavUsers,
      subtitle: l10n.adminUsersSubtitle,
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showUserForm(context, ref, null),
          icon: const Icon(Icons.person_add),
          label: Text(l10n.adminNewUser),
        ),
      ],
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: AdminEmptyState(
                title: l10n.adminNoUsersTitle,
                message: l10n.adminNoUsersMessage,
                icon: Icons.people_outline,
              ),
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final name = (user['name'] ?? '').toString();
              final email = (user['email'] ?? '').toString();
              final isAdmin = user['isAdmin'] == true;
              final isDeleted = user['isDeleted'] == true;
              return AdminCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AdminColors.primary.withOpacity(0.12),
                      child: Text(
                        name.isNotEmpty ? name[0] : l10n.userInitialFallback,
                        style: TextStyle(color: AdminColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? l10n.adminUnnamedUser : name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (isAdmin)
                          Chip(
                            label: Text(l10n.adminRoleAdmin),
                            backgroundColor: AdminColors.accent.withOpacity(0.18),
                          ),
                        if (isDeleted)
                          Chip(
                            label: Text(l10n.adminStatusDeleted),
                            backgroundColor: AdminColors.error.withOpacity(0.12),
                            labelStyle: TextStyle(color: AdminColors.error),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _showUserForm(context, ref, user);
                        } else if (value == 'delete') {
                          await _deleteUser(context, ref, user['id'] as int);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          enabled: !isDeleted,
                          child: Text(l10n.edit),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          enabled: !isDeleted,
                          child: Text(l10n.delete),
                        ),
                      ],
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

  Future<void> _showUserForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? user) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: user?['name']?.toString() ?? '');
    final emailController = TextEditingController(text: user?['email']?.toString() ?? '');
    final phoneController = TextEditingController(text: user?['phone']?.toString() ?? '');
    final cnicController = TextEditingController(text: user?['cnic']?.toString() ?? '');
    final passwordController = TextEditingController();
    bool isAdmin = user?['isAdmin'] == true;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(user == null ? l10n.adminCreateUser : l10n.adminEditUser),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: l10n.name)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: l10n.email),
                    enabled: user == null,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: l10n.phone),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cnicController,
                    decoration: InputDecoration(labelText: l10n.cnic),
                    enabled: user == null,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: user == null ? l10n.password : l10n.adminNewPasswordOptional),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: isAdmin,
                    title: Text(l10n.adminRoleAdmin),
                    onChanged: (value) => setState(() => isAdmin = value),
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

      if (user == null) {
        final name = nameController.text.trim();
        final email = emailController.text.trim().toLowerCase();
        final phone = phoneController.text.trim();
        final cnic = cnicController.text.trim();
        final password = passwordController.text;

        if (name.isEmpty || email.isEmpty || phone.isEmpty || cnic.isEmpty || password.isEmpty) {
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
        if (!_isValidPassword(password)) {
          if (context.mounted) {
            AppNotifications.showSnackBar(context,
              SnackBar(content: Text(l10n.adminPasswordRuleStrict)),
            );
          }
          return;
        }
        await ref.read(adminRepositoryProvider).createUser({
          'name': name,
          'email': email,
          'phone': phone,
          'cnic': cnic,
          'password': password,
          'isAdmin': isAdmin,
        });
      } else {
        final name = nameController.text.trim();
        final phone = phoneController.text.trim();
        if (name.isEmpty || phone.isEmpty) {
          if (context.mounted) {
            AppNotifications.showSnackBar(context,
              SnackBar(content: Text(l10n.adminNamePhoneRequired)),
            );
          }
          return;
        }
        final data = <String, dynamic>{
          'name': name,
          'phone': phone,
          'isAdmin': isAdmin,
        };
        if (passwordController.text.trim().isNotEmpty) {
          final password = passwordController.text;
          if (!_isValidPassword(password)) {
            if (context.mounted) {
              AppNotifications.showSnackBar(context,
                SnackBar(content: Text(l10n.adminPasswordRuleStrict)),
              );
            }
            return;
          }
          data['password'] = password;
        }
        await ref.read(adminRepositoryProvider).updateUser(user['id'] as int, data);
      }
      ref.invalidate(adminUsersProvider);
      ref.invalidate(usersTotalProvider);
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
      cnicController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _deleteUser(BuildContext context, WidgetRef ref, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDeleteUserTitle),
        content: Text(l10n.adminDeleteUserConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteUser(id);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(usersTotalProvider);
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

final RegExp _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$');

bool _isValidEmail(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  final at = trimmed.indexOf('@');
  if (at <= 0 || at >= trimmed.length - 3) return false;
  return trimmed.contains('.', at);
}

bool _isValidPassword(String value) {
  return _passwordRegex.hasMatch(value);
}
