import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/google_signup_args.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/session/session_invalidator.dart';
import '../../../../core/preferences/preferences_providers.dart';
import '../../../../core/notifications/push_notifications_controller.dart';
import '../../../user_features/data/datasources/user_remote_data_source.dart';
import '../../../user_features/presentation/controllers/user_controller.dart';

part 'auth_controller.g.dart';

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  FutureOr<User?> build() async {
    ref.listen<int>(sessionInvalidationProvider, (prev, next) {
      if (prev != null && next != prev) {
        state = const AsyncValue.data(null);
        ref.read(appLoggerProvider).warn('auth.session.invalidated');
      }
    });
    return _checkUser();
  }

  Future<User?> _checkUser() async {
    final repo = ref.watch(authRepositoryProvider);
    try {
      final user = await repo.getCurrentUser();
      _syncLanguagePreference(user);
      return user;
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.session.check_failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    ref.read(appLoggerProvider).info('auth.login.start');
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.login(email, password);
      final user = await repo.getCurrentUser();
      _syncLanguagePreference(user);
      state = AsyncValue.data(user);
      ref.read(appLoggerProvider).info('auth.login.success', {
        'userId': user?.id,
      });
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.login.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
    }
  }

  Future<void> signup(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    ref.read(appLoggerProvider).info('auth.signup.start');
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signup(data);
      final user = await repo.getCurrentUser();
      _syncLanguagePreference(user);
      state = AsyncValue.data(user);
      ref.read(appLoggerProvider).info('auth.signup.success', {
        'userId': user?.id,
      });
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.signup.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    ref.read(appLoggerProvider).info('auth.logout.start');
    try {
      try {
        final googleSignIn = _buildGoogleSignIn();
        await _forceGoogleAccountChooser(googleSignIn);
      } catch (_) {
        ref.read(appLoggerProvider).warn('auth.logout.google_clear_skipped');
      }
      try {
        await ref.read(pushNotificationsControllerProvider.notifier).unregisterDeviceToken();
      } catch (e) {
        ref.read(appLoggerProvider).warn('auth.logout.push_unregister_failed');
      }
      try {
        await ref.read(userRepositoryProvider).clearActivityLog();
      } catch (e) {
        ref.read(appLoggerProvider).warn('auth.logout.activity_clear_failed');
      }
      await ref.read(authRepositoryProvider).logout();
      state = const AsyncValue.data(null);
      ref.read(userActivityProvider.notifier).clear();
      ref.read(appLoggerProvider).info('auth.logout.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.logout.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
    }
  }

  Future<void> forgotPassword(String email) async {
    ref.read(appLoggerProvider).info('auth.forgot_password.start');
    try {
      await ref.read(authRepositoryProvider).forgotPassword(email);
      ref.read(appLoggerProvider).info('auth.forgot_password.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.forgot_password.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    ref.read(appLoggerProvider).info('auth.reset_password.start');
    try {
      await ref.read(authRepositoryProvider).resetPassword(token, newPassword);
      ref.read(appLoggerProvider).info('auth.reset_password.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.reset_password.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    ref.read(appLoggerProvider).info('auth.change_password.start');
    try {
      await ref.read(authRepositoryProvider).changePassword(
        currentPassword,
        newPassword,
        confirmPassword,
      );
      ref.read(appLoggerProvider).info('auth.change_password.success');
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.change_password.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
      Error.throwWithStackTrace(err, st);
    }
  }

  GoogleSignIn _buildGoogleSignIn() {
    final webClientId = AppConstants.googleWebClientId.trim();
    final rawServerClientId = AppConstants.googleServerClientId.trim();
    final webMissing = _isMissingClientId(webClientId);
    final rawServerMissing = _isMissingClientId(rawServerClientId);
    final serverClientId = rawServerMissing ? webClientId : rawServerClientId;
    final serverMissing = _isMissingClientId(serverClientId);
    if (kIsWeb && webMissing) {
      throw AppException(
        userMessage:
            'Google web client ID missing. Set GOOGLE_WEB_CLIENT_ID and try again.',
      );
    }
    if (!kIsWeb && serverMissing) {
      throw AppException(
        userMessage:
            'Google client ID missing. Set GOOGLE_SERVER_CLIENT_ID and try again.',
      );
    }
    return GoogleSignIn(
      scopes: const ['email'],
      clientId: kIsWeb ? webClientId : null,
      serverClientId: !kIsWeb ? serverClientId : null,
    );
  }

  Future<void> _forceGoogleAccountChooser(GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.disconnect();
      ref.read(appLoggerProvider).info('auth.google.disconnect');
      return;
    } catch (_) {
      // Fall back to signOut if disconnect is not supported or fails.
    }
    try {
      await googleSignIn.signOut();
      ref.read(appLoggerProvider).info('auth.google.signout');
    } catch (_) {
      ref.read(appLoggerProvider).warn('auth.google.signout_failed');
    }
  }

  bool _isMissingClientId(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized.contains('your_') || normalized.contains('replace');
  }

  Future<GoogleSignupArgs?> loginWithGoogle() async {
    final previousState = state;
    state = const AsyncValue.loading();
    ref.read(appLoggerProvider).info('auth.google.start');
    try {
      final googleSignIn = _buildGoogleSignIn();
      await _forceGoogleAccountChooser(googleSignIn);
      final account = await googleSignIn.signIn();
      if (account == null) {
        state = previousState;
        return null;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw AppException(userMessage: 'Google sign-in failed. Please try again.');
      }
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.loginWithGoogle(idToken);
      if (response['needsProfile'] == true) {
        final googleToken = response['googleToken'];
        if (googleToken is! String || googleToken.trim().isEmpty) {
          throw AppException(userMessage: 'Google sign-in failed. Please try again.');
        }
        state = const AsyncValue.data(null);
        final prefill = response['prefill'];
        return GoogleSignupArgs(
          googleToken: googleToken,
          name: prefill is Map ? prefill['name']?.toString() : null,
          email: prefill is Map ? prefill['email']?.toString() : null,
        );
      }
      final user = await repo.getCurrentUser();
      _syncLanguagePreference(user);
      state = AsyncValue.data(user);
      ref.read(appLoggerProvider).info('auth.google.success', {
        'userId': user?.id,
      });
      return null;
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.google.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
      return null;
    }
  }

  Future<void> completeGoogleSignup(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    ref.read(appLoggerProvider).info('auth.google.complete.start');
    try {
      await ref.read(authRepositoryProvider).completeGoogleSignup(data);
      final user = await ref.read(authRepositoryProvider).getCurrentUser();
      _syncLanguagePreference(user);
      state = AsyncValue.data(user);
      ref.read(appLoggerProvider).info('auth.google.complete.success', {
        'userId': user?.id,
      });
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.google.complete.failed', {
        'status': err.statusCode,
      });
      state = AsyncValue.error(err, st);
      Error.throwWithStackTrace(err, st);
    }
  }

  Future<bool> verifyEmail(String token) async {
    ref.read(appLoggerProvider).info('auth.verify_email.start');
    try {
      final ok = await ref.read(authRepositoryProvider).verifyEmail(token);
      ref.read(appLoggerProvider).info('auth.verify_email.success');
      return ok;
    } catch (e, st) {
      final err = ErrorMapper.from(e);
      ref.read(appLoggerProvider).warn('auth.verify_email.failed', {
        'status': err.statusCode,
      });
      Error.throwWithStackTrace(err, st);
    }
  }

  void _syncLanguagePreference(User? user) {
    final lang = user?.language?.trim().toLowerCase();
    if (lang == null || (lang != 'en' && lang != 'ur')) {
      return;
    }
    final current = ref.read(appLanguageProvider);
    if (current != lang) {
      ref.read(appLanguageProvider.notifier).setLanguage(lang);
    }
  }
}
