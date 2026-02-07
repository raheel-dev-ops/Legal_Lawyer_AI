// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notifications)
final notificationsProvider = NotificationsFamily._();

final class NotificationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AppNotification>>,
          List<AppNotification>,
          FutureOr<List<AppNotification>>
        >
    with
        $FutureModifier<List<AppNotification>>,
        $FutureProvider<List<AppNotification>> {
  NotificationsProvider._({
    required NotificationsFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'notificationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notificationsHash();

  @override
  String toString() {
    return r'notificationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AppNotification>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AppNotification>> create(Ref ref) {
    final argument = this.argument as int?;
    return notifications(ref, before: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notificationsHash() => r'8e5bb6c37792902f01d2075462748e0465b68d22';

final class NotificationsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AppNotification>>, int?> {
  NotificationsFamily._()
    : super(
        retry: null,
        name: r'notificationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NotificationsProvider call({int? before}) =>
      NotificationsProvider._(argument: before, from: this);

  @override
  String toString() => r'notificationsProvider';
}

@ProviderFor(notificationUnreadCount)
final notificationUnreadCountProvider = NotificationUnreadCountProvider._();

final class NotificationUnreadCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  NotificationUnreadCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationUnreadCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationUnreadCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return notificationUnreadCount(ref);
  }
}

String _$notificationUnreadCountHash() =>
    r'dd20c2bd7a8aaa67536d4cf5fa13a35daf8e3e73';

@ProviderFor(notificationPreferences)
final notificationPreferencesProvider = NotificationPreferencesProvider._();

final class NotificationPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<NotificationPreferences>,
          NotificationPreferences,
          FutureOr<NotificationPreferences>
        >
    with
        $FutureModifier<NotificationPreferences>,
        $FutureProvider<NotificationPreferences> {
  NotificationPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPreferencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<NotificationPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<NotificationPreferences> create(Ref ref) {
    return notificationPreferences(ref);
  }
}

String _$notificationPreferencesHash() =>
    r'03aff42f80873656d4a76e331d372a4925b31f43';

@ProviderFor(NotificationController)
final notificationControllerProvider = NotificationControllerProvider._();

final class NotificationControllerProvider
    extends $NotifierProvider<NotificationController, void> {
  NotificationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationControllerHash();

  @$internal
  @override
  NotificationController create() => NotificationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$notificationControllerHash() =>
    r'dfca06c6394b1369e6db138505f8b8e01369fe16';

abstract class _$NotificationController extends $Notifier<void> {
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
