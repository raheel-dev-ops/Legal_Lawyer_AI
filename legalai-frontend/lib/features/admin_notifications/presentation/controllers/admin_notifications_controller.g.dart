// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_notifications_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminNotifications)
final adminNotificationsProvider = AdminNotificationsProvider._();

final class AdminNotificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminNotification>>,
          List<AdminNotification>,
          FutureOr<List<AdminNotification>>
        >
    with
        $FutureModifier<List<AdminNotification>>,
        $FutureProvider<List<AdminNotification>> {
  AdminNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminNotificationsHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminNotification>> create(Ref ref) {
    return adminNotifications(ref);
  }
}

String _$adminNotificationsHash() =>
    r'1fdb0f6d1c94c2b646c9b7b406cd2b8f5a776a8a';

@ProviderFor(adminNotificationsUnreadCount)
final adminNotificationsUnreadCountProvider =
    AdminNotificationsUnreadCountProvider._();

final class AdminNotificationsUnreadCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  AdminNotificationsUnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminNotificationsUnreadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminNotificationsUnreadCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return adminNotificationsUnreadCount(ref);
  }
}

String _$adminNotificationsUnreadCountHash() =>
    r'6c6a8b38f4d1b3f0a9edee13c0bba9f36f3d2c1b';

@ProviderFor(AdminNotificationsController)
final adminNotificationsControllerProvider =
    AdminNotificationsControllerProvider._();

final class AdminNotificationsControllerProvider
    extends $NotifierProvider<AdminNotificationsController, void> {
  AdminNotificationsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminNotificationsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminNotificationsControllerHash();

  @$internal
  @override
  AdminNotificationsController create() => AdminNotificationsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$adminNotificationsControllerHash() =>
    r'1aa06c1fb0b774985e0a9a1f37b59cfd1ebc3f9b';

abstract class _$AdminNotificationsController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AdminNotificationsStreamController)
final adminNotificationsStreamControllerProvider =
    AdminNotificationsStreamControllerProvider._();

final class AdminNotificationsStreamControllerProvider
    extends $NotifierProvider<AdminNotificationsStreamController, void> {
  AdminNotificationsStreamControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminNotificationsStreamControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$adminNotificationsStreamControllerHash();

  @$internal
  @override
  AdminNotificationsStreamController create() =>
      AdminNotificationsStreamController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$adminNotificationsStreamControllerHash() =>
    r'2c54e6fddfa6c3b71a0a6c884f8f6e9d85e20c9b';

abstract class _$AdminNotificationsStreamController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
