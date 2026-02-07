// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authStateNotifier)
final authStateProvider = AuthStateNotifierProvider._();

final class AuthStateNotifierProvider
    extends
        $FunctionalProvider<
          AuthStateNotifier,
          AuthStateNotifier,
          AuthStateNotifier
        >
    with $Provider<AuthStateNotifier> {
  AuthStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateNotifierHash();

  @$internal
  @override
  $ProviderElement<AuthStateNotifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthStateNotifier create(Ref ref) {
    return authStateNotifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthStateNotifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthStateNotifier>(value),
    );
  }
}

String _$authStateNotifierHash() => r'c993f13c150beeb0aec12e489b00718e779fea6f';

@ProviderFor(goRouter)
final goRouterProvider = GoRouterProvider._();

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'98b474d8b2965e1e85917a23fea1b55ab5de9a89';
