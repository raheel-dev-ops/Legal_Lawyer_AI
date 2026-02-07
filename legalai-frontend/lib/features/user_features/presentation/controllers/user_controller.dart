import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/user_remote_data_source.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/utils/ttl_cache.dart';

final userBookmarksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(userRepositoryProvider).getBookmarks();
});

const Duration _activityCacheTtl = Duration(seconds: 30);
final TtlCache _activityCache = TtlCache(defaultTtl: _activityCacheTtl);

final userActivityProvider =
    AsyncNotifierProvider.autoDispose<UserActivityController, List<Map<String, dynamic>>>(
  UserActivityController.new,
);

class UserActivityController extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch({bool forceRefresh = false}) async {
    const key = 'activityLog';
    if (!forceRefresh) {
      final cached = _activityCache.get<List<Map<String, dynamic>>>(key);
      if (cached != null) {
        return cached;
      }
    }
    final items = await ref.read(userRepositoryProvider).getActivityLog();
    final list = items.take(6).toList();
    _activityCache.set(key, list);
    return list;
  }

  Future<void> refresh() async {
    _activityCache.invalidate('activityLog');
    state = await AsyncValue.guard(() => _fetch(forceRefresh: true));
  }

  void prependLocal(String eventType, Map<String, dynamic> payload) {
    final current = state.value ?? const <Map<String, dynamic>>[];
    final updated = [
      {
        'type': eventType,
        'payload': payload,
        'createdAt': DateTime.now().toIso8601String(),
      },
      ...current,
    ];
    final list = updated.take(6).toList();
    _activityCache.set('activityLog', list);
    state = AsyncValue.data(list);
  }

  void clear() {
    _activityCache.invalidate('activityLog');
    state = const AsyncValue.data([]);
  }
}

class UserController extends Notifier<void> {
  @override
  void build() {
    return;
  }

  Future<void> uploadAvatar(PlatformFile file) async {
    await ref.read(userRepositoryProvider).uploadAvatar(file);
    ref.invalidate(authControllerProvider);
  }
}

final userControllerProvider = NotifierProvider.autoDispose<UserController, void>(() => UserController());
