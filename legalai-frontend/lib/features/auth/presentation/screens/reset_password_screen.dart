import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_button_tokens.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _strengthScore = 0;

  final _passwordRegex = RegExp(r'^(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenController.text = widget.token!;
    }
    _newController.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _newController.removeListener(_updateStrength);
    _tokenController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final pwd = _newController.text;
    final hasMin = pwd.length >= 8;
    final hasNumber = RegExp(r'\d').hasMatch(pwd);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(pwd);
    final score = [hasMin, hasNumber, hasSpecial].where((v) => v).length;
    if (score != _strengthScore) {
      setState(() => _strengthScore = score);
    }
  }

  Color _strengthColor() {
    if (_strengthScore <= 1) return AppPalette.error;
    if (_strengthScore == 2) return AppPalette.warning;
    return AppPalette.success;
  }

  String _strengthLabel(AppLocalizations l10n) {
    if (_strengthScore <= 1) return l10n.passwordStrengthWeak;
    if (_strengthScore == 2) return l10n.passwordStrengthMedium;
    return l10n.passwordStrengthStrong;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            widget.token?.trim().isNotEmpty == true
                ? widget.token!.trim()
                : _tokenController.text.trim(),
            _newController.text,
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.passwordResetSuccess)),
        );
        context.go('/login');
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
    final showTokenField = widget.token == null || widget.token!.isEmpty;
    final scheme = Theme.of(context).colorScheme;
    final bgTop = scheme.background;
    final bgBottom = scheme.surfaceVariant;
    final fieldBg = scheme.surfaceVariant;
    final fieldBorder = scheme.outline;
    final textPrimary = scheme.onSurface;
    final textMuted = scheme.onSurfaceVariant;
    final iconMuted = scheme.onSurfaceVariant;
    final trackColor = scheme.outlineVariant;
    final inactiveRule = scheme.onSurfaceVariant.withOpacity(0.7);
    final accent = scheme.primary;
    final strengthColor = _strengthColor();
    final fillCount = (_strengthScore + 1).clamp(1, 4);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(AppResponsive.spacing(context, 24)),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      Text(
                        l10n.resetPasswordHeadline,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      Text(
                        l10n.resetPasswordSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textMuted,
                              height: 1.5,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 22)),
                      if (showTokenField) ...[
                        Text(
                          l10n.resetToken,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 8)),
                        TextFormField(
                          controller: _tokenController,
                          decoration: _fieldDecoration(
                            l10n.resetToken,
                            fieldBg: fieldBg,
                            fieldBorder: fieldBorder,
                            hintColor: textMuted,
                            focusColor: accent,
                          ),
                          style: TextStyle(color: textPrimary),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return l10n.tokenRequired;
                            return null;
                          },
                        ),
                        SizedBox(height: AppResponsive.spacing(context, 16)),
                      ],
                      Text(
                        l10n.newPassword,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      TextFormField(
                        controller: _newController,
                        decoration: _fieldDecoration(
                          l10n.newPassword,
                          hint: l10n.newPassword,
                          fieldBg: fieldBg,
                          fieldBorder: fieldBorder,
                          hintColor: textMuted,
                          focusColor: accent,
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                            icon: Icon(
                              _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: iconMuted,
                            ),
                          ),
                        ),
                        style: TextStyle(color: textPrimary),
                        obscureText: _obscureNew,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.newPasswordRequired;
                          if (!_passwordRegex.hasMatch(value)) return l10n.passwordRule;
                          return null;
                        },
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.passwordStrengthLabel,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: textMuted,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            _strengthLabel(l10n),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: strengthColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 10)),
                      Row(
                        children: List.generate(
                          4,
                          (index) => Expanded(
                            child: Container(
                              height: 6,
                              margin: EdgeInsets.only(
                                right: index == 3 ? 0 : AppResponsive.spacing(context, 8),
                              ),
                              decoration: BoxDecoration(
                                color: index < fillCount ? strengthColor : trackColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 16)),
                      _PasswordRequirement(
                        met: _newController.text.length >= 8,
                        text: l10n.passwordRuleLength,
                        activeColor: AppPalette.success,
                        inactiveColor: inactiveRule,
                        inactiveText: textMuted,
                      ),
                      _PasswordRequirement(
                        met: RegExp(r'\d').hasMatch(_newController.text),
                        text: l10n.passwordRuleNumber,
                        activeColor: AppPalette.success,
                        inactiveColor: inactiveRule,
                        inactiveText: textMuted,
                      ),
                      _PasswordRequirement(
                        met: RegExp(r'[^A-Za-z0-9]').hasMatch(_newController.text),
                        text: l10n.passwordRuleSpecial,
                        activeColor: AppPalette.success,
                        inactiveColor: inactiveRule,
                        inactiveText: textMuted,
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 18)),
                      Text(
                        l10n.confirmNewPassword,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      TextFormField(
                        controller: _confirmController,
                        decoration: _fieldDecoration(
                          l10n.confirmNewPassword,
                          hint: l10n.reenterPasswordHint,
                          fieldBg: fieldBg,
                          fieldBorder: fieldBorder,
                          hintColor: textMuted,
                          focusColor: accent,
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: iconMuted,
                            ),
                          ),
                        ),
                        style: TextStyle(color: textPrimary),
                        obscureText: _obscureConfirm,
                        validator: (value) {
                          if (value == null || value.isEmpty) return l10n.confirmPasswordRequired;
                          if (value != _newController.text) return l10n.passwordsDoNotMatch;
                          return null;
                        },
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 26)),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: scheme.onPrimary,
                            minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
                            padding: AppButtonTokens.padding,
                            shape: AppButtonTokens.shape,
                            textStyle: AppButtonTokens.textStyle,
                          ),
                          child: _isSubmitting
                              ? CircularProgressIndicator(color: scheme.onPrimary)
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(l10n.resetPassword),
                                    SizedBox(width: AppResponsive.spacing(context, 8)),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String label, {
    String? hint,
    Widget? suffix,
    required Color fieldBg,
    required Color fieldBorder,
    required Color hintColor,
    required Color focusColor,
  }) {
    return InputDecoration(
      hintText: hint ?? label,
      hintStyle: TextStyle(color: hintColor),
      filled: true,
      fillColor: fieldBg,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: focusColor, width: 1.4),
      ),
      suffixIcon: suffix,
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  final bool met;
  final String text;
  final Color activeColor;
  final Color inactiveColor;
  final Color inactiveText;

  const _PasswordRequirement({
    required this.met,
    required this.text,
    required this.activeColor,
    required this.inactiveColor,
    required this.inactiveText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppResponsive.spacing(context, 10)),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: met ? activeColor : inactiveColor,
            size: 20,
          ),
          SizedBox(width: AppResponsive.spacing(context, 10)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: met ? activeColor : inactiveText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
