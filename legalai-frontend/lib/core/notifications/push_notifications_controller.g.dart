// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_notifications_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PushNotificationsController)
final pushNotificationsControllerProvider =
    PushNotificationsControllerProvider._();

final class PushNotificationsControllerProvider
    extends $AsyncNotifierProvider<PushNotificationsController, void> {
  PushNotificationsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushNotificationsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushNotificationsControllerHash();

  @$internal
  @override
  PushNotificationsController create() => PushNotificationsController();
}

String _$pushNotificationsControllerHash() =>
    r'ef740a2ce6af11b7c1fb64ae6cbf484ce050ac87';

abstract class _$PushNotificationsController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
