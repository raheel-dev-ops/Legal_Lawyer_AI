import 'package:flutter/material.dart';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/theme/app_button_tokens.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(
            _emailController.text.trim().toLowerCase(),
          );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(l10n.resetLinkSent)),
        );
        context.pop();
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
    final scheme = Theme.of(context).colorScheme;
    final bgTop = scheme.background;
    final bgBottom = scheme.surfaceVariant;
    final cardTop = scheme.surface;
    final cardBottom = scheme.surfaceVariant;
    final fieldBg = scheme.surfaceVariant;
    final fieldBorder = scheme.outline;
    final textPrimary = scheme.onSurface;
    final textMuted = scheme.onSurfaceVariant;
    final iconMuted = scheme.onSurfaceVariant;
    final infoBg = scheme.surfaceVariant;
    final infoBorder = scheme.outlineVariant;
    final accent = scheme.primary;
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
                      SizedBox(height: AppResponsive.spacing(context, 6)),
                      Container(
                        height: AppResponsive.spacing(context, 190),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [cardTop, cardBottom],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withOpacity(0.16),
                              blurRadius: 30,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: AppResponsive.spacing(context, 74),
                            height: AppResponsive.spacing(context, 74),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.surface,
                              border: Border.all(color: fieldBorder, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.28),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: Icon(Icons.lock_reset_rounded, color: accent, size: 32),
                          ),
                        ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 24)),
                      Text(
                        l10n.forgotPasswordTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 10)),
                      Text(
                        l10n.forgotPasswordSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textMuted,
                              height: 1.5,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 24)),
                      Text(
                        l10n.emailAddress,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: l10n.emailPlaceholder,
                          hintStyle: TextStyle(color: textMuted),
                          prefixIcon: Icon(Icons.mail_outline, color: iconMuted),
                          filled: true,
                          fillColor: fieldBg,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: accent, width: 1.4),
                          ),
                        ),
                        style: TextStyle(color: textPrimary),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return l10n.emailRequired;
                          if (!value.contains('@')) return l10n.emailInvalid;
                          return null;
                        },
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 18)),
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
                                    Text(l10n.sendResetLink),
                                    SizedBox(width: AppResponsive.spacing(context, 8)),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 18)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${l10n.rememberPassword} ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: textMuted,
                                ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              l10n.login,
                              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 22)),
                      Container(
                        padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                        decoration: BoxDecoration(
                          color: infoBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: infoBorder),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: accent, size: 22),
                            SizedBox(width: AppResponsive.spacing(context, 12)),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: textMuted,
                                        height: 1.4,
                                      ),
                                  children: [
                                    TextSpan(text: l10n.supportHintPrefix),
                                    TextSpan(
                                      text: l10n.support,
                                      style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () => context.push('/support-contact'),
                                    ),
                                    TextSpan(text: l10n.supportHintSuffix),
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
        ),
      ),
    );
  }
}
