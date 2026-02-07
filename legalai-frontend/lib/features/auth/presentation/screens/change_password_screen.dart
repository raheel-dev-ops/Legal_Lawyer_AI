import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/widgets/safe_mode_banner.dart';
import '../../../../core/theme/app_button_tokens.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  final bool showSafeMode;

  const ChangePasswordScreen({super.key, this.showSafeMode = true});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  final _passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$');

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.showSafeMode && ref.read(safeModeProvider)) {
      final l10n = AppLocalizations.of(context)!;
      AppNotifications.showSnackBar(context,
        SnackBar(content: Text(l10n.safeModeDescription)),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            _currentController.text,
            _newController.text,
            _confirmController.text,
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.passwordUpdated)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      final err = ErrorMapper.from(e);
      if (mounted) {
        final message = err is AppException ? err.userMessage : err.toString();
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxWidth = AppResponsive.maxContentWidth(context);
    final cardWidth = maxWidth > 520 ? 520.0 : maxWidth;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final safeMode = widget.showSafeMode ? ref.watch(safeModeProvider) : false;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppResponsive.spacing(context, 20),
            AppResponsive.spacing(context, 20),
            AppResponsive.spacing(context, 20),
            AppResponsive.spacing(context, 20) + viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardWidth),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (widget.showSafeMode) ...[
                    const SafeModeBanner(),
                    SizedBox(height: AppResponsive.spacing(context, 16)),
                  ],
                  Container(
                    padding: EdgeInsets.all(AppResponsive.spacing(context, 20)),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: scheme.outline),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.lock_outline, color: scheme.primary),
                            ),
                            SizedBox(width: AppResponsive.spacing(context, 12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.changePassword,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(height: AppResponsive.spacing(context, 4)),
                                  Text(
                                    l10n.passwordRule,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 18)),
                        TextFormField(
                          controller: _currentController,
                          decoration: InputDecoration(
                            labelText: l10n.currentPassword,
                            prefixIcon: const Icon(Icons.key_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_showCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _showCurrent = !_showCurrent),
                            ),
                          ),
                          obscureText: !_showCurrent,
                          validator: (value) {
                            if (value == null || value.isEmpty) return l10n.currentPasswordRequired;
                            return null;
                          },
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 12)),
                        TextFormField(
                          controller: _newController,
                          decoration: InputDecoration(
                            labelText: l10n.newPassword,
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _showNew = !_showNew),
                            ),
                          ),
                          obscureText: !_showNew,
                          validator: (value) {
                            if (value == null || value.isEmpty) return l10n.newPasswordRequired;
                            if (!_passwordRegex.hasMatch(value)) {
                              return l10n.passwordRule;
                            }
                            if (value == _currentController.text) {
                              return l10n.newPasswordDifferent;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 12)),
                        TextFormField(
                          controller: _confirmController,
                          decoration: InputDecoration(
                            labelText: l10n.confirmNewPassword,
                            prefixIcon: const Icon(Icons.verified_user_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _showConfirm = !_showConfirm),
                            ),
                          ),
                          obscureText: !_showConfirm,
                          validator: (value) {
                            if (value == null || value.isEmpty) return l10n.confirmPasswordRequired;
                            if (value != _newController.text) return l10n.passwordsDoNotMatch;
                            return null;
                          },
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 16)),
                        Container(
                          padding: EdgeInsets.all(AppResponsive.spacing(context, 12)),
                          decoration: BoxDecoration(
                            color: scheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.passwordStrengthLabel,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: AppResponsive.spacing(context, 8)),
                              _RuleRow(text: l10n.passwordRuleLength),
                              _RuleRow(text: l10n.passwordRuleNumber),
                              _RuleRow(text: l10n.passwordRuleSpecial),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppResponsive.spacing(context, 20)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || safeMode ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
                        padding: AppButtonTokens.padding,
                        shape: AppButtonTokens.shape,
                        textStyle: AppButtonTokens.textStyle,
                      ),
                      child: _isSubmitting
                          ? CircularProgressIndicator(color: scheme.onPrimary)
                          : Text(l10n.updatePassword),
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

class _RuleRow extends StatelessWidget {
  final String text;
  const _RuleRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
