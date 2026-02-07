// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_notifications_remote_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminNotificationsRepository)
final adminNotificationsRepositoryProvider =
    AdminNotificationsRepositoryProvider._();

final class AdminNotificationsRepositoryProvider
    extends
        $FunctionalProvider<
          AdminNotificationsRepository,
          AdminNotificationsRepository,
          AdminNotificationsRepository
        >
    with $Provider<AdminNotificationsRepository> {
  AdminNotificationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminNotificationsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminNotificationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminNotificationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminNotificationsRepository create(Ref ref) {
    return adminNotificationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminNotificationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminNotificationsRepository>(value),
    );
  }
}

String _$adminNotificationsRepositoryHash() =>
    r'7e364baac1e43578ef34a9a1b6c3e0bdf9d1f221';
