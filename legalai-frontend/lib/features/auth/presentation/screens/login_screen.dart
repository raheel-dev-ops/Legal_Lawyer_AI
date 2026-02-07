import 'dart:convert';
import 'package:legalai_frontend/core/utils/app_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/layout/app_responsive.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/theme/app_button_tokens.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loadingSaved = true;
  bool _isAutofilling = false;
  bool _passwordTouched = false;
  bool _googleLoading = false;
  Map<String, String> _savedAccounts = {};

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
    _emailController.addListener(_handleEmailChange);
    _passwordController.addListener(_handlePasswordChange);
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleEmailChange);
    _passwordController.removeListener(_handlePasswordChange);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    final args = await ref.read(authControllerProvider.notifier).loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (args != null) {
      context.push('/signup', extra: args);
    }
  }

  Future<void> _loadRememberedCredentials() async {
    final storage = ref.read(secureStorageProvider);
    final remember = await storage.read(key: AppConstants.rememberMeKey);
    if (!mounted) return;
    final shouldRemember = remember == 'true';
    String savedEmail = '';
    String savedPassword = '';
    Map<String, String> accounts = {};
    if (shouldRemember) {
      final accountsRaw = await storage.read(key: AppConstants.rememberAccountsKey);
      if (accountsRaw != null && accountsRaw.trim().isNotEmpty) {
        final decoded = jsonDecode(accountsRaw);
        if (decoded is Map<String, dynamic>) {
          accounts = decoded.map((key, value) => MapEntry(key, value.toString()));
        }
      } else {
        final legacyEmail = await storage.read(key: AppConstants.rememberEmailKey);
        final legacyPassword = await storage.read(key: AppConstants.rememberPasswordKey);
        if ((legacyEmail ?? '').isNotEmpty && (legacyPassword ?? '').isNotEmpty) {
          accounts = {legacyEmail!.trim(): legacyPassword!};
          await storage.write(
            key: AppConstants.rememberAccountsKey,
            value: jsonEncode(accounts),
          );
        }
      }
      savedEmail = await storage.read(key: AppConstants.rememberLastEmailKey) ?? '';
      if (savedEmail.isEmpty && accounts.isNotEmpty) {
        savedEmail = accounts.keys.first;
      }
      if (savedEmail.isNotEmpty) {
        savedPassword = accounts[savedEmail] ?? '';
      }
    }
    if (!mounted) return;
    setState(() {
      _rememberMe = shouldRemember;
      _loadingSaved = false;
      _savedAccounts = accounts;
      if (savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
      if (savedPassword.isNotEmpty) {
        _isAutofilling = true;
        _passwordController.text = savedPassword;
        _isAutofilling = false;
      }
    });
  }

  Future<void> _persistRememberedCredentials() async {
    final storage = ref.read(secureStorageProvider);
    if (!_rememberMe) {
      await storage.delete(key: AppConstants.rememberMeKey);
      await storage.delete(key: AppConstants.rememberEmailKey);
      await storage.delete(key: AppConstants.rememberPasswordKey);
      await storage.delete(key: AppConstants.rememberAccountsKey);
      await storage.delete(key: AppConstants.rememberLastEmailKey);
      _savedAccounts = {};
      return;
    }
    await storage.write(key: AppConstants.rememberMeKey, value: 'true');
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    _savedAccounts[email] = _passwordController.text;
    await storage.write(
      key: AppConstants.rememberAccountsKey,
      value: jsonEncode(_savedAccounts),
    );
    await storage.write(key: AppConstants.rememberLastEmailKey, value: email);
  }

  void _handleEmailChange() {
    if (_loadingSaved || !_rememberMe) return;
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    final saved = _savedAccounts[email];
    if (saved == null) {
      if (!_passwordTouched) {
        _isAutofilling = true;
        _passwordController.text = '';
        _isAutofilling = false;
      }
      return;
    }
    if (_passwordTouched && _passwordController.text.isNotEmpty) return;
    _isAutofilling = true;
    _passwordController.text = saved;
    _isAutofilling = false;
    _passwordTouched = false;
  }

  void _handlePasswordChange() {
    if (_isAutofilling) return;
    _passwordTouched = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authControllerProvider);
    final maxWidth = AppResponsive.maxContentWidth(context);
    final cardWidth = maxWidth > 520 ? 520.0 : maxWidth;
    final scheme = Theme.of(context).colorScheme;

    final bgTop = scheme.background;
    final bgBottom = scheme.surfaceVariant;
    final fieldBg = scheme.surfaceVariant;
    final fieldBorder = scheme.outline;
    final accent = scheme.primary;
    final textPrimary = scheme.onSurface;
    final textMuted = scheme.onSurfaceVariant;
    final iconMuted = scheme.onSurfaceVariant;
    final cardSurface = scheme.surface;
    final cardBorder = scheme.outline;
    final googleBg = scheme.surface;
    final dividerColor = scheme.outlineVariant;
    final googleLabel = l10n.signInWithGoogle;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        final err = next.error;
        final message = err is AppException ? err.userMessage : err.toString();
        AppNotifications.showSnackBar(context,
          SnackBar(content: Text(message)),
        );
      }
      if (previous?.isLoading == true && next.hasValue && next.value != null) {
        _persistRememberedCredentials();
      }
      // Success is handled by router redirect
    });

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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppResponsive.spacing(context, 24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: AppResponsive.spacing(context, 92),
                          height: AppResponsive.spacing(context, 92),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cardSurface,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.35),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(color: cardBorder, width: 1.2),
                          ),
                          child: Icon(Icons.shield_outlined, color: accent, size: 38),
                        ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 20)),
                      Text(
                        l10n.loginTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      Text(
                        l10n.loginSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textMuted,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 28)),
                      Text(
                        l10n.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: l10n.enterEmail,
                          hintStyle: TextStyle(color: textMuted),
                          prefixIcon: Icon(Icons.email_outlined, color: iconMuted),
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
                        validator: (value) => value!.isEmpty ? l10n.enterEmail : null,
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 16)),
                      Text(
                        l10n.password,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: l10n.enterPassword,
                          hintStyle: TextStyle(color: textMuted),
                          prefixIcon: Icon(Icons.lock_outline, color: iconMuted),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: iconMuted,
                            ),
                          ),
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
                        obscureText: _obscurePassword,
                        validator: (value) => value!.isEmpty ? l10n.enterPassword : null,
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 10)),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: _loadingSaved
                                ? null
                                : (v) {
                                    setState(() => _rememberMe = v ?? false);
                                    if (!_rememberMe) {
                                      _persistRememberedCredentials();
                                    }
                                  },
                            activeColor: accent,
                            side: BorderSide(color: fieldBorder),
                          ),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: textMuted,
                                ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text(
                              l10n.forgotPassword,
                              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      ElevatedButton(
                        onPressed: state.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: scheme.onPrimary,
                          minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
                          padding: AppButtonTokens.padding,
                          shape: AppButtonTokens.shape,
                          textStyle: AppButtonTokens.textStyle,
                        ),
                        child: state.isLoading
                            ? CircularProgressIndicator(color: scheme.onPrimary)
                            : Text(l10n.login),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 22)),
                      Row(
                        children: [
                          Expanded(child: Divider(color: dividerColor)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppResponsive.spacing(context, 12)),
                            child: Text('OR', style: TextStyle(color: textMuted)),
                          ),
                          Expanded(child: Divider(color: dividerColor)),
                        ],
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 16)),
                      OutlinedButton(
                        onPressed: _googleLoading ? null : _loginWithGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: fieldBorder),
                          minimumSize: const Size(double.infinity, AppButtonTokens.minHeight),
                          padding: AppButtonTokens.padding,
                          shape: AppButtonTokens.shape,
                          textStyle: AppButtonTokens.textStyle,
                          backgroundColor: googleBg,
                        ),
                        child: _googleLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: textPrimary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/google_g.png',
                                        width: 18,
                                        height: 18,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Text(
                                              'G',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF4285F4),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: AppResponsive.spacing(context, 12)),
                                  Text(
                                    googleLabel,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                      SizedBox(height: AppResponsive.spacing(context, 26)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: textMuted,
                                ),
                          ),
                          GestureDetector(
                            onTap: () => context.push('/signup'),
                            child: Text(
                              l10n.signUp,
                              style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
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
